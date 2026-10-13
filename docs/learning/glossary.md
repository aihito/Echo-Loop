# 术语小词典（前端小白向）

> 读 [业务模型](./business-models.md)、[核心服务](./core-services.md) 时遇到的词，用白话解释。  
> 不求学术严谨，求「能看懂文档在说啥」。源码/协议为准。  
> 最后更新：2026-10-13  
> 入口：[学习地图](./README.md)

按字母 / 拼音首字母速查；同义写法写在括号里。

---

## 网络与请求

### HTTP / HTTPS
浏览器、App 跟服务器说话的协议。`https://` 是加密版。文档里的 `GET` / `POST` / `PUT` 是不同「动词」：  
- **GET**：要数据（查配置、查任务状态）  
- **POST**：提交数据（翻译、上传元信息）  
- **PUT**：上传一整份内容（例如把音频文件塞进 R2）

### Endpoint（端点）
一个具体 URL 路径，比如 `/api/v1/stream/translate`。  
「打某个端点」= 对这个路径发 HTTP 请求。

### Header（请求头 / 响应头）
请求或响应里附带的小标签，不是正文。例如：  
- `Authorization: Bearer …`：我是谁  
- `Content-Type`：正文是 JSON 还是文件  
- `x-app-platform`：本 App 自定义，告诉后端平台是 iOS/Android…

### Body（请求体）
POST/PUT 时真正送过去的内容。常见：  
- **JSON**：`{"text":"hello"}` 文本对象  
- **multipart / FormData**：又有字段又有文件（复述评估上传录音）  
- **raw bytes**：原始文件字节流（R2 上传）

### JSON
一种文本数据格式，长得像：`{"name":"Echo","ok":true}`。前后端交换结构化数据时最常用。

### NDJSON（Newline Delimited JSON）
**一行一个 JSON 对象**，用换行隔开，而不是一个大数组。  

适合**流式**：服务器想说一点推一点，不用等全部说完。  

