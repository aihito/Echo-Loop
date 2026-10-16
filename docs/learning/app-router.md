# Echo Loop 路由与匹配规则参考

> 面向查阅：go_router **怎么匹配**、项目里有哪些路径、常量怎么拼、redirect / extra / 嵌套约定。  
> 源码真相：`lib/router/app_router.dart`、`lib/features/community_collections/community_collection_routes.dart`。  
> 页面职责见 [screens.md](./screens.md)；运行时挂载树见 [ui-component-tree.md](./ui-component-tree.md)。  
> 最后更新：2026-10-16

---

## 0. 30 秒心智模型

```text
URL 字符串
  → GoRouter 按「路由树」从根往下匹配
  → 命中某条 GoRoute 的 builder → 画出对应 Screen
  → 若带 parentNavigatorKey: rootNavigatorKey → 全屏盖住底栏（壳外）
  → 否则留在 StatefulShellBranch 内 → 底栏/侧栏仍在（壳内）
```

导航 API：

| API | 作用 |
|-----|------|
| `context.push(path)` | 压栈前进（可返回） |
| `context.go(path)` | 替换到该 location（不保留中间栈语义，慎用） |
| `context.pop()` | 出栈 |
| `AppRoutes.pushNested(context, segment)` | 在**当前 matchedLocation** 后追加相对段（防 §7.17 塌栈） |

路径常量集中在 `AppRoutes`（及社区的 `CommunityCollectionRoutes`），业务代码应优先用这些方法，少手写字符串。

---

## 1. 匹配规则（本仓库实际用法）

### 1.1 静态段 vs 动态段

| 写法 | 含义 | 例子 |
|------|------|------|
| `'discover'` | 字面匹配这一段 | `/collections/discover` |
| `':collectionId'` | 匹配**任意一段**，并命名参数 | `/collections/abc` → `pathParameters['collectionId']='abc'` |
| `':audioId/plan'` | 两段：动态 + 静态 | `/collections/c1/a1/plan` |
| `'/audio/:audioId/plan'` | 绝对路径（顶层路由） | `/audio/a1/plan` |

动态段名字可以任意（`:id` / `:collectionId`），只要和 `state.pathParameters['…']` 的 key 一致。

### 1.2 嵌套路径 = 父 path + 子 path

子路由写的是**相对段**，完整 URL 由祖先拼出来：

```text
GoRoute(path: '/collections')
  └─ GoRoute(path: ':collectionId')
       └─ GoRoute(path: ':audioId/plan')

完整 URL = /collections/{collectionId}/{audioId}/plan
```

因此：

- `AppRoutes.collectionDetail(id)` → `'/collections/$id'`
- 能匹配到子路由 `path: ':collectionId'`，**不是**因为字符串里写了 `{id}` 魔法，而是「父 `/collections` + 子动态段」。

### 1.3 同级静态优先于动态（重要）

在 `/collections` 下，同级子路由大致是：

```text
pdf-preview          （静态）
discover             （静态）
podcast-subscribe    （静态）
:collectionId        （动态，吃掉「其余任意一段」）
```

所以：

| URL | 命中 |
|-----|------|
| `/collections/discover` | `discover` → 发现页 |
| `/collections/podcast-subscribe` | Podcast 搜索 |
| `/collections/<某个合集UUID>` | `:collectionId` → 合集详情 |

若把 `discover` 删掉只留 `:collectionId`，则 `discover` 会被当成某个合集 id。

### 1.4 壳内 vs 壳外（`parentNavigatorKey`）

| 标记 | 条件 | 表现 |
|------|------|------|
| 〔shell〕 | 写在 `StatefulShellBranch` 里，且**不**挂 `rootNavigatorKey` | 底栏/侧栏仍可见 |
| 〔rootNav〕 | `parentNavigatorKey: rootNavigatorKey` | 全屏盖住壳，无 Tab |

合集详情本身是 〔shell〕；其下的 `plan` / 播放器等多为 〔rootNav〕。

### 1.5 Query 参数

目前主要用在学习计划：

- `?autoStart=true` → `state.uri.queryParameters['autoStart'] == 'true'`

路径匹配不依赖 query；query 只影响 builder 行为。

### 1.6 `extra`（不可进 URL）

部分页还依赖 `state.extra` 传对象（`AudioItem`、`SentenceDetailArgs`、`MediaLearningStartup`、`PodcastPreviewArg` 等）。

