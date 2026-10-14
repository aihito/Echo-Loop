# 自家后端 API 契约（客户端视角）

> 供用 **Go（或其它语言）重写/对接后端** 时对照。  
> 字段名、路径以 Flutter 客户端源码为准；不是 OpenAPI 生成物。  
> 术语：[glossary.md](./glossary.md) · 服务索引：[core-services.md](./core-services.md)  
> 最后更新：2026-10-13 · 入口：[学习地图](./README.md)

```yaml
# 每条接口固定形状
Endpoint:
  method: GET|POST|PUT
  path: /api/...
  purpose: 一句话：谁用、干什么、产出什么   # 必有
  auth: none | Bearer   # Bearer = Supabase accessToken
  request:              # Content-Type + body/query
  response:             # 成功形态
  errors:               # 客户端会处理的状态码
```

---

## 0. 全局约定

### 0.1 基址与 Region

客户端按系统地区在 **全球 / 中国** 固定选一个 `apiBaseUrl`（不跨区回退）。  
Go 部署需两套或同源多入口，与客户端 `RuntimeEndpointRouter` 配置一致。

### 0.2 每个请求可能带的公共 Header

| Header | 必填 | 含义 |
|--------|------|------|
| `x-app-platform` | 建议 | ios / android / macos / windows / … |
| `x-app-distribution` | 建议 | appstore / play / sideload / …（编译期渠道） |
| `x-app-version` | 可选 | 端上版本号，可缺 |
| `Authorization` | 按接口 | `Bearer <supabase_access_token>` |

后端可按「平台+渠道」做 AI 免费额度等策略（缺 header 时建议 fail-open，兼容老客户端）。

### 0.3 计费类响应可附带

| Header | 值 | 含义 |
|--------|-----|------|
| `x-entitlement-active` | `0` / `1` | 服务端当前权益快照；客户端与本地不一致则回源 `/api/entitlements` |

### 0.4 流式协议（两种 NDJSON）

成功时：`Content-Type` 建议 `application/x-ndjson` 或 `text/plain`；**一行一个 JSON**，立刻 flush。

**A) Ops（句 AI / AI 词典）** — 拼 JSON 对象：

```text
{"ops":[{"p":["translation"],"v":"你好"}]}
{"done":true}
```

- `ops[].p`：路径数组（字符串或数字下标）  
- `ops[].v`：叶子标量  
- `done: true`：正常结束  
- `__error`：流内错误  

**B) Text（句聊）** — 拼字符串：

```text
{"delta":"Hello"}
{"meta":{"messageId":"..."}}
{"done":true}
```

流未开时的非 200：小 JSON，例如 `{"code":"...","error":"..."}`。  
客户端常见映射：`401` 需登录，`402` 额度不足。

### 0.5 不在本契约内（勿当成自家 REST）

| 能力 | 谁做 |
|------|------|
| 登录注册 | Supabase Auth（Go 验 JWT） |
| 词典/TTS/ASR 模型包 | CDN 静态 GET |
| 播客 RSS 正文 | App 直连第三方 |
| R2 文件体 | 客户端 PUT 预签名 URL |
| iOS 查版本 | itunes.apple.com |

---

## 1. 句级 AI（优先实现）

