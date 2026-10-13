# 核心服务一览

> `lib/services/` = 非 UI 可复用能力（不全是外部 API）。  
> 结构类 YAML；叶子字段右侧有 `#` 中文注释，同级对齐。源码为准。  
> 最后更新：2026-10-12  
> 入口：[学习地图](./README.md)

```yaml
# 本地 / 平台（精简）
ServiceName:
  file: 相对路径                   # 源码位置
  about: 一句话职责
  kind: local | platform | hybrid  # 能力类型

# 远端 / 有 HTTP 的服务（完整）；叶子字段右侧均有 # 注释且同级对齐
RemoteService:
  file: 相对路径                                                     # 源码位置
  about: 一句话职责
  kind: backend | hybrid                                             # 能力类型
  client: createBackendDio | createAuthenticatedBackendDio | 裸 Dio  # 客户端工厂
  transport: HTTPS 1.1 | HTTPS/2（AI） | 外网直连                    # 传输协议
  auth: none | Bearer | Token Gate                                   # 鉴权方式
  headers_extra: [...]                                               # 除公共 client-info 外的头
  request: application/json | multipart | raw | query-only           # 请求体形态
  response: application/json | NDJSON stream | octet-stream          # 响应形态
  endpoints:                                                         # method / path / body|query
    - ...
```

- `local`：纯本机  
- `platform`：系统/插件  
- `backend`：自家或第三方 HTTP  
- `hybrid`：本地 + 网络/平台  

**目录**