本仓库两种用法（详见 [core-services §0](./core-services.md#0-公共约定文档概念不是-dart-类名)）：  
- **Ops 协议**：每行改 JSON 对象的某个字段（翻译/词典渐显）  
- **Text 协议**：每行往一段文字后面加字（聊天打字机效果）

### Stream / 流式响应
响应不是「一次性整包到达」，而是边生成边往下推。  
客户端用 `ResponseType.stream` 读，UI 可以逐帧刷新。  
和「普通 JSON 一次返回」相对。

### Dio
Flutter/Dart 里常用的 **HTTP 客户端库**（类似前端的 axios / fetch 封装）。  
本仓库打自家 API 时经 `createBackendDio` 统一创建。

### Interceptor（拦截器）
Dio 在「请求发出前 / 响应回来后」自动跑的钩子。  
用来加 header、打日志、读权益信号、Token 过期处理等，业务代码不用每次手写。

### Bearer Token / accessToken
证明「已登录」的一串令牌。请求头写成：  
`Authorization: Bearer <accessToken>`  
本 App 的登录态来自 **Supabase**；过期前由 Token Gate 刷新。

### Token Gate
发请求前检查 accessToken 还有效不；快过期就 refresh。  
不是单独网页，是客户端协调逻辑（`SupabaseTokenCoordinator`）。

### HTTP/1.1 vs HTTP/2
两种在 HTTPS 上传数据的「管道方式」。  
HTTP/2 可在一条连接上更好复用，本仓库 **AI 流式接口**默认走 HTTP/2；本地 `http://localhost` 仍用 1.1。

### CDN
Content Delivery Network：把**静态大文件**（模型 zip、词典包）放到离用户近的节点下载。  
和「自家业务 API」不是同一台服务；本仓库叫 **model CDN**。

### R2
Cloudflare 的对象存储（像一个云硬盘桶）。  
转录流程：先向自家 API 要**预签名 URL**，再 **PUT** 音频直传 R2，不经过自家服务器中转文件体。

### Presigned URL（预签名 URL）
带时效和权限的临时上传/下载地址。拿到后可直接 PUT/GET 文件，不必把云存储密钥放进 App。

### SHA-256（sha256）
文件内容的指纹（哈希）。同一文件指纹相同。  
转录用它判断「这音频以前传过没有」→ 可跳过上传或命中字幕缓存。

### HTTP Range（断点续传）
下载时说「只要文件从第 N 字节开始的部分」。  
大文件中断后可接着下，不必从头来（ReliableHttpDownloader）。

### MIME / Content-Type
标明「这是什么类型的数据」，如 `audio/mpeg`、`application/json`、`image/png`。

### CancelToken
Dio 里用来**取消进行中请求**的令牌。用户关掉面板或离开页面时，避免过期回调还改 UI。

### Status code（状态码）
服务器用数字表示结果：  
- `200` 成功  
- `401` 未登录 / token 无效  
- `402` 本仓库常表示额度不足  
- `404` 找不到  
- `409` 冲突（如已有订阅还去结账）

### BCP 47（如 `zh-CN`）
语言标签标准写法：语言 + 可选地区。`zh-CN` 简体，`zh-TW` 繁体，`en` 英语。

---

## 本仓库特有约定名（不是 Dart 类）

### BackendCommon
打**自家后端 API** 时共用的规矩：地区基址、平台/渠道头、可选登录、权益响应头。  
详见 core-services §0。

### NdjsonOpsProtocol
流式**拼 JSON 对象**的 NDJSON 约定（句 AI、AI 词典）。

### NdjsonTextProtocol
流式**拼纯文本**的 NDJSON 约定（句聊）。

### ModelCdnCommon
从 CDN **下载离线资源包**（模型/词典）的规矩：裸 GET、不带自家 API header。

---

## 登录、订阅、配置

### Supabase
第三方后端服务，本 App 用它做**账号登录**（邮箱等）。  
拿到的 session 里有 `accessToken`，再拿去调自家 API。

### GoTrue
Supabase 的认证模块名；文档里「GoTrue SDK / refreshSession」= 刷新登录令牌。

### Entitlement（权益）
用户是否 Premium、能用哪些付费能力。  
可从 `/api/entitlements` 拉取；响应头 `x-entitlement-active` 可提示客户端「该对账了」。

### Paddle
第三方支付/订阅平台。App 向自家后端要 checkout URL，打开网页完成付款。

### Remote Config（远程配置）
启动时从服务器拉开关（某功能开不开、地区信息等），不用发版就能改行为。

### OAuth
「用别的账号授权登录/授权」的标准流程。  
例：百度网盘导入时，经自家后端中转完成授权，App 不持有网盘机密。

### Idempotency-Key
结账等「不能点两次就扣两次」的请求带的唯一键；服务器用来去重。

---

## 数据与本地存储

### SQLite
手机/电脑上的轻量数据库文件。离线词典 `dict.sqlite`、部分资源清单等用它。

### Drift
Flutter 里写 SQLite 的库（类型安全的 ORM）。业务主库多在 `lib/database/`。

### SharedPreferences
存少量键值偏好（开关、简单标记），不是主业务库。

### Manifest（安装清单）
记录「某个离线资源装过没有、版本/校验是什么」的小文件，方便启动自愈、避免重复下。

### Model / State（业务文档语境）
- **Model**：业务数据（一条音频、一句字幕）  
- **State**：界面运行态（加载中、当前句下标）  
Model 不依赖 State；State 可以包含 Model。

---

## 音频 / 语音相关

### ASR（Automatic Speech Recognition）
语音识别：声音 → 文字。本仓库有云端转录，也有离线 Whisper。

### TTS（Text To Speech）
文字 → 声音。本地有 Kokoro / Piper 等引擎；也可用系统 TTS。

### VAD（Voice Activity Detection）
检测「这段是人声还是静音」。离线 ASR 常用 Silero VAD。

### Whisper
OpenAI 开源的语音识别模型族；本仓库离线 ASR 用其量化版（tiny/base/small）。

### PCM
未压缩的原始波形采样数据。本地算法（字幕校准、静音检测）常先解码成 PCM。

### Opus
一种高效音频压缩格式；离线发音库里单词发音常用 Opus。

### media_kit
跨平台音视频播放引擎（底层常接 mpv）。随心听/视频等主播放走它。

### audio_service / MediaSession
把播放状态交给**系统**：锁屏控件、耳机线控、通知栏进度条。  
本仓库用 MediaSessionRouter 保证全 App 只有一套会话逻辑。

### Clip / 区间播放
不播整首，只播某一时间段（某一句的 start～end）。

---

## 播客与字幕

### RSS / RSS 2.0
播客节目的「订阅源」XML。本仓库**只认 RSS 2.0 + enclosure**；Atom 不支持。

### Enclosure
RSS 里指向音频文件的标签（真正的 mp3/m4a 地址）。没有 enclosure 就当不了可学材料。

### Atom
另一种订阅 XML 格式（YouTube 等常用）。本 App 解析器当前不支持。

### SRT / VTT / LRC
常见字幕/歌词文件格式。导入后解析成带时间轴的句子列表。

### Transcript / 字幕 / 转写
音频对应的带时间的文字。可来自本地文件、云端 AI、设备离线 ASR。

---

## 工程与 Flutter（读代码常碰到）

### Provider / Riverpod
状态管理：UI 读「当前状态」，通过 Notifier 改状态。本仓库用 Riverpod（常带代码生成 `.g.dart`）。

### GoRouter
声明式路由：URL ↔ 页面。有「壳内 Tab」和「壳外全屏学习页」之分。

### Shell / 壳
带底栏/侧栏的主框架。学习播放页多在壳外全屏，避免被 Tab 抢走返回栈。

### Feature
按功能分包的目录（`lib/features/podcast` 等），里面可有自己的 API/UI。

### Repository
只管数据存取（网络/数据库），不管完整业务流程编排。

### Platform Channel / 原生桥
Dart 调 iOS/Android/macOS 原生代码的通道（录音权限、部分解码、更新安装等）。

### FFI
Dart 直接调本地 C/C++ 库（如 sqlite3、sherpa-onnx）。Web 上通常不可用。

### build_runner
根据注解生成代码（Riverpod、Drift、json 等）的命令行工具。

### l10n / ARB
国际化：文案写在 `.arb`，生成 `AppLocalizations`。模板是 `app_en.arb`。

---

## 学习产品用语（和代码枚举相关）

### 盲听 / 精听 / 跟读 / 复述
学习闭环里的阶段：先听懂大意 → 逐句抠 → 跟读模仿 → 口头复述。

### 收藏 / 复习 / 调度（scheduler）
把难句/词标收藏，按间隔提醒再练（本地通知 + 记忆调度）。

### ECDICT
开源英汉词典数据；本地离线查词库来源。  
https://github.com/skywind3000/ECDICT

### Lemmatize / 原形
把 `running` 等还原成词典里的基本形式 `run`。本仓库本地查词主要按**表面词形**精确匹配，避免错配。

---

## 怎么用这份表

1. 扫 [core-services](./core-services.md) / [business-models](./business-models.md) 时，生词先查这里。  
2. 仍不懂：看对应服务的 `does` + 源码文件头 `///` 注释。  
3. 发现文档用了新黑话但这里没有：补一条到本文件（保持「一句话能懂」）。