均需 **Bearer**。除 evaluate-review 外为 `application/json`。响应：**NDJSON Ops**。  
更细字段树见 [core-services.md §2](./core-services.md#2-句级-ai流式)。

### 1.1 POST `/api/v1/stream/translate`

**用途**：精听/句详情点「翻译」——只译当前句（可带前后文），流式吐出译文供面板展示；不计学习进度。

| 方向 | 字段 | 类型 | 说明 |
|------|------|------|------|
| body | `text` | string | 要译的目标句 |
| body | `previousText` | string? | 上文 |
| body | `nextText` | string? | 下文 |
| body | `targetLanguage` | string? | BCP 47，如 `zh-CN` |
| 响应累积 | `translation` | string | ops 路径 `["translation"]` |

### 1.2 POST `/api/v1/stream/analyze`

**用途**：精听点「解析」——对单句做语法/词汇/听力要点分析，流式填入解析卡，帮助拆解难句。

| 方向 | 字段 | 类型 | 说明 |
|------|------|------|------|
| body | `text` | string | 原句 |
| body | `targetLanguage` | string? | 说明语言 |
| 响应累积 | `grammar[]` | `{point,note}` | 语法 1~3 |
| 响应累积 | `vocabulary[]` | `{term,note}` | 词汇 0~4 |
| 响应累积 | `listening[]` | `{phrase,note}` | 听力 1~3 |

### 1.3 POST `/api/v1/stream/lookup-word`

**用途**：查词面板「AI 词典」查**单词**——流式生成结构化词条（音标、多义、搭配、词族等），与本地 ECDICT 互补；计 AI 额度。

| 方向 | 字段 | 类型 | 说明 |
|------|------|------|------|
| body | `query` | string | 单词（无空白） |
| body | `targetLanguage` | string? | BCP 47 |
| 响应累积 | `headword` | string | 词头 |
| 响应累积 | `pronunciation.uk` / `.us` | string | 英/美 IPA，可空串 |
| 响应累积 | `meanings[]` | object | `partOfSpeech` / `translation[]` / `definition` / `usageNote` / `examples[{sentence,translation}]` / `synonyms[]` / `antonyms[]` |
| 响应累积 | `commonExpressions[]` | object | `expression` / `type` / `meaning` / `example{sentence,translation}` |
| 响应累积 | `wordFamily[]` | object | `word` / `partOfSpeech` / `meaning` / `example` |
| 响应累积 | `forms[]` | object | `form`（英文屈折）/ `label`（目标语标签） |
| 响应累积 | `etymology` | string | 词源，可空 |
| 响应累积 | `learnerTips[]` | string | 学习者提示 |

错误：`401`；`402` 额度。

### 1.4 POST `/api/v1/stream/lookup-phrase`

**用途**：查词面板「AI 词典」查**多词/短语**——解释是否自然、类别、要点与相近表达；过长返回 `phrase_too_long`。请求体同 1.3（`query` 含空白）。

| 方向 | 字段 | 类型 | 说明 |
|------|------|------|------|
| 响应累积 | `originalExpression` | string | 表达本体；兼容缺省读 `headword` |
| 响应累积 | `naturalness` | string | 不自然时纠正说明；自然可空 |
| 响应累积 | `category` | string | 短语动词/搭配/习语… |
| 响应累积 | `pronunciationTips[]` | string | 连读/重音等 |
| 响应累积 | `keyPoints[]` | object | `point` / `sentence` / `translation` |
| 响应累积 | `meanings[]` | object | `translation[]` / `examples[{sentence,translation}]` |
| 响应累积 | `similarExpressions[]` | object | `expression` / `difference` / `sentence` / `translation` |
| 响应累积 | `background` | string | 补充背景 |

错误另含 `400` + `code=phrase_too_long`。

### 1.5 POST `/api/v1/stream/sense-groups`

**用途**：精听/意群模式——把一句切成 `medium`/`fine` 两档意群，供高亮与分段跟读；只切分原文，不翻译。

| 方向 | 字段 | 类型 | 说明 |
|------|------|------|------|
| body | `text` | string | 原句（**无** targetLanguage） |
| 响应累积 | `medium` | string[] | 中等粒度意群 |
| 响应累积 | `fine` | string[] | 细粒度意群 |

### 1.6 POST `/api/v1/stream/evaluate-review`

**用途**：复述练习结束后——上传用户录音 + 对照原文，AI 打分并给出要点覆盖、纠错与建议，驱动复述报告页。  
`Content-Type: multipart/form-data`。计量口径：`retell_review`。

| 方向 | 字段 | 类型 | 说明 |
|------|------|------|------|
| body | `file` | file | 录音，常名 `retell-review.m4a` |
| body | `originalText` | string | 对照原文 |
| body | `language` | string | 客户端现写死 `"en"` |
| body | `targetLanguage` | string | 评估说明语言 |
| 响应累积 | `transcript` | string | 整段转写（可经 meta） |
| 响应累积 | `summary` | string | 总评 |
| 响应累积 | `rating` | enum? | poor…perfect |
| 响应累积 | `suggestion` | string | |
| 响应累积 | `keyPoints[]` | object | keyPoint/original/transcript/status/feedback |
| 响应累积 | `corrections[]` | object | type/transcript/correction/explanation |

`status`：`covered|partial|missed|distorted|added`；纠错 `type`：`grammar|wordChoice|redundancy|phrasing|cohesion`。

---

## 2. 云端转录（优先实现）

均需 **Bearer**（自家 API）。JSON。整条流水线：申请上传 → PUT 文件 → 提交任务 → 轮询 → 取字幕。

### 2.1 POST `/api/v2/user-audio/upload-url`

**用途**：云端转写第一步——按音频 `sha256` 询问是否已在对象存储；已有则跳过上传，否则签发预签名 PUT URL。

| 方向 | 字段 | 类型 | 说明 |
|------|------|------|------|
| body | `sha256` | string | 音频内容指纹 |
| body | `mimeType` | string | 如 `audio/mpeg` |
| body | `fileSize` | int | 字节数 |

响应：

| 字段 | 类型 | 说明 |
|------|------|------|
| `audioExists` | bool | true → 可跳过上传 |
| `uploadUrl` | string? | 预签名 PUT；仅 `audioExists=false` |
| `objectName` | string? | 对象路径 |
| `publicUrl` | string? | 公开访问 URL |

### 2.2 PUT `<presignedUrl>`（对象存储，非 Go 业务 path）

**用途**：客户端把音频字节直传 R2/对象存储（不经 Go 中转文件体）。Go 只负责签发 2.1 的 URL。  
请求：`Content-Type` + `Content-Length` + 原始字节。

### 2.3 POST `/api/v2/user-audio/submit-transcription`

**用途**：上传完成（或 `audioExists`）后提交转写——命中字幕缓存则直接返回 `transcript`；否则返回 `jobId` 供轮询。

| 方向 | 字段 | 类型 | 说明 |
|------|------|------|------|
| body | `sha256` | string | 必填 |
| body | `fileName` | string? | |
| body | `objectName` | string? | |
| body | `publicUrl` | string? | |
| body | `mimeType` | string? | |
| body | `fileSize` | int? | |
| body | `language` | string | 转录语言 |
| body | `mergeSentences` | bool | 默认 true；false=不合并短句 |

响应：

| 字段 | 类型 | 说明 |
|------|------|------|
| `cached` | bool | true → 带 `transcript`，无 `jobId` |
| `jobId` | string? | 异步任务 |
| `transcript` | object? | 见 2.5 结构 |

### 2.4 GET `/api/v2/user-audio/job-status/{jobId}`

**用途**：轮询异步转写任务是否完成；`succeeded` 后再调 2.5 拉字幕（或产品约定时机）。

响应：

| 字段 | 类型 | 说明 |
|------|------|------|
| `status` | string | `queued` / `running` / `succeeded` / `failed` |
| `errorMessage` | string? | 仅 failed（字段名是 **errorMessage**，不是 error） |

### 2.5 GET `/api/v2/user-audio/transcript`

**用途**：按内容指纹 + 语言取最终字幕（句子 + 可选词级时间戳），写入本地学习材料。

| 方向 | 字段 | 类型 | 说明 |
|------|------|------|------|
| query | `sha256` | string | |
| query | `language` | string | |
| query | `mergeSentences` | bool | |

响应 `TranscriptResult`：

| 字段 | 类型 | 说明 |
|------|------|------|
| `fullText` | string | 全文 |
| `sentences[].text` | string | 句文本 |
| `sentences[].startTime` / `endTime` | number | **秒**（浮点） |
| `sentences[].startWordIndex` / `endWordIndex` | int? | 在 `words` 中的下标 |
| `words[].word` | string | 词 |
| `words[].startTime` / `endTime` | number | **秒** |

`submit-transcription` 在 `cached=true` 时内嵌同一 `transcript` 对象。

---

## 3. 句聊

### 3.1 POST `/api/v1/stream/chat/sentence`

**用途**：句聊/助手页发多轮对话——带历史消息与可选句上下文，助手回答以 `delta` 流式打出（打字机效果）。  
需 **Bearer**。JSON。响应：**NDJSON Text**。其它入口也可换 path，body 形状相同。

| 方向 | 字段 | 类型 | 说明 |
|------|------|------|------|
| body | `messages` | array | `[{ role, content }, ...]`；role 为 `user`/`assistant` 等 |
| body | `context` | object? | 句聊上下文（可空对象则省略） |
| body | `targetLanguage` | string? | |

`content` 可能已含追问引用（`<quote>…</quote>` + 指令），由客户端 `toWire` 拼好。

---

## 4. 订阅与权益

### 4.1 GET `/api/entitlements`

**用途**：查询当前用户是否 Premium 及到期/续订信息；支付回跳或权益头不一致时用 `force=1` 强刷。  
需 **Bearer**（可 `authRetryOnce`）。`isPremium=false` 表示权威免费（可降级）；**非 2xx 不当成免费**，客户端走缓存。

| 方向 | 字段 | 类型 | 说明 |
|------|------|------|------|
| query | `force` | `"1"`? | 强制回源 |

响应：

| 字段 | 类型 | 说明 |
|------|------|------|
| `isPremium` | bool | false = 权威免费态 |
| `entitlementIds` | string[]? | |
| `productId` | string? | |
| `expiresAtMs` | int? | UTC 毫秒 |
| `willRenew` | bool? | |
| `source` | string? | |
| `purchaseType` | string? | 客户端映射周期 |

### 4.2 GET `/api/paddle/plans`

**用途**：订阅/付费墙展示可买套餐（月/年及可选一次性）与地区化价格，供用户选择 `planId`。  
通常无需登录（公开 Dio）。价格由后端按请求来源判定。

| 字段 | 类型 | 说明 |
|------|------|------|
| `serverTime` | string? | 服务端时间，客户端写缓存 meta |
| `plans[]` | object | 自动续费；`planId` 现认 `plus_monthly` / `plus_yearly` |
| `plans[].planId` | string | |
| `plans[].priceString` | string | 地区化续费价（含币种符号） |
| `plans[].hasFreeTrial` | bool? | |
| `plans[].trialDays` | int? | |
| `plans[].introOffer` | object? | 见下 |
| `plans[].introOffer.discountType` | `"percentage"` | 现仅认此值 |
| `plans[].introOffer.discountPercent` | number | 1~100；客户端推算优惠价串 |
| `plans[].introOffer.renewalPriceString` | string | 促销结束后续费价 |
| `plans[].introOffer.period` | string? | `day`/`week`/`month`/`year` |
| `plans[].introOffer.periodNumberOfUnits` | int? | 默认 1 |
| `plans[].introOffer.cycles` | int? | 默认 1 |
| `plans[].introOffer.isFreeTrial` | bool? | |
| `oneTimePlans[]` | object? | 可选；单项坏数据忽略 |
| `oneTimePlans[].planId` | string | 现仅认 `plus_yearly_one_time` |
| `oneTimePlans[].priceString` | string | |
| `oneTimePlans[].purchaseType` | `"one_time"` | |
| `oneTimePlans[].accessType` | `"fixed_term"` | |
| `oneTimePlans[].autoRenew` | `false` | |
| `oneTimePlans[].duration` | `{unit:"year",count:1}` | |

### 4.3 POST `/api/paddle/hosted-checkout`

**用途**：用户点购买——服务端创建 Paddle 托管结账，客户端打开 `checkoutUrl`；`Idempotency-Key` 防连点重复下单。  
需 **Bearer** + 头 `Idempotency-Key`（UUID）。

| 方向 | 字段 | 类型 | 说明 |
|------|------|------|------|
| body | `planId` | string | 与 plans / oneTimePlans 对应 |
| body | `locale` | string | BCP 47 language tag |
| 响应 | `attemptId` | string | 结账尝试 id |
| 响应 | `checkoutUrl` | string | 必须 https |

`409` + `code: already_entitled`：已有权益。

### 4.4 POST `/api/paddle/portal`

**用途**：已订阅用户管理订阅（取消/换卡等）——返回短期 Customer Portal URL，客户端打开浏览器。  
需 **Bearer**。

| 字段 | 类型 | 说明 |
|------|------|------|
| `portalUrl` | string | Customer Portal https URL |

### 4.5 Webhook（服务端对服务端）

**用途**：Paddle（及 RevenueCat 等）支付事件回调，服务端更新权益库。**不**由 App 直接调；App 只信 `/api/entitlements`。

---

## 5. 配置 / 目录 / 社区 / 网盘

### 5.1 GET `/api/v1/client/config`

**用途**：启动/刷新远程开关与地区上下文——控制云盘导入、AI 助手、商店 Web 支付兜底等显隐，以及云端转录上限。  
通常 **无需登录**。

| 方向 | 字段 | 类型 | 说明 |
|------|------|------|------|
| query | `platform` | string | 客户端平台名 |
| 响应 | `version` | int | 必填；当前认 `1` |
| 响应 | `ttlSeconds` | int? | 缓存 TTL，缺省 86400 |
| 响应 | `context.countryCode` | string? | 空/`unknown` → 客户端 null |
| 响应 | `context.platform` / `.channel` | string? | 回显，可空串 |
| 响应 | `features.cloudDriveImport.enabled` | bool | 网盘导入；默认 true |
| 响应 | `features.showStoreWebCheckoutFallback.enabled` | bool | 商店 Web 支付兜底；默认 false |
| 响应 | `features.aiChatAssistant.enabled` | bool | AI 助手；默认 true |
| 响应 | `limits.transcription.maxDurationSeconds` | int | 默认 1800 |
| 响应 | `limits.transcription.maxUploadBytes` | int | 默认 25MB |

### 5.2 GET `/api/v1/catalog`

**用途**：资源库「发现播客」——返回运营配置的推荐节目列表；客户端只读 `podcastCatalogs`，再引导用户订阅 feed。

| 字段 | 类型 | 说明 |
|------|------|------|
| `podcastCatalogs[]` | object | 客户端只消费此字段 |
| `podcastCatalogs[].id` | string | |
| `podcastCatalogs[].title` | string | 节目名 |
| `podcastCatalogs[].description` | string? | |
| `podcastCatalogs[].imageUrl` | string? | |
| `podcastCatalogs[].applePodcastUrl` | string | 订阅优先 |
| `podcastCatalogs[].rssUrl` | string | Apple 空时回退 |

### 5.3 社区合集

#### GET `/api/v2/collections?cursor?`

**用途**：社区首页分页列出公开合集（约 20 条/页），供浏览与进入详情。

| 字段 | 类型 | 说明 |
|------|------|------|
| `items[]` | object | 约 20/页 |
| `items[].id` / `name` | string | |
| `items[].description` / `coverUrl` / `authorNickname` | string? | |
| `items[].fileCount` | int | |
| `items[].publishedAt` | string | ISO-8601 |
| `items[].updatedAt` | string? | 缺省等同 publishedAt |
| `nextCursor` | string? | 无则结束 |

#### GET `/api/v2/collections/{id}?cursor?`

**用途**：打开某个合集——返回合集元信息 + 一页可学文件；继续翻页用 `cursor`。

| 字段 | 类型 | 说明 |
|------|------|------|
| `collection` | object | 同上目录条目形状 |
| `items[]` | object | 一页文件 |
| `items[].id` / `title` / `mediaUrl` | string | |
| `items[].description` | string? | |
| `items[].mediaType` | `audio`\|`video` | |
| `items[].durationSec` / `fileSizeBytes` | int? | |
| `items[].difficulty` | `A1`…`C2`? | |
| `items[].publishedAt` | string? | |
| `items[].sortOrder` | int | |
| `nextCursor` | string? | |

#### GET `/api/v2/collections/{id}/files/{fileId}`

**用途**：导入某集前拉取文件元数据 + 字幕；成功后可落成本地材料进入学习。

| 字段 | 类型 | 说明 |
|------|------|------|
| `file` | object | 同上一页文件条目 |
| `subtitle.sentences[]` | object | `text` / `startTime` / `endTime`（**秒**） |
| `subtitle.words[]` | object | `word` / `startTime` / `endTime`（**秒**）；可空列表 |

错误：`404` 不存在；字幕不可用 `422`。

### 5.4 百度网盘 OAuth（均 POST JSON）

客户端不直持百度机密；经自家后端完成授权，用于网盘导入音频。

#### POST `/api/v1/netdisk/baidu/oauth/session`

**用途**：开始网盘授权——创建会话，返回浏览器要打开的授权 URL 与轮询凭证。

| 方向 | 字段 | 类型 | 说明 |
|------|------|------|------|
| body | `platform` | string | `ios`/`android`/`macos`/`windows`/`linux` |
| body | `forceLogin` | bool? | |
| 响应 | `sessionId` | string | |
| 响应 | `pollToken` | string | 一次性轮询凭证 |
| 响应 | `authorizationUrl` | string | 浏览器授权 URL |
| 响应 | `expiresAt` | string | ISO-8601 UTC |
| 响应 | `pollIntervalSeconds` | int | ≥1 |

#### POST `.../session/status`

**用途**：用户授权过程中轮询——是否仍 pending、是否已拿到凭证、是否取消/失败。  
Body：`sessionId`, `pollToken`。

| 字段 | 类型 | 说明 |
|------|------|------|
| `status` | string | `pending`/`exchanging`/`completed`/`canceled`/`failed` |
| `credential` | object? | 仅 `completed` 必有：`accessToken`/`refreshToken`/`expiresAt`/`scope` |
| `error` | object? | `failed`/`canceled` 可选：`code`/`message` |

#### POST `.../session/acknowledge`

**用途**：客户端已安全收下凭证后告知后端，便于清理会话状态。  
Body：`sessionId`, `pollToken`；响应可空。

#### POST `.../refresh`

**用途**：`accessToken` 过期时用 `refreshToken` 换新凭证，继续列目录/下文件。  
Body：`refreshToken`；响应同 `credential` 四字段。

---

## 6. 版本检查（非 iOS）

### GET `{apiBase}/version.json`

**用途**：非 iOS 启动/设置检查更新——比较本地版本与 `latestVersion`/`minimumVersion`，驱动可选更新或强制升级弹窗（iOS 走 App Store Lookup，不经此文件）。  
可静态托管。客户端会带 `x-app-*`（仅此请求）。

| 字段 | 类型 | 说明 |
|------|------|------|
| `latestVersion` | string | **必填**；最新版 |
| `minimumVersion` | string | **必填**；低于则强制更新 |
| `releaseNotes` | map? | locale → 文案 |
| `downloadUrl` | map? | platform → url |
| `platforms.ios.minimumVersion` | string? | iOS 渠道覆盖 |
| `platforms.android.googlePlay.minimumVersion` | string? | |
| `platforms.android.googlePlay.storeUrl` | string? | |
| `platforms.android.googlePlay.fallbackUrl` | string? | |
| `platforms.android.apk.latestVersion` | string? | |
| `platforms.android.apk.minimumVersion` | string? | |
| `platforms.android.apk.downloadUrl` | string? | |

---

## 7. Go 实现建议顺序

```text
1. JWT 校验中间件 + 公共 header 读取
2. §2 转录四件套 + 对象存储预签名
3. §1 AI 流式（Ops NDJSON）+ 额度 402
4. §4 权益 + Paddle（或等价）+ webhook
5. §3 句聊（Text NDJSON）
6. §5 config / catalog / collections / 网盘
7. version.json
```

流式注意：响应头尽早写出并 flush；帧间僵死由客户端 30s idle 断开。

---

## 8. 对照源码

| 域 | 客户端 |
|----|--------|
| 句 AI | `lib/services/sentence_ai_api_client.dart` |
| 转录 | `lib/services/transcription_api_client.dart` |
| 句聊 | `lib/features/chatbot/services/chat_api_client.dart` |
| 权益/Paddle | `lib/features/subscription/services/` |
| 配置 | `lib/features/remote_config/` |
| 合集 | `lib/features/community_collections/data/community_collection_api.dart` |
| 网盘 OAuth | `lib/features/baidu_netdisk/data/baidu_oauth_api.dart` |
| Dio 公共 | `lib/services/backend_dio.dart` |

---

## 维护

客户端增删路径或字段时：同步本文件 + [core-services.md](./core-services.md) 对应节。  
流式对象顶层字段以各 `fromJson` **永不抛、缺省空** 的契约为准。