| 节 | 内容 |
|----|------|
| [§0](#0-自家后端公共约定) | Backend header / Token Gate / 两种 NDJSON / CDN 下载约定 |
| [§1](#1-网络基建) | Dio 工厂、端点路由、Token、HTTP/2 |
| [§2](#2-句级-ai流式) | translate / analyze / lookup / sense-groups / evaluate-review |
| [§3](#3-云端转录) | upload-url → R2 PUT → submit / job / transcript |
| [§4](#4-其它远端-api多在-features同样走-backenddio) | 聊天、播客 RSS、合集、百度 OAuth、权益、Paddle、升级检查 |
| [§5](#5-下载与资源安装) | ReliableHttpDownloader、词典 CDN |
| [§6](#6-播放与媒体)–[§13](#13-系统集成) | 本地/平台能力（播放、ASR/TTS、词典查询、统计等） |

---

## 0. 自家后端公共约定

所有走 `createBackendDio` / `createAuthenticatedBackendDio` 的请求共享：

```yaml
BackendCommon:
  base_url: RuntimeEndpointRouter.apiBaseUrl          # 按系统 Region 选全球/中国，不跨区回退
  client: Dio
  public_headers:                                     # BaseOptions，每个请求都带
    x-app-platform: ios|android|macos|windows|...     # 运行平台标识
    x-app-distribution: appstore|play|sideload|...    # 编译期渠道
    x-app-version: "x.y.z"                            # App 版本，可空则省略
  auth_header: "Authorization: Bearer <token>"        # 需登录端点由调用方传入
  token_gate:                                         # createAuthenticatedBackendDio
    before_send: TokenCoordinator 保证未过期            # 发请求前保证 token 有效
    on_401: 默认不重放；authRetryOnce 才刷新重试 1 次     # 显式 opt-in
  entitlement_header_in: "x-entitlement-active: 1|0"  # 响应头，权益拦截器读取
  do_not_use_for:                                     # 禁止注入自家 header
    - R2 预签名上传
    - CDN 模型/资源下载
    - 播客 RSS
    - App Store Lookup
```

### NDJSON 流式协议（两种）

```yaml
# A) 结构化对象（句 AI / 词典 / 意群 / 复述评估）
NdjsonOpsProtocol:
  about: 字段级增量；对齐后端 stream/_shared.ts
  transport: POST + ResponseType.stream；成功体为 text/ndjson（逐行 JSON）
  frames:
    ops:   '{"ops":[{"p":["path","to","leaf"],"v": <scalar>}, ...]}'  # 一批叶子，累积后 yield 一帧
    done:  '{"done":true}'                                            # 末帧 isFinal=true，可落缓存
    error: '{"__error": ...}'                                         # → NdjsonStreamException
  non_200_body: 小 JSON {"code","error",...}（流未开时）；401/402 等由业务映射登录/额度
  idle_timeout: aiHttpStreamIdleTimeout = 30s（帧间无字节则断）
  decode: ndjson_stream.dart + ndjson_object_stream.dart

# B) 纯文本聊天（ChatApiClient）
NdjsonTextProtocol:
  about: 累计全文，非 ops 路径
  frames:
    delta: '{"delta":"..."}'               # 追加文本到 buffer
    meta:  '{"meta":{"messageId":"..."}}'  # 可选 messageId 等元信息
    done:  '{"done":true}'                 # 流正常结束
    error: '{"__error":...}'               # 流内错误
  decode: lib/features/chatbot/services/ndjson_text_stream.dart
```

### CDN 模型 / 资源下载（非自家 API）

```yaml
ModelCdnCommon:
  base_url: RuntimeEndpointRouter.modelCdnBaseUrl          # 与 API 同 Region
  client: 裸 Dio + DioReliableHttpDownloader               # 禁止 BackendDio（不带 x-app-*）
  transport: HTTPS GET + ReliableHttpDownloader            # .part / Range / 校验
  request: 无 JSON body；URI 由 archivePath 拼出             # 请求形态
  response: zip | tar.gz 归档 → 本地解压                     # 响应形态
  install: ResourceArchiveInstaller / AsrArchiveInstaller  # 写本地 manifest
  url_pattern: "{cdn}/model/{archivePath}"                 # ASR/TTS 带 /model/ 前缀
  # 词典/发音：modelCdnUri(archivePath) 路径已含 dictionary/...
```

---

## 1. 网络基建

```yaml
BackendDio:
  file: lib/services/backend_dio.dart
  about: 自家后端统一 Dio 工厂（header / 日志 / 权益头 / 可选 Token Gate）
  kind: backend
  factories:
    createBackendDio: 公共 header + ApiLog + EntitlementSignal + 可选 RuntimeApiEndpointInterceptor
    createAuthenticatedBackendDio: 上者 + Token Gate 拦截器
  auth_retry: authRetryOnceOptions(...)        # 显式 opt-in 401 重放一次

RuntimeEndpointRouter:
  file: lib/services/runtime_endpoint_router.dart
  about: 按 UserRegion 固定选全球或中国 API/CDN，未配置则报错不跨区
  kind: local
  outputs:
    apiBaseUrl: String                         # 当前区域 API 根地址
    modelCdnBaseUrl: String                    # 当前区域模型/资源 CDN 根地址
    apiUri(path) / modelCdnUri(path): Uri      # 相对 path → 绝对 Uri

ClientInfo:
  file: lib/services/client_info.dart
  about: 组装 x-app-platform / x-app-distribution / x-app-version
  kind: local

SupabaseTokenCoordinator:
  file: lib/services/supabase_token_coordinator.dart
  about: access token 有效性门闸（非 HTTP 客户端；给 Dio 拦截器用）
  kind: hybrid
  protocol: Supabase GoTrue SDK（refreshSession）                    # 非 HTTP；SDK 刷新
  failures: notSignedIn | identityChanged | temporarilyUnavailable  # Token Gate 失败原因

AiHttpClientAdapter / AiHttp2RetryInterceptor:
  file: lib/services/ai_http_client_adapter.dart 等
  about: AI Dio 在 HTTPS 上启用 HTTP/2；GOAWAY/空闲连接失效可安全重试
  kind: backend
  transport: HTTP/2（默认开；--dart-define=AI_HTTP2_ENABLED=false 回退 1.1）
  note: 仅 https baseUrl；localhost http 保持 1.1

ApiLogInterceptor:
  file: lib/services/api_log_interceptor.dart
  about: 打印 method/uri/status/耗时（流式成功体不预读）
  kind: local

EntitlementSignalInterceptor:
  file: lib/services/entitlement_signal_interceptor.dart
  about: 读响应头 x-entitlement-active，通知订阅层对账
  kind: local
  response_header: "x-entitlement-active: 1|0"  # 服务端权益快照
```

---

## 2. 句级 AI（流式）

```yaml
SentenceAiApiClient:
  file: lib/services/sentence_ai_api_client.dart
  about: 翻译 / 解析 / 查词 / 意群 / 复述评估
  kind: backend
  client: createAuthenticatedBackendDio + configureAiHttpClientAdapter
  transport: HTTPS HTTP/2（生产）+ Dio stream
  auth: Bearer accessToken（每请求 Options.headers）
  request: 多数 application/json；evaluate-review 为 multipart/form-data
  response: NDJSON ops 协议（见 §0）；非 200 为小 JSON
  timeouts: connect 15s / receive 30s（到首字节）；帧间 idle 30s
  endpoints:
    - method: POST
      path: /api/v1/stream/translate
      body:
        text: string                       # 目标句
        previousText: string?              # 上文，可选
        nextText: string?                  # 下文，可选
        targetLanguage: string?            # BCP 47，如 zh-CN
      response_accumulates: SentenceTranslation（字段 translation）

    - method: POST
      path: /api/v1/stream/analyze
      body:
        text: string                       # 目标句原文
        targetLanguage: string?            # BCP 47，如 zh-CN
      response_accumulates: SentenceAnalysis（grammar/vocabulary/listening…）

    - method: POST
      path: /api/v1/stream/lookup-word
      body:
        query: string                      # 单词（规范化后无空白）
        targetLanguage: string?            # BCP 47，如 zh-CN
      response_accumulates: DictionaryEntry
      errors: 400 phrase_too_long | 401 DictionaryAuthRequired | 402 额度

    - method: POST
      path: /api/v1/stream/lookup-phrase
      body:
        query: string                      # 多词/短语（含空白）
        targetLanguage: string?            # BCP 47，如 zh-CN
      response_accumulates: MultiWordDictionaryEntry

    - method: POST
      path: /api/v1/stream/sense-groups
      body:
        text: string                       # 原句；无意群目标语言字段
      response_accumulates: SenseGroupResult（medium → fine）

    - method: POST
      path: /api/v1/stream/evaluate-review
      content_type: multipart/form-data
      body:
        file: MultipartFile                # 本地录音，filename retell-review.m4a
        originalText: string               # 复述对照原文
        language: "en"                     # 固定写死英语源
        targetLanguage: string             # 评估说明语言（BCP 47）
      metering: 后端 retell_review 口径
      response_accumulates: RetellReviewEvaluation
```

---

## 3. 云端转录

```yaml
TranscriptionApiClient:
  file: lib/services/transcription_api_client.dart
  about: 用户音频上传 R2 + 提交/轮询转录
  kind: backend
  client: createAuthenticatedBackendDio（自家 API）；R2 上传用裸 Dio
  transport: HTTPS HTTP/1.1（未挂 AI h2 adapter）
  auth: Bearer accessToken（自家 API）；R2 靠预签名 URL
  request: application/json（API）；PUT raw file（R2）
  response: application/json
  endpoints:
    - method: POST
      path: /api/v2/user-audio/upload-url
      body:
        sha256: string                     # 音频内容指纹
        mimeType: string                   # MIME 类型
        fileSize: int                      # 文件字节数
      response:
        audioExists: bool                  # true 则可跳过上传
        uploadUrl: string?                 # 预签名 PUT URL
        objectName: string                 # R2 对象路径
        publicUrl: string                  # R2 公开访问 URL

    - method: PUT
      path: "<presigned R2 URL>"           # 完整 URL，非自家 base
      headers:
        Content-Type: mimeType             # 上传 MIME
        Content-Length: fileLength         # 上传字节长度
      body: 文件字节流（file.openRead()）
      note: 裸 Dio + ApiLogInterceptor(tag=R2-UPLOAD)；不带 x-app-*

    - method: POST
      path: /api/v2/user-audio/submit-transcription
      body:
        sha256: string                     # 音频内容指纹
        fileName: string?                  # 原始文件名，可选
        objectName: string?                # R2 对象路径，可选
        publicUrl: string?                 # R2 公开 URL，可选
        mimeType: string?                  # MIME，可选
        fileSize: int?                     # 字节数，可选
        language: string                   # 转录语言
        mergeSentences: bool               # 是否合并短句，默认 true
      response:
        cached: bool                       # true 时直接带 transcript
        jobId: string?                     # 异步任务 ID
        transcript: object?                # 缓存命中时的转录结果

    - method: GET
      path: /api/v2/user-audio/job-status/{jobId}
      response:
        status: queued|running|succeeded|failed  # 任务状态
        error: string?                           # 失败信息，仅 failed

    - method: GET
      path: /api/v2/user-audio/transcript
      query:
        sha256: string                     # 音频内容指纹
        language: string                   # 转录语言
        mergeSentences: bool               # 是否合并短句，默认 true
      response: TranscriptResult（sentences / wordTimestamps / text）
```

---

## 4. 其它远端 API（多在 features/，同样走 BackendDio）

学习时一并对照；实现不在 `lib/services/` 根下。

```yaml
ChatApiClient:
  file: lib/features/chatbot/services/chat_api_client.dart
  about: 通用聊天流式（句聊等）
  kind: backend
  client: createAuthenticatedBackendDio + AI HTTP/2
  transport: HTTPS HTTP/2 + stream
  auth: Bearer accessToken
  request: application/json
  response: NdjsonTextProtocol（§0 B，delta 累积全文）
  endpoints:
    - method: POST
      path: 调用方传入，如 /api/v1/stream/chat/sentence
      body:
        messages: [{role, content}, ...]   # ChatMessage.toWire(+ followUpInstruction)
        context: map?                      # 句聊等业务上下文
        targetLanguage: string?            # BCP 47，如 zh-CN

PodcastRepository.feedFetch:
  file: lib/features/podcast/podcast_repository.dart
  about: 拉取第三方播客 RSS（外网，非自家 API）
  kind: hybrid
  client: 裸 Dio（不带 x-app-*）
  transport: HTTPS GET
  auth: none
  request: query-only（完整 feedUrl）
  response: text/xml|application/rss+xml 等 → ResponseType.plain 字符串
  parse: PodcastFeedParser（仅 RSS 2.0 + enclosure；Atom 不支持）
  anti_bot: isAntiBotChallenge → PodcastFeedBlockedException
  endpoints:
    - method: GET
      path: "<user/catalog podcastFeedUrl>"
      options: { responseType: plain }

RemoteConfigService:
  file: lib/features/remote_config/remote_config_service.dart
  about: 拉取客户端远程配置
  kind: backend
  client: createBackendDio（通常无需登录）
  request: query-only
  response: application/json
  endpoints:
    - method: GET
      path: /api/v1/client/config
      query:
        platform: string                     # clientPlatformName()

PodcastCatalogService:
  file: lib/features/podcast/data/podcast_catalog_service.dart
  about: 播客目录（catalog 内 podcastCatalogs）
  kind: backend
  client: createBackendDio
  endpoints:
    - method: GET
      path: /api/v1/catalog
      response: JSON（再取 podcastCatalogs）

CommunityCollectionApi:
  file: lib/features/community_collections/data/community_collection_api.dart
  about: 社区合集列表 / 详情 / 文件+字幕
  kind: backend
  client: createBackendDio
  request: query-only
  response: application/json
  endpoints:
    - method: GET
      path: /api/v2/collections
      query: cursor?
    - method: GET
      path: /api/v2/collections/{collectionId}
      query: cursor?
    - method: GET
      path: /api/v2/collections/{id}/files/{fileId}
      errors: 404 not found | 422 字幕不可用

BackendBaiduOAuthApi:
  file: lib/features/baidu_netdisk/data/baidu_oauth_api.dart
  about: 百度网盘 OAuth 会话经自家后端中转
  kind: backend
  client: createBackendDio
  request: application/json
  response: application/json
  endpoints:
    - method: POST
      path: /api/v1/netdisk/baidu/oauth/session
      body: { platform, forceLogin? }
    - method: POST
      path: /api/v1/netdisk/baidu/oauth/session/status
      body: { sessionId, pollToken }
    - method: POST
      path: /api/v1/netdisk/baidu/oauth/session/acknowledge
      body: { sessionId, pollToken }
    - method: POST
      path: /api/v1/netdisk/baidu/oauth/refresh
      body: { refreshToken }

BackendEntitlementRepository:
  file: lib/features/subscription/services/entitlement_repository.dart
  about: 拉取用户权益
  kind: backend
  client: createAuthenticatedBackendDio
  auth: Bearer + authRetryOnceOptions
  endpoints:
    - method: GET
      path: /api/entitlements
      query: force=1?                  # 强制回源
      response: Entitlement JSON；非 2xx → null（走缓存，不误降级）

PaddleBillingRepository / PaddlePlansService:
  file: lib/features/subscription/services/paddle_*.dart
  about: 套餐列表、托管结账、客户门户
  kind: backend
  client: authenticated + 部分公开 Dio
  endpoints:
    - method: GET
      path: /api/paddle/plans
    - method: POST
      path: /api/paddle/hosted-checkout
      body: { planId, locale }
      headers: Authorization, Idempotency-Key
      response: { attemptId, checkoutUrl }
      errors: 409 already_entitled
    - method: POST
      path: /api/paddle/portal
      response: { portalUrl }

AppUpdateChecker:
  file: lib/services/app_update_checker.dart
  about: 检查新版本
  kind: hybrid
  client: 裸 Dio（混打外网与自家，故不用全局 BackendDio header）
  endpoints:
    - method: GET
      path: https://itunes.apple.com/lookup
      query: { bundleId, country? }
      response: text/javascript → 自行 jsonDecode
      headers: 不带 x-app-*
    - method: GET
      path: {apiBase}/version.json     # 非 iOS
      headers: clientInfoHeaders()     # 仅此请求带自家标识
      response: AppUpdateInfo JSON
```

---

## 5. 下载与资源安装

```yaml
ReliableHttpDownloader:
  file: lib/services/reliable_http_downloader.dart
  about: 通用可靠 GET 落盘（.part / Range 续传 / 原子 rename / 校验 / 重试）
  kind: hybrid
  client: DioReliableHttpDownloader(dio) 或调用方注入；不自动带 x-app-*
  transport: HTTP(S) GET；可选 Range 续传
  request: 无 body；调用方拼 URI + headers
  response: octet-stream → 本地文件
  method: download(...)
  inputs:
    uri: Uri                           # 下载目标 Uri
    savePath: string                   # 最终落盘路径
    headers: Map?                      # 可选请求头
    expectedSize: int?                 # 期望字节数，可选
    allowResume: bool                  # 是否允许 Range 续传
  failures: cancelled|timeout|network|httpStatus|redirect|storage|integrity|conflict|unknown  # 结构化失败分类

BackgroundFileDownloadService:
  file: lib/services/background_file_download_service.dart
  about: 后台下载进度通知（限频，供播客单集等）
  kind: hybrid
  note: 业务下载仍走 ReliableHttpDownloader / 任务协调器；本类管通知 UI

DownloadTaskCoordinator / DownloadTaskStore:
  file: lib/services/download/
  about: 下载任务编排与持久化
  kind: hybrid

ResourceArchiveInstaller:
  file: lib/services/resource_archive_installer.dart
  about: CDN 归档下载 + 解压 + 写 ResourceInstallManifest 通式
  kind: hybrid
  transport: 见 §0 ModelCdnCommon
  flow: GET uri → save archive → extract → write manifest
  inputs:
    resourceId: string                 # 资源安装 ID
    uri: Uri                           # CDN 归档 Uri
    root: Directory                    # 安装根目录
    archiveFileName: string?           # 本地归档临时文件名
    expectedSha256: string?            # 完整性校验，可选

ResourceInstallManifest:
  file: lib/services/resource_install_manifest.dart
  about: 可安装资源本地清单 schema
  kind: local

DictionaryDownloadManager:
  file: lib/services/dictionary_download_manager.dart
  about: 词典 ZIP 从 CDN 下载并安装
  kind: hybrid
  client: 裸 Dio + ReliableHttpDownloader + ResourceArchiveInstaller
  transport: HTTPS GET
  uri: modelCdnUri(spec.archivePath)   # 无额外 /model/ 前缀
  catalog: lib/services/dictionary/dictionary_catalog.dart
  examples:
    zh-CN: dictionary/en_zh-CN/dict_en_zh-CN-v1.sqlite.zip  # 简体词典归档相对路径
    zh-TW: dictionary/en_zh-TW/dict_en_zh-TW-v1.sqlite.zip  # 繁体词典归档相对路径
```

---

## 6. 播放与媒体

```yaml
AudioPlaybackService:
  file: lib/services/audio_playback_service.dart
  about: 通用单文件音频播放
  kind: platform

MediaPlayerBackend / MediaKitPlayerBackend:
  file: lib/services/media_player_backend.dart 等
  about: 播放后端抽象与 media_kit 实现
  kind: platform

MediaKitDurationProbe:
  file: lib/services/media_kit_duration_probe.dart
  about: 音视频时长探测（导入入库）
  kind: platform

MediaSessionRouter:
  file: lib/services/media_session_router.dart
  about: 全 App 唯一 audio_service / 系统媒体会话路由
  kind: platform

EchoLoopMediaHandler / BackgroundAudioHandler:
  file: lib/services/echo_loop_media_handler.dart 等
  about: 锁屏/通知栏媒体控件与后台播放
  kind: platform

AudioPreviewController:
  file: lib/services/audio_preview_controller.dart
  about: 短音频试听状态机
  kind: platform

NativeAudioDecoder:
  file: lib/services/native_audio_decoder.dart
  about: 原生音频解码通道（PCM 等）
  kind: platform

MediaFullscreenService / WindowFullscreenService:
  file: lib/services/media_fullscreen_service.dart 等
  about: 视频页 / 桌面窗口全屏
  kind: platform

MediaSubtitleStyle:
  file: lib/services/media_subtitle_style.dart
  about: 视频画面字幕样式
  kind: local

SilenceSkipDetector:
  file: lib/services/silence_skip_detector.dart
  about: 字幕间隙静音段检测
  kind: local
```

---

## 7. 录音、语音、ASR

```yaml
RecordingService:
  file: lib/services/recording_service.dart
  about: 通用录音
  kind: platform

SpeechPracticePlatform:
  file: lib/services/speech_practice_platform.dart
  about: 录音识别平台通道
  kind: platform

SpeechPracticeMatcher:
  file: lib/services/speech_practice_matcher.dart
  about: 识别文本与目标句比对
  kind: local

SpeechPermissionService / SpeechCompletionDetector:
  file: lib/services/speech_permission_service.dart 等
  about: 录音权限；跟读完成判定
  kind: hybrid

RetellReviewAudioPreparer:
  file: lib/services/retell_review_audio_preparer.dart
  about: 复述评估上传前临时转码
  kind: hybrid
  note: 产出文件再交给 SentenceAiApiClient.evaluateReviewStream（multipart）

AsrModelManager / AsrArchiveInstaller:
  file: lib/services/asr/asr_model_manager.dart 等
  about: 离线 ASR 模型下载安装
  kind: hybrid
  client: 裸 Dio + ReliableHttpDownloader（AsrArchiveInstaller）
  transport: HTTPS GET → zip
  uri: modelCdnUri("/model/{archivePath}")
  catalog: asr_model_catalog.dart
  examples:
    - asr/silero-vad-v1.zip
    - asr/whisper-tiny-en-int8-v1.zip
    - asr/whisper-base-en-int8-v1.zip
    - asr/whisper-small-en-int8-v1.zip
  status: notDownloaded|downloading|downloaded|failed  # 模型下载状态机

OfflineAsrEngine / SherpaOnnxEngine / AudioFileReader:
  file: lib/services/asr/
  about: 本地推理与音频读入（无 HTTP）
  kind: local
```

---

## 8. TTS 与发音库

```yaml
KokoroModelManager / PiperModelManager:
  file: lib/services/tts/kokoro_model_manager.dart / piper_model_manager.dart
  about: TTS 模型归档下载安装
  kind: hybrid
  client: 裸 Dio + ResourceArchiveInstaller
  transport: HTTPS GET → tar.gz
  uri: modelCdnUri("/model/{voice|spec.archivePath}")
  archiveFileName: "_download_{id}.tar.gz"  # 本地下载临时名模板

KokoroSynthesizer / PiperSynthesizer / *TtsEngine:
  file: lib/services/tts/
  about: 本地合成 PCM/文件（无 HTTP）
  kind: local

PronunciationLibraryManager:
  file: lib/services/pronunciation/pronunciation_library_manager.dart
  about: 离线发音库 ZIP 下载安装
  kind: hybrid
  transport: HTTPS GET
  uri: modelCdnUri(pronunciationSpec.archivePath)
  catalog: pronunciation_catalog.dart → dictionary/pronunciation-v2.zip

PronunciationRepository / LocalAudioClipPlayer / SourceSentencePlayer:
  file: lib/services/pronunciation/
  about: 本地查询与片段/原句区间播放
  kind: platform
```

---

## 9. 词典（查询侧）

```yaml
DictionaryService:
  file: lib/services/dictionary_service.dart
  about: 本地词典查询入口
  kind: local

DictionarySource 族:
  file: lib/services/dictionary/
  about: 本地 / AI / 网页词典源
  kind: hybrid
  ai_source: 委托 SentenceAiApiClient lookup-word / lookup-phrase（NDJSON）
  web_source: 加载网页 URL（非自家 API JSON）

DictionaryCatalog:
  file: lib/services/dictionary/dictionary_catalog.dart
  about: 词典包目录元数据
  kind: local
```

---

## 10. 字幕与导出

```yaml
SubtitleParser / LrcParser:
  file: lib/services/subtitle_parser.dart / lrc_parser.dart
  about: SRT/VTT / LRC 本地解析
  kind: local

SubtitleAutoAlignService:
  file: lib/services/subtitle_auto_align_service.dart
  about: 用本地解码 + 静音检测微调句边界（非 HTTP）
  kind: local
  inputs: 音频路径 + 句子时间轴；失败回退原始字幕

AudioExportService:
  file: lib/services/audio_export_service.dart
  about: 音频条目导出
  kind: local

StudyPdfExportService / Builder / Loader:
  file: lib/services/pdf_export/
  about: 学习材料 PDF 导出
  kind: local
```

---

## 11. 存储、备份、清理

```yaml
StorageService:
  file: lib/services/storage_service.dart
  about: SharedPreferences 薄封装
  kind: local

StorageMigrationService / BackupService:
  file: lib/services/storage_migration_service.dart / backup/
  about: 目录迁移；备份恢复
  kind: local

OrphanFileCleanupService / TempCleanupService:
  file: lib/services/orphan_file_cleanup_service.dart 等
  about: 孤儿媒体 / 临时目录清理
  kind: local

BundledExampleInstaller / DemoDataSeeder:
  file: lib/services/bundled_example_installer.dart 等
  about: 内置示例；演示数据
  kind: local
```

---

## 12. 学习统计与提醒

```yaml
StudyTimeService / StudySessionTimer / StudyActivityGate:
  file: lib/services/study_*.dart
  about: 时长入库、阶段计时、前后台资格
  kind: hybrid

ReviewReminderService / ReviewReminderTimeCalculator:
  file: lib/services/review_reminder_*.dart
  about: 本地通知调度与时刻计算
  kind: platform

LearnedVocabularyTracker:
  file: lib/services/learned_vocabulary_tracker.dart
  about: 已学词汇追踪
  kind: local
```

---

## 13. 系统集成

```yaml
AppLogger / StartupTrace:
  file: lib/services/app_logger.dart 等
  about: 日志；启动耗时
  kind: local

AppDeepLinkRouter:
  file: lib/services/app_deep_link_router.dart
  about: Deep Link 解析分发
  kind: platform

AppUpdateLauncher / AndroidUpdateBridge:
  file: lib/services/app_update_launcher.dart 等
  about: 打开商店/安装包；Android 原生桥
  kind: platform

NotificationPermission* / NetworkPermissionTrigger:
  file: lib/services/notification_*.dart / network_permission_trigger.dart
  about: 通知权限；iOS 网络权限触发
  kind: platform

AppWindowService / AppNotice / AppNetworkImageCache:
  file: lib/services/app_window_service.dart 等
  about: 桌面窗口；Toast；图片磁盘缓存
  kind: hybrid

UserIdService / DeviceDiagnosticsService / RefreshCoordinator:
  file: lib/services/user_id_service.dart 等
  about: 本地用户 ID；诊断；刷新去重
  kind: hybrid

EmbeddingSimilarity / TextEmbeddingPlatform:
  file: lib/services/embedding_similarity.dart 等
  about: 向量相似度；Apple NLEmbedding 通道
  kind: platform
```

---

## 怎么读

```text
UI / Provider
    ↓
API Client（§2–4）── Dio ── BackendCommon（§0）── 自家 API / CDN / R2
    ↓
本地服务（解析、播放、存储…）
```

优先精读：**§0 公共约定 → SentenceAiApiClient → TranscriptionApiClient → MediaSession / Recording → ReliableHttpDownloader**。

---

## 维护

- 新增**远端**能力：补全 `client/transport/auth/request/response/endpoints`（含 body 字段）。  
- 纯本地服务：`file/about/kind` 即可。  
- Feature 内 API 客户端可记在 §4，避免只扫 `lib/services/` 根目录漏掉。


