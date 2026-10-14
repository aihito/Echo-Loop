# 核心服务一览

> `lib/services/` = 非 UI 可复用能力（不全是外部 API）。  
> 结构类 YAML；叶子字段右侧有 `#` 中文注释，同级对齐。源码为准。  
> 生词（NDJSON / Dio / CDN / Bearer…）先查：[术语小词典](./glossary.md)  
> 对接/重写后端（含参数）：[backend-api.md](./backend-api.md)  
> 最后更新：2026-10-13  
> 入口：[学习地图](./README.md)

```yaml
# 每条服务固定形状（本地可省略 HTTP 字段）
ServiceName:
  file: 相对路径                   # 源码位置
  about: 一句话职责                # 是什么
  does: 谁用、何时用、产出/副作用  # 具体做什么（必有）
  kind: local | platform | backend | hybrid
  # 远端另有：client / transport / auth / request / response / endpoints
  # endpoints[] 每条必有 purpose（该 API 干什么）+ 字段树
```

- `local`：纯本机  
- `platform`：系统/插件  
- `backend`：自家或第三方 HTTP  
- `hybrid`：本地 + 网络/平台  

**目录**

| 节 | 内容 |
|----|------|
| [§0](#0-公共约定文档概念不是-dart-类名) | BackendCommon / 两种 NDJSON / ModelCdnCommon（约定说明） |
| [§1](#1-网络基建) | Dio 工厂、端点路由、Token、HTTP/2 |
| [§2](#2-句级-ai流式) | translate / analyze / lookup / sense-groups / evaluate-review |
| [§3](#3-云端转录) | upload-url → R2 PUT → submit / job / transcript |
| [§4](#4-其它远端-api多在-features同样走-backenddio) | 聊天、播客 RSS、合集、百度 OAuth、权益、Paddle、升级检查 |
| [§5](#5-下载与资源安装) | ReliableHttpDownloader、词典 CDN |
| [§6](#6-播放与媒体)–[§13](#13-系统集成) | 本地/平台能力（播放、ASR/TTS、词典查询、统计等） |

---

## 0. 公共约定（文档概念，不是 Dart 类名）

下面四个名字是**手册里的约定标签**，方便后文写「走 BackendCommon / 用 NdjsonOps…」。  
代码里没有叫 `BackendCommon` / `NdjsonOpsProtocol` 的 class；对应实现散落在 Dio 工厂、ndjson_*、CDN 安装器里。

---

### BackendCommon — 打「自家后端 API」时大家共用的一套规矩

```yaml
BackendCommon:
  what: 文档约定名（≠ 某个 .dart 类）
  about: 凡 createBackendDio / createAuthenticatedBackendDio 创建的请求，都遵守这套
  does: >
    统一「怎么连自家服务器」：基址按地区选、每个请求带平台/渠道/版本头、
    可选登录 Token、响应里顺带读权益信号。这样 AI/转录/权益/结账等客户端不用各写一套。
  used_by:
    - SentenceAiApiClient、TranscriptionApiClient、ChatApiClient
    - Entitlement / Paddle、RemoteConfig、社区合集、百度 OAuth 等
  not_this: 外网直连（R2 预签名、CDN 模型包、播客 RSS、App Store Lookup）禁止套这套 header

  base_url: RuntimeEndpointRouter.apiBaseUrl          # 按系统 Region 选全球/中国，不跨区回退
  client: Dio                                         # 经 BackendDio 工厂创建
  public_headers:                                     # BaseOptions，每个请求都带
    x-app-platform: ios|android|macos|windows|...     # 运行平台标识
    x-app-distribution: appstore|play|sideload|...    # 编译期渠道
    x-app-version: "x.y.z"                            # App 版本，可空则省略
  auth_header: "Authorization: Bearer <token>"        # 需登录端点由调用方传入
  token_gate:                                         # 仅 createAuthenticatedBackendDio
    before_send: TokenCoordinator 保证未过期            # 发请求前保证 token 有效
    on_401: 默认不重放；authRetryOnce 才刷新重试 1 次     # 显式 opt-in
  entitlement_header_in: "x-entitlement-active: 1|0"  # 响应头，权益拦截器读取
  do_not_use_for:                                     # 禁止注入自家 header
    - R2 预签名上传
    - CDN 模型/资源下载
    - 播客 RSS
    - App Store Lookup
```

一句话：**BackendCommon = 自家 HTTPS API 的 Dio 公共配置约定。**

---

### NdjsonOpsProtocol — AI「结构化结果」流式协议（字段一点点长出来）

```yaml
NdjsonOpsProtocol:
  what: 文档约定名；实现 = ndjson_stream + ndjson_object_stream
  about: 后端按行推 NDJSON；每行是「往对象某个路径写一个叶子」，客户端累积成完整业务对象
  does: >
    翻译/解析/AI 词典/意群/复述评估要边生成边刷新 UI：不能等整包 JSON。
    服务端每次 flush 若干 ops（路径 p + 值 v）；客户端拼进 Map 再 fromJson，
    收到 done 才算最终可缓存帧。对齐后端 stream/_shared.ts。
  used_by: SentenceAiApiClient（translate / analyze / lookup-* / sense-groups / evaluate-review）
  vs_text: 不是聊天那种「往字符串后面加字」，而是「往 JSON 树某个字段设值」

  transport: POST + ResponseType.stream；成功体为 text/ndjson（一行一个 JSON）
  frames:
    ops:   '{"ops":[{"p":["path","to","leaf"],"v": <scalar>}, ...]}'  # 一批叶子，累积后 yield 一帧
    done:  '{"done":true}'                                            # 末帧 isFinal=true，可落缓存
    error: '{"__error": ...}'                                         # → NdjsonStreamException
  non_200_body: 小 JSON {"code","error",...}（流未开时）；401/402 → 登录/额度
  idle_timeout: aiHttpStreamIdleTimeout = 30s（帧间无字节则断）
  decode: lib/services/ndjson_stream.dart + ndjson_object_stream.dart
```

一句话：**NdjsonOpsProtocol = 流式「拼 JSON 对象」的协议（句 AI / AI 词典用）。**

示例（翻译字段渐显）：

```text
{"ops":[{"p":["translation"],"v":"你"}]}
{"ops":[{"p":["translation"],"v":"你好"}]}
{"done":true}
```

---

### NdjsonTextProtocol — AI「纯文本聊天」流式协议（字符串一点点加长）

```yaml
NdjsonTextProtocol:
  what: 文档约定名；实现 = chatbot/ndjson_text_stream.dart
  about: 同样是 NDJSON 逐行推，但语义是往一段文字后面追加 delta，不是改对象字段树
  does: >
    句聊/助手要打字机效果：服务端推 {"delta":"…"}，客户端 StringBuffer 累加，
    done 结束；可选 meta.messageId。与 Ops 协议共享「一行一 JSON / done / __error」，
    但帧形状不同，解码器用 accumulateNdjsonText 而不是 accumulateNdjsonObject。
  used_by: ChatApiClient（如 POST /api/v1/stream/chat/sentence）
  vs_ops: 不要用 ops 去解析聊天；也不要用 delta 去解析词典/解析结果

  transport: 同左，POST + stream + NDJSON
  frames:
    delta: '{"delta":"..."}'               # 追加文本到 buffer
    meta:  '{"meta":{"messageId":"..."}}'  # 可选 messageId 等元信息
    done:  '{"done":true}'                 # 流正常结束
    error: '{"__error":...}'               # 流内错误
  decode: lib/features/chatbot/services/ndjson_text_stream.dart
```

一句话：**NdjsonTextProtocol = 流式「拼字符串」的协议（聊天用）。**

示例：

```text
{"delta":"Hello"}
{"delta":" world"}
{"done":true}
```

---

### ModelCdnCommon — 下「模型/词典等大文件」时共用的 CDN 规矩（不是自家 API）

```yaml
ModelCdnCommon:
  what: 文档约定名（≠ 某个 class）；实现散落在 RuntimeEndpointRouter + ReliableHttpDownloader + *ArchiveInstaller
  about: ASR/TTS/词典/发音库等离线资源从 CDN 拉归档包，不走 BackendCommon
  does: >
    这些是静态 zip/tar.gz，不是 JSON API：用裸 Dio GET（不带 x-app-*），
    经可靠下载器落盘、校验、解压、写安装清单。基址与 API 同 Region，
    但域名是 modelCdnBaseUrl，路径由各 catalog 的 archivePath 决定。
  used_by:
    - AsrModelManager（Whisper/VAD）
    - Kokoro/Piper ModelManager（TTS）
    - DictionaryDownloadManager（ECDICT sqlite.zip）
    - PronunciationLibraryManager（真人发音包）
  not_this: 不要 createBackendDio；不要当 REST 去 POST JSON

  base_url: RuntimeEndpointRouter.modelCdnBaseUrl          # 与 API 同 Region
  client: 裸 Dio + DioReliableHttpDownloader               # 禁止 BackendDio（不带 x-app-*）
  transport: HTTPS GET + ReliableHttpDownloader            # .part / Range / 校验
  request: 无 JSON body；URI 由 archivePath 拼出             # 请求形态
  response: zip | tar.gz 归档 → 本地解压                     # 响应形态
  install: ResourceArchiveInstaller / AsrArchiveInstaller  # 写本地 manifest
  url_pattern: "{cdn}/model/{archivePath}"                 # ASR/TTS 带 /model/ 前缀
  # 词典/发音：modelCdnUri(archivePath) 路径已含 dictionary/...
```

一句话：**ModelCdnCommon = 离线资源 CDN 下载/安装约定（模型、词典包）。**

---

### 四者怎么区分（速记）

| 名字 | 本质 | 典型用途 |
|------|------|----------|
| BackendCommon | 自家 API 的 Dio 公共头/鉴权约定 | 翻译、转录、权益、结账… |
| NdjsonOpsProtocol | 流式拼 **JSON 对象** | 句 AI、AI 词典 |
| NdjsonTextProtocol | 流式拼 **纯文本** | 句聊 |
| ModelCdnCommon | CDN **大文件 GET** 约定 | Whisper/TTS/ECDICT/发音库 |

---

## 1. 网络基建

```yaml
BackendDio:
  file: lib/services/backend_dio.dart
  about: 自家后端统一 Dio 工厂
  does: 新建打自家 API 的 Dio；注入平台/渠道 header、日志、权益头；可选 Token Gate。禁止用于 R2/CDN/RSS。
  kind: backend
  factories:
    createBackendDio: 公共 header + ApiLog + EntitlementSignal + 可选 RuntimeApiEndpointInterceptor
    createAuthenticatedBackendDio: 上者 + Token Gate 拦截器
  auth_retry: authRetryOnceOptions(...)        # 显式 opt-in 401 重放一次

RuntimeEndpointRouter:
  file: lib/services/runtime_endpoint_router.dart
  about: 按 UserRegion 固定选全球或中国 API/CDN
  does: 启动判定中国用户后锁定区域；对外提供 apiBaseUrl / modelCdnBaseUrl；未配置该区端点则报错，不跨区回退。
  kind: local
  outputs:
    apiBaseUrl: String                         # 当前区域 API 根地址
    modelCdnBaseUrl: String                    # 当前区域模型/资源 CDN 根地址
    apiUri(path) / modelCdnUri(path): Uri      # 相对 path → 绝对 Uri

ClientInfo:
  file: lib/services/client_info.dart
  about: 组装平台/渠道/版本公共 header
  does: 供 BackendDio 写入每个自家请求；后端据此做 AI 免费额度等策略（见 subscription-setup）。
  kind: local

SupabaseTokenCoordinator:
  file: lib/services/supabase_token_coordinator.dart
  about: access token 有效性门闸
  does: 发请求前确保会话未过期（必要时 refresh）；身份切换/登出时失败可区分，供鉴权 Dio 拦截器使用。
  kind: hybrid
  protocol: Supabase GoTrue SDK（refreshSession）                    # 非 HTTP；SDK 刷新
  failures: notSignedIn | identityChanged | temporarilyUnavailable  # Token Gate 失败原因

AiHttpClientAdapter / AiHttp2RetryInterceptor:
  file: lib/services/ai_http_client_adapter.dart 等
  about: AI 请求 HTTP/2 适配与连接层重试
  does: 给 SentenceAi / Chat 等流式 Dio 挂 h2 adapter；GOAWAY/空闲断连时安全重试，避免整句 AI 白失败。
  kind: backend
  transport: HTTP/2（默认开；--dart-define=AI_HTTP2_ENABLED=false 回退 1.1）
  note: 仅 https baseUrl；localhost http 保持 1.1

ApiLogInterceptor:
  file: lib/services/api_log_interceptor.dart
  about: Dio 请求诊断日志
  does: 打 method/uri/status/耗时到 AppLogger；流式成功体不预读，避免破坏 NDJSON 消费。
  kind: local

EntitlementSignalInterceptor:
  file: lib/services/entitlement_signal_interceptor.dart
  about: 从响应头读权益信号
  does: 计费/转录等响应带 x-entitlement-active 时通知订阅层；与本地权益不一致则回源对账（退款/到期无需轮询）。
  kind: local
  response_header: "x-entitlement-active: 1|0"  # 服务端权益快照
```

---

## 2. 句级 AI（流式）

```yaml
SentenceAiApiClient:
  file: lib/services/sentence_ai_api_client.dart
  about: 句级 AI 流式客户端
  does: >
    精听/查词面板/意群高亮/复述评估等调用：流式返回翻译、语法解析、AI 词典、
    意群切分、复述打分；UI 逐帧渐显。需登录；402 映射额度不足。
  kind: backend
  client: createAuthenticatedBackendDio + configureAiHttpClientAdapter
  transport: HTTPS HTTP/2（生产）+ Dio stream
  auth: Bearer accessToken（每请求 Options.headers）
  request: 多数 application/json；evaluate-review 为 multipart/form-data
  response: NDJSON ops 协议（见 §0）；非 200 为小 JSON
  timeouts: connect 15s / receive 30s（到首字节）；帧间 idle 30s
  # 下列成功体均为 NDJSON Ops：逐帧累积 → 下列 schema；末帧 {"done":true}
  # 非 200：小 JSON {code,error}；401 登录；402 额度（lookup 另见）
  # 每个 endpoint 必有 purpose（干什么）；字段树见 body / response_*
  endpoints:
    - method: POST
      path: /api/v1/stream/translate
      purpose: 精听/句详情点「翻译」——只译当前句（可带前后文），流式吐出译文供面板展示
      body:
        text: string                       # 目标句
        previousText: string?              # 上文，可选
        nextText: string?                  # 下文，可选
        targetLanguage: string?            # BCP 47，如 zh-CN
      response_proto: NdjsonOpsProtocol
      response_object:                     # 累积成 SentenceTranslation
        translation: string                # 译文；ops 路径 ["translation"]

    - method: POST
      path: /api/v1/stream/analyze
      purpose: 精听点「解析」——对单句做语法/词汇/听力要点分析，流式填入解析卡
      body:
        text: string                       # 目标句原文
        targetLanguage: string?            # BCP 47，如 zh-CN
      response_proto: NdjsonOpsProtocol
      response_object:                     # 累积成 SentenceAnalysis（半成品可空）
        grammar:                           # 语法要点 1~3
          - point: string                  # 结构/句型短标签
            note: string                   # 通俗说明
        vocabulary:                        # 词汇 0~4
          - term: string                   # 原句中的词/短语
            note: string                   # 含义/搭配
        listening:                         # 听力难点 1~3
          - phrase: string                 # 原句片段
            note: string                   # 连读/弱读等说明
      # ops 例：["grammar",0,"point"] / ["vocabulary",1,"note"]

    - method: POST
      path: /api/v1/stream/lookup-word
      purpose: 查词面板「AI 词典」查单词——流式生成结构化词条；与本地 ECDICT 互补；计额度
      body:
        query: string                      # 单词（规范化后无空白）
        targetLanguage: string?            # BCP 47，如 zh-CN
      response_proto: NdjsonOpsProtocol
      response_object:                     # 累积成 DictionaryEntry（单词）
        headword: string                   # 词头（原形）
        pronunciation:                     # 英美音标，可空串
          uk: string                       # 英式 IPA
          us: string                       # 美式 IPA
        meanings:                          # 词义列表（常用在前）
          - partOfSpeech: string           # n./v./adj.…
            translation: [string]          # 目标语对译，每条一项
            definition: string             # 英英释义
            usageNote: string              # 用法注（语域/易混），可空
            examples:                      # 中英对照例句
              - sentence: string           # 英文例句
                translation: string        # 译文
            synonyms: [string]             # 同义词
            antonyms: [string]             # 反义词
        commonExpressions:                 # 搭配/习语/短语动词
          - expression: string             # 表达本体
            type: string                   # collocation|idiom|phrasal verb|…
            meaning: string                # 含义或用法注
            example:                       # 单条例句
              sentence: string
              translation: string
        wordFamily:                        # 词族（派生/相关词形）
          - word: string                   # 相关词
            partOfSpeech: string           # 词性
            meaning: string                # 与词头不同处的简明释义
            example: { sentence, translation }
        forms:                             # 屈折变化
          - form: string                   # 英文形式，如 did / done
            label: string                  # 目标语标签，如「过去式」
        etymology: string                  # 词源简注，可空
        learnerTips: [string]              # 学习者提示，每条一项
      errors: 401 需登录 | 402 额度

    - method: POST
      path: /api/v1/stream/lookup-phrase
      purpose: 查词面板「AI 词典」查多词/短语——自然度、类别、要点与相近表达；过长 phrase_too_long
      body:
        query: string                      # 多词/短语（含空白）
        targetLanguage: string?            # BCP 47，如 zh-CN
      response_proto: NdjsonOpsProtocol
      response_object:                     # 累积成 MultiWordDictionaryEntry
        originalExpression: string         # 表达本体；兼容缺省时读 headword
        naturalness: string                # 不自然时的纠正说明；自然可空
        category: string                   # 短语动词/搭配/习语/术语…
        pronunciationTips: [string]        # 连读/弱读/重音等，可空列表
        keyPoints:                         # 核心要点（重要在前）
          - point: string                  # 要点说明（目标语）
            sentence: string               # 英文例句，可空
            translation: string            # 例句译文，无例句则空
        meanings:                          # 各义项
          - translation: [string]          # 目标语对译
            examples:
              - sentence: string
                translation: string
        similarExpressions:                # 相近/替代/易混
          - expression: string             # 相近表达
            difference: string             # 与原表达差异说明
            sentence: string               # 例句
            translation: string            # 例句译文
        background: string                 # 补充背景，可空
      errors: 400 phrase_too_long | 401 | 402

    - method: POST
      path: /api/v1/stream/sense-groups
      purpose: 精听/意群模式——把一句切成 medium/fine 两档意群，供高亮与分段跟读；不翻译
      body:
        text: string                       # 原句；无意群目标语言字段
      response_proto: NdjsonOpsProtocol
      response_object:                     # 累积成 SenseGroupResult
        medium: [string]                   # 中等粒度意群（口语节奏）
        fine: [string]                     # 细粒度意群
      # 通常先推 medium[] 再 fine[]；列表可有 null 占位洞，客户端过滤

    - method: POST
      path: /api/v1/stream/evaluate-review
      purpose: 复述结束后上传录音+原文，AI 打分并给出要点覆盖/纠错/建议，驱动复述报告页
      content_type: multipart/form-data
      body:
        file: MultipartFile                # 本地录音，filename retell-review.m4a
        originalText: string               # 复述对照原文
        language: "en"                     # 固定写死英语源
        targetLanguage: string             # 评估说明语言（BCP 47）
      metering: 后端 retell_review 口径
      response_proto: NdjsonOpsProtocol
      response_object:                     # 累积成 RetellReviewEvaluation
        transcript: string                 # 整段录音转写（常经 meta 写入）
        summary: string                    # 总评
        rating: poor|fair|good|excellent|perfect?  # 可晚到
        suggestion: string                 # 一条高价值建议，可空
        keyPoints:                         # 要点还原，上限约 20
          - keyPoint: string               # 母语表述（成形信号）
            original: string               # 原文摘录，可空
            transcript: string             # 口语音转摘录，可空
            status: covered|partial|missed|distorted|added?
            feedback: string               # 该条反馈，可空
        corrections:                       # 局部纠错，上限约 10
          - type: grammar|wordChoice|redundancy|phrasing|cohesion?
            transcript: string             # 问题片段
            correction: string             # 更正说法
            explanation: string            # 母语说明
```
---

## 3. 云端转录

```yaml
TranscriptionApiClient:
  file: lib/services/transcription_api_client.dart
  about: 云端 AI 转录流水线客户端
  does: >
    导入音频无字幕时：按 sha256 取预签名 URL → PUT 到 R2 → 提交转录任务 →
    轮询 job → 拉回句子/词级时间戳入库。命中缓存则跳过上传或直接返回 transcript。
  kind: backend
  client: createAuthenticatedBackendDio（自家 API）；R2 上传用裸 Dio
  transport: HTTPS HTTP/1.1（未挂 AI h2 adapter）
  auth: Bearer accessToken（自家 API）；R2 靠预签名 URL
  request: application/json（API）；PUT raw file（R2）
  response: application/json
  endpoints:
    - method: POST
      path: /api/v2/user-audio/upload-url
      purpose: 云端转写第一步——按 sha256 问是否已在对象存储；否则签发预签名 PUT URL
      body:
        sha256: string                     # 音频内容指纹
        mimeType: string                   # MIME 类型
        fileSize: int                      # 文件字节数
      response:
        audioExists: bool                  # true → 可跳过 PUT 上传
        uploadUrl: string?                 # 预签名 PUT URL；仅 audioExists=false
        objectName: string?                # R2 对象路径
        publicUrl: string?                 # R2 公开访问 URL

    - method: PUT
      path: "<presigned R2 URL>"           # 完整 URL，非自家 base
      purpose: 客户端把音频字节直传 R2（不经自家 API 中转文件体）；Go 只负责签发 URL
      headers:
        Content-Type: mimeType             # 须与申请 upload-url 时一致
        Content-Length: fileLength         # 上传字节长度
      body: 文件字节流（file.openRead()）
      note: 裸 Dio + ApiLogInterceptor(tag=R2-UPLOAD)；不带 x-app-*

    - method: POST
      path: /api/v2/user-audio/submit-transcription
      purpose: 上传完成（或 audioExists）后提交转写；命中缓存直接返回 transcript，否则返回 jobId
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
        cached: bool                       # true → 带 transcript，无 jobId
        jobId: string?                     # 异步任务 ID（cached=false）
        transcript: TranscriptResult?      # 结构同下方 GET transcript

    - method: GET
      path: /api/v2/user-audio/job-status/{jobId}
      purpose: 轮询异步转写是否完成；succeeded 后再拉 transcript
      response:
        status: queued|running|succeeded|failed  # 任务状态
        errorMessage: string?                    # 仅 failed；字段名是 errorMessage

    - method: GET
      path: /api/v2/user-audio/transcript
      purpose: 按内容指纹+语言取最终字幕（句子+可选词级时间戳），写入本地学习材料
      query:
        sha256: string                     # 音频内容指纹
        language: string                   # 转录语言
        mergeSentences: bool               # 是否合并短句，默认 true
      response:                            # TranscriptResult
        fullText: string                   # 全文
        sentences:
          - text: string                   # 句文本
            startTime: number              # 秒（浮点）
            endTime: number                # 秒（浮点）
            startWordIndex: int?           # 在 words[] 中的起始下标
            endWordIndex: int?             # 在 words[] 中的结束下标
        words:                             # 词级时间戳，可空列表
          - word: string                   # 词文本
            startTime: number              # 秒
            endTime: number                # 秒
```
---

## 4. 其它远端 API（多在 features/，同样走 BackendDio）

学习时一并对照；实现不在 `lib/services/` 根下。

```yaml
ChatApiClient:
  file: lib/features/chatbot/services/chat_api_client.dart
  about: 通用聊天流式客户端
  does: 句聊/助手页发多轮消息；流式吐出累计全文（delta）；endpoint 由调用方传入。
  kind: backend
  client: createAuthenticatedBackendDio + AI HTTP/2
  transport: HTTPS HTTP/2 + stream
  auth: Bearer accessToken
  request: application/json
  response: NdjsonTextProtocol（§0 B，delta 累积全文）
  endpoints:
    - method: POST
      path: 调用方传入，如 /api/v1/stream/chat/sentence
      purpose: 句聊/助手页发多轮对话——带历史与可选句上下文，助手回答以 delta 流式打出
      body:
        messages:                          # 多轮历史
          - role: string                   # user | assistant 等
            content: string                # 可含追问 <quote>…</quote>
        context: map?                      # 句聊上下文；空对象则省略不传
        targetLanguage: string?            # BCP 47，如 zh-CN
      response_proto: NdjsonTextProtocol
      response_frames:                     # 非累积对象，是文本帧
        delta: string                      # 追加到全文 buffer
        meta:                              # 可选元信息帧
          messageId: string?               # 服务端消息 id
        done: true                         # 正常结束
        __error: object?                   # 流内错误
      # 客户端最终：ChatTextFrame{ text, isFinal, messageId? }

PodcastRepository.feedFetch:
  file: lib/features/podcast/podcast_repository.dart
  about: 拉取第三方播客 RSS
  does: 订阅/刷新播客合集时 GET feedUrl，解析单集 enclosure 入库；遇反爬页抛错提示用户。
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
      purpose: 拉取该播客 RSS XML，解析单集 enclosure 入库；遇反爬页抛错
      options: { responseType: plain }
      # 解析后本地模型字段由 PodcastFeedParser 决定，非自家 JSON 契约

RemoteConfigService:
  file: lib/features/remote_config/remote_config_service.dart
  about: 客户端远程配置
  does: 启动/刷新拉 feature 开关与地区上下文；失败可走本地缓存或 defaults，控制云盘导入/AI 助手等能力显隐。
  kind: backend
  client: createBackendDio（通常无需登录）
  request: query-only
  response: application/json
  endpoints:
    - method: GET
      path: /api/v1/client/config
      purpose: 启动/刷新远程开关与地区上下文——控制云盘导入、AI 助手等显隐及转录上限
      query:
        platform: string                   # clientPlatformName()
      response:                            # RemoteConfig.fromRemoteJson
        version: int                       # 必填；当前客户端认 1，否则 FormatException
        ttlSeconds: int?                   # 缓存 TTL，缺省 86400；≤0 回退默认
        context:
          countryCode: string?             # 国家码；空/unknown → 客户端当 null
          platform: string?                # 回显平台，可空串
          channel: string?                 # 回显渠道，可空串
        features:
          cloudDriveImport:
            enabled: bool                  # 网盘导入总入口；默认 true
          showStoreWebCheckoutFallback:
            enabled: bool                  # 商店包 Web 支付兜底入口；默认 false
          aiChatAssistant:
            enabled: bool                  # AI 助手入口；默认 true
        limits:                            # 可选；嵌套 transcription
          transcription:
            maxDurationSeconds: int        # 云端转录最长秒数；默认 1800
            maxUploadBytes: int            # 云端转录最大字节；默认 25MB

PodcastCatalogService:
  file: lib/features/podcast/data/podcast_catalog_service.dart
  about: 官方播客推荐目录
  does: 资源库「发现播客」拉 /api/v1/catalog，只取 podcastCatalogs 展示可订阅节目列表。
  kind: backend
  client: createBackendDio
  endpoints:
    - method: GET
      path: /api/v1/catalog
      purpose: 资源库「发现播客」——返回运营推荐节目列表；客户端只读 podcastCatalogs
      response:
        podcastCatalogs:                   # 客户端只消费此字段
          - id: string                     # 目录条目 id
            title: string                  # 节目名
            description: string?           # 简介
            imageUrl: string?              # 封面
            applePodcastUrl: string        # Apple Podcasts URL（订阅优先）
            rssUrl: string                 # RSS feed URL（Apple 空时回退）

CommunityCollectionApi:
  file: lib/features/community_collections/data/community_collection_api.dart
  about: 社区合集 HTTP API
  does: 浏览公开合集、翻页文件、拉单文件元数据+字幕，供一键加入本地资料库学习。
  kind: backend
  client: createBackendDio
  request: query-only
  response: application/json
  endpoints:
    - method: GET
      path: /api/v2/collections
      purpose: 社区首页分页列出公开合集（约 20 条/页），供浏览与进入详情
      query:
        cursor: string?                    # 分页游标；首屏省略
      response:
        items:                             # PublicCollectionCatalogEntry，约 20/页
          - id: string
            name: string                   # 合集名
            description: string?
            coverUrl: string?
            authorNickname: string?
            fileCount: int                 # 文件数
            publishedAt: string            # ISO-8601
            updatedAt: string?             # 缺省等同 publishedAt
        nextCursor: string?                # 下一页；无则结束
    - method: GET
      path: /api/v2/collections/{collectionId}
      purpose: 打开某个合集——返回合集元信息 + 一页可学文件；翻页用 cursor
      query:
        cursor: string?
      response:
        collection:                        # 同目录条目形状
          id: string
          name: string
          description: string?
          coverUrl: string?
          authorNickname: string?
          fileCount: int
          publishedAt: string
          updatedAt: string?
        items:                             # CommunityCollectionFile 一页
          - id: string
            title: string
            description: string?
            mediaType: audio|video
            durationSec: int?
            fileSizeBytes: int?
            difficulty: A1|A2|B1|B2|C1|C2?
            publishedAt: string?
            sortOrder: int
            mediaUrl: string               # 媒体直链
        nextCursor: string?
    - method: GET
      path: /api/v2/collections/{id}/files/{fileId}
      purpose: 导入某集前拉取文件元数据 + 字幕；成功后可落成本地材料进入学习
      response:
        file:                              # 同 CommunityCollectionFile
          id: string
          title: string
          description: string?
          mediaType: audio|video
          durationSec: int?
          fileSizeBytes: int?
          difficulty: A1|A2|B1|B2|C1|C2?
          publishedAt: string?
          sortOrder: int
          mediaUrl: string
        subtitle:
          sentences:
            - text: string
              startTime: number            # 秒；客户端转 Duration
              endTime: number              # 秒；须 ≥ startTime
          words:                           # 词级；可空列表但字段必有
            - word: string
              startTime: number            # 秒
              endTime: number
      errors: 404 合集/文件不存在 | 422 字幕不可用

BackendBaiduOAuthApi:
  file: lib/features/baidu_netdisk/data/baidu_oauth_api.dart
  about: 百度网盘 OAuth 经自家后端中转
  does: 创建/轮询/确认授权会话、刷新 token；客户端不直持百度机密，用于网盘导入音频。
  kind: backend
  client: createBackendDio
  request: application/json
  response: application/json
  endpoints:
    - method: POST
      path: /api/v1/netdisk/baidu/oauth/session
      purpose: 开始网盘授权——创建会话，返回浏览器授权 URL 与轮询凭证
      body:
        platform: string                   # ios|android|macos|windows|linux
        forceLogin: bool?                  # 强制重新登录
      response:                            # BaiduOAuthSession
        sessionId: string                  # 不透明会话 ID
        pollToken: string                  # 一次性轮询凭证（仅内存）
        authorizationUrl: string           # 浏览器打开的百度授权 URL
        expiresAt: string                  # ISO-8601 UTC
        pollIntervalSeconds: int           # 建议轮询间隔，≥1
    - method: POST
      path: /api/v1/netdisk/baidu/oauth/session/status
      purpose: 授权过程中轮询——是否仍 pending、是否已拿到凭证、是否取消/失败
      body:
        sessionId: string
        pollToken: string
      response:                            # BaiduOAuthSessionStatus
        status: pending|exchanging|completed|canceled|failed
        credential:                        # 仅 completed 必有
          accessToken: string
          refreshToken: string
          expiresAt: string                # access 过期 ISO-8601 UTC
          scope: string                    # 百度 scope 原文
        error:                             # failed/canceled 可选
          code: string
          message: string
    - method: POST
      path: /api/v1/netdisk/baidu/oauth/session/acknowledge
      purpose: 客户端已安全收下凭证后告知后端，便于清理会话状态
      body:
        sessionId: string
        pollToken: string
      response: 空/确认即可
    - method: POST
      path: /api/v1/netdisk/baidu/oauth/refresh
      purpose: accessToken 过期时用 refreshToken 换新凭证，继续列目录/下文件
      body:
        refreshToken: string
      response:                            # BaiduCredentialBundle
        accessToken: string
        refreshToken: string
        expiresAt: string
        scope: string

BackendEntitlementRepository:
  file: lib/features/subscription/services/entitlement_repository.dart
  about: 用户订阅权益回源
  does: 登录后拉 /api/entitlements 得到是否 Premium；非 2xx 返回 null 走缓存，避免误降级关功能。
  kind: backend
  client: createAuthenticatedBackendDio
  auth: Bearer + authRetryOnceOptions
  endpoints:
    - method: GET
      path: /api/entitlements
      purpose: >
        查询是否 Premium 及到期/续订；force=1 强刷。
        isPremium=false=权威免费；非 2xx 不当成免费（走缓存）
      query:
        force: "1"?                        # 强制回源；省略则允许中间层缓存
      response:
        isPremium: bool                    # false = 权威免费（可降级）
        entitlementIds: [string]?          # 权益 id 列表
        productId: string?                 # 当前商品 id
        expiresAtMs: int?                  # UTC 毫秒到期
        willRenew: bool?                   # 是否将自动续订
        source: string?                    # 权益来源标识
        purchaseType: string?              # subscription|one_time|… → 客户端映射周期
      # 非 2xx → 失败走缓存，不把错误当成「降级为免费」

PaddleBillingRepository / PaddlePlansService:
  file: lib/features/subscription/services/paddle_*.dart
  about: Paddle 订阅结账与门户
  does: 展示套餐；创建托管 checkout 打开支付；创建 portal 管理订阅/取消；已有权益时 409。
  kind: backend
  client: authenticated + 部分公开 Dio
  endpoints:
    - method: GET
      path: /api/paddle/plans
      purpose: 订阅/付费墙展示可买套餐（月/年及可选一次性）与地区化价格
      response:
        serverTime: string?                # 服务端时间，缓存 meta 用
        plans:                             # 自动续费订阅；planId 现认 plus_monthly|plus_yearly
          - planId: string
            priceString: string            # 地区化续费价（含币种符号）
            hasFreeTrial: bool?            # 是否免费试用
            trialDays: int?                # 试用天数；无试用为 0
            introOffer:                    # 可选促销
              discountType: "percentage"   # 现仅认 percentage
              discountPercent: number      # 1~100；客户端推算优惠价串
              renewalPriceString: string   # 促销结束后续费价展示
              period: day|week|month|year?
              periodNumberOfUnits: int?    # 促销周期单位数，默认 1
              cycles: int?                 # 促销周期次数，默认 1
              isFreeTrial: bool?           # 是否免费试用形态
        oneTimePlans:                      # 可选；单项坏数据忽略不拖垮订阅列表
          - planId: "plus_yearly_one_time" # 现仅认此 id
            priceString: string
            purchaseType: "one_time"
            accessType: "fixed_term"
            autoRenew: false
            duration: { unit: "year", count: 1 }
    - method: POST
      path: /api/paddle/hosted-checkout
      purpose: 用户点购买——创建 Paddle 托管结账，返回 checkoutUrl；幂等防连点
      body:
        planId: string                     # 与 plans / oneTimePlans 的 planId 对应
        locale: string                     # BCP 47 language tag
      headers:
        Authorization: Bearer ...
        Idempotency-Key: uuid              # 防重复下单
      response:
        attemptId: string                  # 结账尝试 id
        checkoutUrl: string                # 必须 https 可打开 URL
      errors: 409 + code=already_entitled
    - method: POST
      path: /api/paddle/portal
      purpose: 已订阅用户管理订阅（取消/换卡等）——返回短期 Customer Portal URL
      response:
        portalUrl: string                  # Customer Portal https URL

AppUpdateChecker:
  file: lib/services/app_update_checker.dart
  about: 检查是否有新版本
  does: iOS 查 App Store Lookup；其它平台拉自家 version.json；结果驱动更新弹窗/强制升级。
  kind: hybrid
  client: 裸 Dio（混打外网与自家，故不用全局 BackendDio header）
  endpoints:
    - method: GET
      path: https://itunes.apple.com/lookup
      purpose: iOS 查 App Store 最新版本，驱动更新弹窗（非自家契约）
      query:
        bundleId: string                   # App bundle id
        country: string?                   # 商店国家，可选
      response: text/javascript → jsonDecode
        # 常用 results[0].version / trackViewUrl 等；非自家契约
      headers: 不带 x-app-*
    - method: GET
      path: {apiBase}/version.json         # 非 iOS
      purpose: 非 iOS 检查更新——比较 latest/minimum，驱动可选更新或强制升级
      headers: clientInfoHeaders()         # 仅此请求带自家标识
      response:                            # AppUpdateInfo.fromJson
        latestVersion: string              # 必填；最新可用版本
        minimumVersion: string             # 必填；低于则强制更新
        releaseNotes:                      # 可选；locale → 文案
          zh: string?
          en: string?
          # …其它 locale key
        downloadUrl:                       # 可选；platform → url
          android: string?
          windows: string?
          macos: string?
          # …其它 platform key
        platforms:                         # 可选 v2；缺省用顶层字段
          ios:
            minimumVersion: string?        # iOS 渠道最低版本覆盖
          android:
            googlePlay:
              minimumVersion: string?
              storeUrl: string?
              fallbackUrl: string?
            apk:
              latestVersion: string?
              minimumVersion: string?
              downloadUrl: string?
```

---

## 5. 下载与资源安装

```yaml
ReliableHttpDownloader:
  file: lib/services/reliable_http_downloader.dart
  about: 通用可靠 GET 落盘
  does: 给 ASR/TTS/词典/播客等下载大文件；.part 续传、原子 rename、大小校验、结构化失败分类。
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
  about: 后台下载进度通知
  does: 播客单集等后台下载时限频刷新通知栏进度；不负责真正 HTTP，只管系统通知 UI。
  kind: hybrid
  note: 业务下载仍走 ReliableHttpDownloader / 任务协调器

DownloadTaskCoordinator / DownloadTaskStore:
  file: lib/services/download/
  about: 下载任务编排与持久化
  does: 管理可恢复的下载任务队列（状态落盘），避免杀进程后丢失进度/重复下。
  kind: hybrid

ResourceArchiveInstaller:
  file: lib/services/resource_archive_installer.dart
  about: CDN 归档安装通式
  does: 下载 zip/tar → 解压到目标目录 → 写安装清单；TTS/词典/发音库共用此流程。
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
  does: 记录已装资源 id/版本/校验，供启动自愈与「是否已下载」判断。
  kind: local

DictionaryDownloadManager:
  file: lib/services/dictionary_download_manager.dart
  about: 离线词典包下载安装
  does: 按母语从 CDN 拉 ECDICT SQLite ZIP，解压为 dict.sqlite，供本地查词；约 12MB。
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
  does: 简单 play/pause/seek 单文件场景（非学习任务主引擎）；封装平台播放器调用。
  kind: platform

MediaPlayerBackend / MediaKitPlayerBackend:
  file: lib/services/media_player_backend.dart 等
  about: 媒体播放后端抽象 + media_kit
  does: 随心听/视频等主播放能力；抽象便于测试注入 fake，真机走 media_kit。
  kind: platform

MediaKitDurationProbe:
  file: lib/services/media_kit_duration_probe.dart
  about: 音视频时长探测
  does: 导入材料入库前探测 totalDuration，避免库列表时长为 0。
  kind: platform

MediaSessionRouter:
  file: lib/services/media_session_router.dart
  about: 全 App 唯一系统媒体会话路由
  does: 决定谁占用锁屏/耳机线控；前台试听与学习后台播放物理隔离（见 CLAUDE 踩坑 §7.12）。
  kind: platform

EchoLoopMediaHandler / BackgroundAudioHandler:
  file: lib/services/echo_loop_media_handler.dart 等
  about: 锁屏控件与后台播放
  does: 盲听/精听等学习任务后台继续播，并上报进度到通知栏/锁屏。
  kind: platform

AudioPreviewController:
  file: lib/services/audio_preview_controller.dart
  about: 短音频试听状态机
  does: 设置页音色试听、发音预览等短片段播放，与主媒体会话隔离。
  kind: platform

NativeAudioDecoder:
  file: lib/services/native_audio_decoder.dart
  about: 原生音频解码通道
  does: 把压缩音频解成 PCM，供字幕自动校准、静音检测等本地算法用。
  kind: platform

MediaFullscreenService / WindowFullscreenService:
  file: lib/services/media_fullscreen_service.dart 等
  about: 全屏协调
  does: 视频页进/出全屏；桌面端同步窗口全屏状态。
  kind: platform

MediaSubtitleStyle:
  file: lib/services/media_subtitle_style.dart
  about: 视频画面字幕样式
  does: 存取画面内嵌字幕字号等偏好，供播放页渲染。
  kind: local

SilenceSkipDetector:
  file: lib/services/silence_skip_detector.dart
  about: 字幕间隙静音检测
  does: 根据句间空隙判断可跳过的静音段，支持「跳过静音」类播放体验。
  kind: local
```

---

## 7. 录音、语音、ASR

```yaml
RecordingService:
  file: lib/services/recording_service.dart
  about: 通用录音
  does: 跟读/复述等任务录用户语音到本地文件，供识别或上传评估。
  kind: platform

SpeechPracticePlatform:
  file: lib/services/speech_practice_platform.dart
  about: 录音识别平台通道
  does: 调系统/插件 ASR 把跟读录音转成文本，供打分比对。
  kind: platform

SpeechPracticeMatcher:
  file: lib/services/speech_practice_matcher.dart
  about: 识别文本与目标句比对
  does: 计算跟读匹配度/对错，驱动跟读结果 UI（非云端打分）。
  kind: local

SpeechPermissionService / SpeechCompletionDetector:
  file: lib/services/speech_permission_service.dart 等
  about: 录音权限；跟读完成判定
  does: 申请麦克风权限；根据音量/停顿判断用户是否说完一句。
  kind: hybrid

RetellReviewAudioPreparer:
  file: lib/services/retell_review_audio_preparer.dart
  about: 复述评估上传前转码
  does: 把复述录音转成后端可收的临时 m4a，再交给 evaluateReviewStream。
  kind: hybrid

AsrModelManager / AsrArchiveInstaller:
  file: lib/services/asr/asr_model_manager.dart 等
  about: 离线 ASR 模型下载安装
  does: 用户开启设备转录时下载 Whisper/VAD 模型包，供无网或隐私场景本地转写。
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
  about: 本地 ASR 推理
  does: 用已装模型对音频文件做离线转写（sherpa-onnx）；读入波形、跑 VAD/识别。
  kind: local
```

---

## 8. TTS 与发音库

```yaml
KokoroModelManager / PiperModelManager:
  file: lib/services/tts/kokoro_model_manager.dart / piper_model_manager.dart
  about: TTS 模型下载安装
  does: 用户选用本地 TTS 时从 CDN 拉 Kokoro/Piper 模型归档并安装，供离线朗读。
  kind: hybrid
  client: 裸 Dio + ResourceArchiveInstaller
  transport: HTTPS GET → tar.gz
  uri: modelCdnUri("/model/{voice|spec.archivePath}")
  archiveFileName: "_download_{id}.tar.gz"  # 本地下载临时名模板

KokoroSynthesizer / PiperSynthesizer / *TtsEngine:
  file: lib/services/tts/
  about: 本地语音合成
  does: 把文本合成 PCM/音频文件；统一 TTS 主干用于查词发音回退、句子朗读等。
  kind: local

PronunciationLibraryManager:
  file: lib/services/pronunciation/pronunciation_library_manager.dart
  about: 离线真人发音库安装
  does: 下载 pronunciation-v2.zip；词典就绪后自动/自愈安装，供单词真人发音。
  kind: hybrid
  transport: HTTPS GET
  uri: modelCdnUri(pronunciationSpec.archivePath)
  catalog: pronunciation_catalog.dart → dictionary/pronunciation-v2.zip

PronunciationRepository / LocalAudioClipPlayer / SourceSentencePlayer:
  file: lib/services/pronunciation/
  about: 发音查询与片段播放
  does: 查词优先播库内 US Opus；多发音展示 badge；也可播原句时间轴区间；失败回退 TTS。
  kind: platform
```

---

## 9. 词典（查询侧）

```yaml
DictionaryService:
  file: lib/services/dictionary_service.dart
  about: 本地 SQLite 词典查询
  does: 打开 dict.sqlite（ECDICT 数据）精确查词；返回音标/释义/柯林斯星/考试标签。
  kind: local

DictionarySource 族:
  file: lib/services/dictionary/
  about: 多词典源抽象
  does: >
    查词面板可切换：本地 ECDICT、AI 流式释义、Cambridge/Oxford 等网页（只开 URL 不解析 HTML）。
    本地源不可关、不需网；AI/网页需网与登录或额度。
  kind: hybrid
  ai_source: 委托 SentenceAiApiClient lookup-word / lookup-phrase（NDJSON）
  web_source: 加载网页 URL（非自家 API JSON）

DictionaryCatalog:
  file: lib/services/dictionary/dictionary_catalog.dart
  about: 词典包目录元数据
  does: 固定简繁 ZIP 的 resourceId / path / sha256 / 体积，供下载管理器定位 CDN 资源。
  kind: local
```

---

## 10. 字幕与导出

```yaml
SubtitleParser / LrcParser:
  file: lib/services/subtitle_parser.dart / lrc_parser.dart
  about: 字幕/歌词文件解析
  does: 导入 SRT/VTT/LRC 时解析成句子时间轴，写入学习材料。
  kind: local

SubtitleAutoAlignService:
  file: lib/services/subtitle_auto_align_service.dart
  about: 字幕时间轴本地校准
  does: 用解码 PCM + 静音检测微调句边界；失败则保留原时间轴，避免越校越差。
  kind: local
  inputs: 音频路径 + 句子时间轴；失败回退原始字幕

AudioExportService:
  file: lib/services/audio_export_service.dart
  about: 音频条目导出
  does: 把库中条目导出为用户可分享的音频/附带文件包。
  kind: local

StudyPdfExportService / Builder / Loader:
  file: lib/services/pdf_export/
  about: 学习材料 PDF 导出
  does: 组装句子/释义等生成 PDF，供打印或外部复习。
  kind: local
```

---

## 11. 存储、备份、清理

```yaml
StorageService:
  file: lib/services/storage_service.dart
  about: SharedPreferences 薄封装
  does: 读写轻量偏好（开关、上次状态等），非业务主库（主库是 Drift）。
  kind: local

StorageMigrationService / BackupService:
  file: lib/services/storage_migration_service.dart / backup/
  about: 目录迁移与备份恢复
  does: 版本升级时搬数据目录；用户备份/恢复学习数据+媒体+离线词典。
  kind: local

OrphanFileCleanupService / TempCleanupService:
  file: lib/services/orphan_file_cleanup_service.dart 等
  about: 孤儿文件与临时目录清理
  does: 删库记录已不在但磁盘残留的媒体；清临时转码/下载碎片，回收空间。
  kind: local

BundledExampleInstaller / DemoDataSeeder:
  file: lib/services/bundled_example_installer.dart 等
  about: 内置示例与演示数据
  does: 首启或演示模式安装示例音频/字幕，让新用户立刻能走学习闭环。
  kind: local
```

---

## 12. 学习统计与提醒

```yaml
StudyTimeService / StudySessionTimer / StudyActivityGate:
  file: lib/services/study_*.dart
  about: 学习时长统计
  does: >
    Gate 根据前后台决定是否计时；Timer 量单阶段墙钟；TimeService 写入日/阶段统计，
    驱动学习报告与今日时长。
  kind: hybrid

ReviewReminderService / ReviewReminderTimeCalculator:
  file: lib/services/review_reminder_*.dart
  about: 收藏复习本地通知
  does: 按调度算下次提醒时刻，注册本地通知，到点唤起用户复习收藏句/词。
  kind: platform

LearnedVocabularyTracker:
  file: lib/services/learned_vocabulary_tracker.dart
  about: 已学词汇追踪
  does: 记录用户学过的词，供统计或复习相关能力查询。
  kind: local
```

---

## 13. 系统集成

```yaml
AppLogger / StartupTrace:
  file: lib/services/app_logger.dart 等
  about: 诊断日志与启动耗时
  does: 内存环+文件日志便于排障；StartupTrace 分段记启动各步耗时。
  kind: local

AppDeepLinkRouter:
  file: lib/services/app_deep_link_router.dart
  about: Deep Link 解析分发
  does: 处理 echo-loop:// 等外链，跳到对应页（订阅回跳、分享入口等）。
  kind: platform

AppUpdateLauncher / AndroidUpdateBridge:
  file: lib/services/app_update_launcher.dart 等
  about: 执行更新动作
  does: 打开商店页或下载安装包；Android 经原生桥处理 APK 安装流程。
  kind: platform

NotificationPermission* / NetworkPermissionTrigger:
  file: lib/services/notification_*.dart / network_permission_trigger.dart
  about: 通知与 iOS 网络权限
  does: 申请通知权限、上报结果、处理通知点击路由；iOS 启动时触发系统网络权限弹窗。
  kind: platform

AppWindowService / AppNotice / AppNetworkImageCache:
  file: lib/services/app_window_service.dart 等
  about: 桌面窗口 / Toast / 图片缓存
  does: 控制 macOS/Windows 窗口；跨页统一提示；网络封面等磁盘缓存。
  kind: hybrid

UserIdService / DeviceDiagnosticsService / RefreshCoordinator:
  file: lib/services/user_id_service.dart 等
  about: 本地用户 ID、诊断、刷新去重
  does: 生成稳定匿名用户 id；采集设备信息排障；合并并发刷新请求避免风暴。
  kind: hybrid

EmbeddingSimilarity / TextEmbeddingPlatform:
  file: lib/services/embedding_similarity.dart 等
  about: 文本向量相似度
  does: Apple 上走 NLEmbedding 通道算语义相近；用于相关匹配类能力（非云端 embedding API）。
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

- 每条必须有 **`does`**（谁用、何时用、产出）。  
- 远端另补：`client/transport/auth/request/response/endpoints`（含 body 字段）。  
- Feature 内 API 客户端可记在 §4，避免只扫 `lib/services/` 根目录漏掉。