- **Android Activity 重建**等场景可能按 URI 重解析，`extra` 丢失。
- 依赖 extra 的子页：丢失时走 `_RestoredRoutePopper`（首帧 `pop` 回入口），避免白屏/崩溃。
- 例外：`/audio/:audioId/player` 会尝试从 `audioLibraryProvider` 按 id 恢复材料。

### 1.7 `AppRoutes.pushNested`

```dart
AppRoutes.pushNested(context, AppRoutes.sentenceDetailSegment, extra: args);
```

本质：`push('${matchedLocation}/sentence-detail')`。

要求：目标段必须已声明为**当前路由的子路由**，否则 go_router 立刻报 no route（把静默塌栈变成可见错误）。详见 `CLAUDE.md` §7.17。

---

## 2. 全局 redirect

定义在 `GoRouter(redirect: …)`（`app_router.dart`）：

| 条件 | 行为 |
|------|------|
| 已登录，且当前是登录相关路径（`/login`、`/login/email`、`/login/check-email`、`/login/password`） | → `/settings` |
| 未登录，且访问 `/account` | → `/settings` |
| 当前已是 `/onboarding/survey` | 不 redirect（防死循环） |
| `shouldShowSurveyProvider == true`（首启问卷未完成） | → `/onboarding/survey` |
| path 为 `/` | → `/study` |
| 其它 | `null`（不拦截） |

`initialLocation`：`/study`。

---

## 3. 兼容用 redirect（旧链接）

| 旧 URL | 新目标 |
|--------|--------|
| `/discover` | `/collections/discover` |
| `/discover/:remoteId` | `/collections/discover/:remoteId` |
| `/podcast-subscribe` | `/collections/podcast-subscribe` |
| `/podcast-subscribe/preview` | `/collections/podcast-subscribe/preview` |

实现：顶层 `GoRoute` 只做 `redirect`，不再挂业务 Screen。

---

## 4. 完整路由树（路径 → Screen）

约定：

- 〔shell〕 / 〔rootNav〕 同上。
- `:name` 表示 path 参数。

### 4.1 壳：StatefulShellRoute（四 Tab）

#### Branch 0 — 资源库 `/collections`

| 完整路径 | Screen | 层 |
|----------|--------|----|
| `/collections` | `LibraryScreen` | 〔shell〕 |
| `/collections/pdf-preview` | `PdfPreviewScreen` | 〔rootNav〕需 `extra: AudioItem` |
| `/collections/discover` | `DiscoverCommunityCollectionsScreen` | 〔shell〕 |
| `/collections/discover/:remoteId` | `CommunityCollectionDetailScreen` | 〔shell〕 |
| `/collections/podcast-subscribe` | `PodcastDiscoveryScreen` | 〔shell〕 |
| `/collections/podcast-subscribe/preview` | `PodcastPreviewScreen` | 〔shell〕需 `extra: PodcastPreviewArg` |
| `/collections/:collectionId` | `CollectionDetailScreen` | 〔shell〕 |
| `/collections/:collectionId/pdf-preview` | `PdfPreviewScreen` | 〔rootNav〕 |
| `/collections/:collectionId/:audioId/plan` | `LearningPlanScreen` | 〔rootNav〕可选 `?autoStart=true` |
| `/collections/:collectionId/:audioId/plan/pdf-preview` | `PdfPreviewScreen` | 〔rootNav〕 |
| `/collections/:collectionId/:audioId/player` | `MediaPlaybackScreen`（经 `_AudioPlayerRoute`） | 〔rootNav〕 |
| `/collections/:collectionId/:audioId/player/sentence-detail` | `SentenceDetailScreen` | 〔rootNav〕需 `SentenceDetailArgs` |
| `/collections/:collectionId/:audioId/media-player` | `MediaPlaybackScreen` | 〔rootNav〕需 `extra: AudioItem` |
| `/collections/:collectionId/:audioId/media-player/sentence-detail` | `SentenceDetailScreen` | 〔rootNav〕 |
| `/collections/:collectionId/:audioId/blind-listen` | `BlindListenPlayerScreen` | 〔rootNav〕 |
| `/collections/:collectionId/:audioId/blind-listen/sentence-detail` | `SentenceDetailScreen` | 〔rootNav〕 |
| `/collections/:collectionId/:audioId/intensive-listen` | `IntensiveListenPlayerScreen` | 〔rootNav〕 |
| `/collections/:collectionId/:audioId/listen-and-repeat` | `ListenAndRepeatPlayerScreen` | 〔rootNav〕 |
| `/collections/:collectionId/:audioId/retell` | `RetellPlayerScreen` | 〔rootNav〕 |
| `/collections/:collectionId/:audioId/retell/sentence-detail` | `SentenceDetailScreen` | 〔rootNav〕 |
| `/collections/:collectionId/:audioId/review-difficult-practice` | `ReviewDifficultPracticeScreen` | 〔rootNav〕 |

#### Branch 1 — 学习

| 完整路径 | Screen | 层 |
|----------|--------|----|
| `/study` | `StudyScreen` | 〔shell〕 |

#### Branch 2 — 收藏

| 完整路径 | Screen | 层 |
|----------|--------|----|
| `/favorites` | `FavoritesScreen` | 〔shell〕 |
| `/favorites/sentence-detail` | `SentenceDetailScreen` | 〔rootNav〕 |

#### Branch 3 — 我的

| 完整路径 | Screen | 层 |
|----------|--------|----|
| `/settings` | `SettingsScreen` | 〔shell〕 |

设置里大量子页用 `Navigator.push`，**不在** GoRouter 树（见 [screens.md](./screens.md) / [ui-component-tree.md](./ui-component-tree.md)）。

### 4.2 壳外全屏（与 Shell 平级）

| 完整路径 | Screen | 备注 |
|----------|--------|------|
| `/backup-restore` | `BackupRestoreScreen` | |
| `/onboarding/survey` | `OnboardingSurveyScreen` | 〔rootNav〕 |
| `/login` | `LoginScreen` | 〔rootNav〕 |
| `/login/email` | `EmailSignInScreen` | `extra` 可为初始 email `String` |
| `/login/check-email` | `CheckEmailScreen` | `extra` email |
| `/login/password` | `PasswordSignInScreen` | 审核员隐藏入口 |
| `/account` | `AccountScreen` | 〔rootNav〕；未登录会被 redirect |
| `/paywall` | `PaywallScreen` | 〔rootNav〕 |
| `/bookmark-review` | `BookmarkReviewScreen` | 〔rootNav〕 |
| `/favorite-vocabulary-review` | `FavoriteVocabularyReviewScreen` | 〔rootNav〕 |
| `/activity-calendar` | `ActivityCalendarScreen` | 〔rootNav〕 |
| `/review-statistics` | `ReviewStatisticsScreen` | 〔rootNav〕 |

### 4.3 独立音频 `/audio/...`（无合集）

与合集内学习页平行的一套，`collectionId` 在 Screen 里为 `null`：

| 完整路径 | Screen |
|----------|--------|
| `/audio/:audioId/plan` | `LearningPlanScreen` |
| `/audio/:audioId/plan/pdf-preview` | `PdfPreviewScreen` |
| `/audio/:audioId/player` | `MediaPlaybackScreen`（可从库恢复） |
| `/audio/:audioId/player/sentence-detail` | `SentenceDetailScreen` |
| `/audio/:audioId/media-player` | `MediaPlaybackScreen` |
| `/audio/:audioId/media-player/sentence-detail` | `SentenceDetailScreen` |
| `/audio/:audioId/subtitles/edit` | `SubtitleSimpleEditorScreen`（**必须** `extra: AudioItem`，否则抛错） |
| `/audio/:audioId/blind-listen` (+ `/sentence-detail`) | `BlindListenPlayerScreen` |
| `/audio/:audioId/intensive-listen` | `IntensiveListenPlayerScreen` |
| `/audio/:audioId/listen-and-repeat` | `ListenAndRepeatPlayerScreen` |
| `/audio/:audioId/retell` (+ `/sentence-detail`) | `RetellPlayerScreen` |
| `/audio/:audioId/review-difficult-practice` | `ReviewDifficultPracticeScreen` |

---

## 5. `AppRoutes` / `CommunityCollectionRoutes` 速查

### 5.1 常量路径

| 常量 | 值 |
|------|-----|
| `AppRoutes.collections` | `/collections` |
| `AppRoutes.study` | `/study` |
| `AppRoutes.favorites` | `/favorites` |
| `AppRoutes.settings` | `/settings` |
| `AppRoutes.discoverResources` | `/collections/discover` |
| `AppRoutes.podcastSubscribe` | `/collections/podcast-subscribe` |
| `AppRoutes.legacyPodcastSubscribe` | `/podcast-subscribe` |
| `CommunityCollectionRoutes.legacyDiscover` | `/discover` |
| `AppRoutes.login` / `emailSignIn` / `checkEmail` / `passwordSignIn` | `/login`… |
| `AppRoutes.account` | `/account` |
| `AppRoutes.paywall` | `/paywall` |
| `AppRoutes.bookmarkReview` | `/bookmark-review` |
| `AppRoutes.favoriteVocabularyReview` | `/favorite-vocabulary-review` |
| `AppRoutes.backupRestore` | `/backup-restore` |
| `AppRoutes.activityCalendar` | `/activity-calendar` |
| `AppRoutes.reviewStatistics` | `/review-statistics` |
| `AppRoutes.onboardingSurvey` | `/onboarding/survey` |
| `AppRoutes.sentenceDetailSegment` | `sentence-detail`（相对段） |
| `AppRoutes.pdfPreviewSegment` | `pdf-preview`（相对段） |
| `AppRoutes.mediaPlayerSegment` | `media-player`（相对段） |
| `AppRoutes.podcastSubscribeSegment` | `podcast-subscribe` |
| `AppRoutes.podcastPreviewSegment` | `preview` |

### 5.2 构建方法（合集内）

| 方法 | 结果示例 |
|------|----------|
| `collectionDetail(c)` | `/collections/c` |
| `discoverCollection(remoteId)` | `/collections/discover/remoteId` |
| `learningPlan(c, a, autoStart:…)` | `/collections/c/a/plan[?autoStart=true]` |
| `player(c, a)` | `/collections/c/a/player` |
| `mediaPlayer(c, a)` | `/collections/c/a/media-player` |
| `blindListenPlayer(c, a)` | `/collections/c/a/blind-listen` |
| `intensiveListenPlayer(c, a)` | `/collections/c/a/intensive-listen` |
| `listenAndRepeatPlayer(c, a)` | `/collections/c/a/listen-and-repeat` |
| `retellPlayer(c, a)` | `/collections/c/a/retell` |
| `reviewDifficultPractice(c, a)` | `/collections/c/a/review-difficult-practice` |

`collectionId == null` 时，多数播放器方法改走 `/audio/:audioId/...` 变体（见源码）。

### 5.3 构建方法（独立音频）

| 方法 | 结果 |
|------|------|
| `audioLearningPlan(a)` | `/audio/a/plan` |
| `audioPlayer(a)` | `/audio/a/player` |
| `subtitleEditor(a)` | `/audio/a/subtitles/edit` |

---

## 6. 典型用户路径（对照匹配）

### 6.1 点合集进详情再进计划

```text
LibraryScreen 〔/collections〕
  → push AppRoutes.collectionDetail(id)
  → 匹配 :collectionId → CollectionDetailScreen
  → push AppRoutes.learningPlan(c, a)
  → 匹配 :audioId/plan → LearningPlanScreen 〔rootNav〕
```

### 6.2 发现资源

```text
DiscoverEntryBanner
  → push /collections/discover
  → DiscoverCommunityCollectionsScreen
  → push /collections/discover/:remoteId
  → CommunityCollectionDetailScreen
```

### 6.3 句子详情（嵌套）

```text
当前已在 …/blind-listen（或 favorites / player 等已声明子路由的页）
  → AppRoutes.pushNested(context, 'sentence-detail', extra: SentenceDetailArgs)
  → URL 变成 …/blind-listen/sentence-detail
  → SentenceDetailScreen 〔rootNav〕
```

---

## 7. 相关文件与回归

| 文件 | 职责 |
|------|------|
| `lib/router/app_router.dart` | GoRouter、AppRoutes、redirect、路由树 |
| `lib/router/main_shell.dart` | Tab 壳、启动时加载合集等 |
| `lib/features/community_collections/community_collection_routes.dart` | 发现资源路径常量 |
| `test/router/app_router_test.dart` | 嵌套路由 / 旧链 redirect / 塌栈相关回归 |

改路由时建议：

1. 同步改 `AppRoutes`（或 Community 常量）与 `GoRoute` 声明。  
2. 全屏子页优先**嵌套**在入口页下，并用 `pushNested`。  
3. 依赖 `extra` 的页要能接受丢失（`_RestoredRoutePopper` 或可从 id 恢复）。  
4. 跑 `flutter test test/router/app_router_test.dart`。  
5. 大改后更新本文与 [ui-component-tree.md](./ui-component-tree.md) §2。

---

## 8. 和「非 GoRouter」导航的边界

以下**不在**本文路由表内，但会出现在产品里：

- 设置页多数子页：`Navigator.push` + `MaterialPageRoute`
- Dialog / BottomSheet / 各类 Sheet：Modal，不改 URL
- 通知点击、深链：另见 `notification_tap_router_bridge` / `app_deep_link_router`（最终多半仍 `go`/`push` 到上表路径）

读 UI 组装时再查 [ui-component-tree.md](./ui-component-tree.md)。
