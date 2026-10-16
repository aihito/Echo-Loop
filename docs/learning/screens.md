# 界面一览（`lib/screens` + 相关 Feature 页）

> 页面组装层速查：谁干什么、挂在哪条路由、和哪些域相关。  
> **完整挂载树 / 全路由 / widgets 目录穷尽**见 [ui-component-tree.md](./ui-component-tree.md)。
> **匹配规则与路径速查**见 [app-router.md](./app-router.md)。
> 源码为准；路由实现见 `lib/router/app_router.dart`。
> 最后更新：2026-10-14 · 入口：[学习地图](./README.md)

---

## 0. 怎么读

| 概念 | 含义 |
|------|------|
| **Screen** | 页面组装：读 provider、分发回调、拼子 Widget；复杂业务不堆在这里 |
| **壳内** | `MainShell` 底栏/侧栏可见（资源库 / 学习 / 收藏 / 设置） |
| **壳外全屏** | 盖住壳；学习任务播放器等多用嵌套子路由（防返回塌栈，CLAUDE §7.17） |
| **Navigator.push** | 设置下属子页等，未进 GoRouter 树，返回靠系统栈 |

**目录边界**

```text
lib/screens/           # 主流程页（库、学习、收藏、计划、各练习播放器、设置及子页…）
lib/features/*/screens # Feature 自管页（登录、付费墙、播客发现、社区合集、问卷…）
lib/widgets/           # 可复用组件（不是整页）
```

`collection_screen.dart` **不是独立路由页**，是 `LibraryScreen` 合集 Tab 的内容组件。

---

## 1. 导航鸟瞰

```text
MainShell
├── /collections          LibraryScreen（合集/音频）
│   ├── discover…         社区合集（features）
│   ├── podcast…          播客发现/预览（features）
│   └── :collectionId     CollectionDetailScreen
│         └── :audioId/
│               ├── plan                 LearningPlanScreen
│               ├── blind-listen         BlindListenPlayerScreen
│               ├── intensive-listen     IntensiveListenPlayerScreen
│               ├── listen-and-repeat    ListenAndRepeatPlayerScreen
│               ├── retell               RetellPlayerScreen
│               ├── review-difficult…    ReviewDifficultPracticeScreen
│               ├── （嵌套）sentence-detail / pdf-preview / media playback…
├── /study                StudyScreen
├── /favorites            FavoritesScreen
└── /settings             SettingsScreen
      └──（多为 MaterialPageRoute）提醒/学习/ASR/TTS/播放/词典/开发者工具…

壳外（节选）
├── /login … /account /paywall /onboarding-survey
├── /bookmark-review /favorite-vocabulary-review
├── /activity-calendar /review-statistics
└── /backup-restore
```

典型用户路径：

```text
资源库 → 合集详情 → 学习计划 → 盲听/精听/跟读/复述
学习 Tab → 任务卡 → 同上练习页
收藏 → 句子讲解 / 闪卡 / 词汇复习
设置 → 各能力子设置 / 备份 / 账号（Feature）
```

---

## 2. `lib/screens` 目录表

### 2.1 壳内主 Tab

| 文件 | 页面 | 路由 / 入口 | 做什么 |
|------|------|-------------|--------|
| `library_screen.dart` | 资源库 | `/collections` | 合集 ↔ 音频双视图；导入、发现入口 |
| `collection_screen.dart` | （合集列表 UI） | 被 Library 引用 | 创建/排序/钉住/删除合集；非独立路由 |
| `study_screen.dart` | 学习 | `/study` | 待复习、推荐、完成统计；进计划/练习 |
| `favorites_screen.dart` | 收藏 | `/favorites` | 收藏句（按音频）/ 词与意群；进讲解与复习 |
| `settings_screen.dart` | 设置 | `/settings` | 账号、订阅、学习与播放相关入口、备份、开发者 |

### 2.2 材料与计划

| 文件 | 页面 | 路由 / 入口 | 做什么 |
|------|------|-------------|--------|
| `collection_detail_screen.dart` | 合集详情 | `/collections/:collectionId` | 合集内音频列表、导入、进计划/随心听 |
| `learning_plan_screen.dart` | 学习计划 | `…/:audioId/plan` | 首次学习四步 + 复习轮次；自由练习；开各播放器 |
| `media_playback_screen.dart` | 随心听 | 嵌套 media 段 | 音/视频自由播、字幕列表、媒体会话 |

### 2.3 学习任务播放器（壳外嵌套）

| 文件 | 页面 | 路由段 | 做什么 |
|------|------|--------|--------|
| `blind_listen_player_screen.dart` | 盲听 | `blind-listen` | 分段/无字幕盲听；遍数与断点 |
| `intensive_listen_player_screen.dart` | 精听 | `intensive-listen` | 逐句遮盖精听；「听不懂」进详情 |
| `listen_and_repeat_player_screen.dart` | 跟读 | `listen-and-repeat` | 难句听后跟读、录音评分 |
| `retell_player_screen.dart` | 复述 | `retell` | 段落听→说；可走 AI 评估 |
| `review_difficult_practice_screen.dart` | 难句补练 | `review-difficult-practice` | 复习：盲听难句 + 可选跟读 |

### 2.4 讲解 / 导出 / 复习工具

| 文件 | 页面 | 路由 / 入口 | 做什么 |
|------|------|-------------|--------|
| `sentence_detail_screen.dart` | 句子讲解 | 嵌套 `sentence-detail` | 单句译/析/意群/播放；收藏切换 |
| `pdf_preview_screen.dart` | PDF 预览 | 嵌套 `pdf-preview` | 导出学习材料 PDF（预览/分享） |
| `bookmark_review_screen.dart` | 收藏句闪卡 | `/bookmark-review` | 极简闪卡复习收藏句 |
| `favorite_vocabulary_review_screen.dart` | 词汇复习 | `favorite-vocabulary-review` | 收藏词/意群复习 |
| `activity_calendar_screen.dart` | 活动日历 | `/activity-calendar` | 按日学习强度与明细 |
| `review_statistics_screen.dart` | 复习统计 | `review-statistics` | 收藏复习表现分层展示 |

### 2.5 设置子页（多从设置 `Navigator.push`）

| 文件 | 页面 | 做什么 |
|------|------|--------|
| `reminder_settings_screen.dart` | 提醒 | 收藏复习/音频复习本地通知 |
| `learning_settings_screen.dart` | 学习 | 如「自动跳过复述」 |
| `playback_settings_screen.dart` | 播放 | 跳过静音及阈值 |
| `asr_settings_screen.dart` | 语音识别 | 后端/离线模型（平台差异） |
| `tts_settings_screen.dart` | 语音合成 | 引擎、口音、Echo Loop 模型/音色 |
| `dictionary_settings_screen.dart` | 词典 | 默认源、启用/禁用网页源等 |
| `backup_restore_screen.dart` | 备份恢复 | 用户数据备份/恢复（亦有独立路由） |

### 2.6 开发者 / 诊断

| 文件 | 页面 | 做什么 |
|------|------|--------|
| `log_viewer_screen.dart` | 日志 | 应用内日志查看、分享 |
| `preferences_viewer_screen.dart` | 偏好查看 | SharedPreferences 排查 |
| `storage_browser_screen.dart` | 存储浏览 | App 目录文件占用排查 |
| `asr_test_screen.dart` | ASR 测试 | 平台/离线识别试验与指标 |

### 2.7 遗留注意

| 文件 | 说明 |
|------|------|
| `player_screen.dart` | 旧自由播放器形态；**当前路由未挂载**，主路径用 `MediaPlaybackScreen`。改播放勿默认改此文件，先确认是否仍被引用。 |

---

## 3. Feature 内页面（不在 `lib/screens`，但同属「界面」）

读主流程时会碰到；实现在 `lib/features/`。

| 域 | 代表页面 | 作用 |
|----|----------|------|
| auth | `login` / `email_sign_in` / `check_email` / `password_sign_in` / `account` | 登录与账号 |
| subscription | `paywall_screen`、`subscription_debug_screen` | 付费墙与订阅调试 |
| podcast | `podcast_discovery` / `podcast_preview` | 发现与预览订阅 |
| community_collections | `discover_collections` / `community_collection_detail` | 社区合集浏览与导入 |
| onboarding_survey | `onboarding_survey_screen` | 首启问卷 |
| chatbot | `chat_screen` / `chat_edit_screen` | 句聊（常从练习页入口进） |
| subtitle_editor | `SubtitleSimpleEditorScreen` | 字幕简易编辑（材料路由） |

---

## 4. 建议阅读顺序

1. **壳与 Tab**：`library_screen` → `study_screen` → `favorites_screen` → `settings_screen`  
2. **一条材料闭环**：`collection_detail` → `learning_plan` → 任选一个 `*_player_screen`  
3. **讲解与 AI UI**：`sentence_detail`（对照 [core-services.md](./core-services.md) 句 AI）  
4. **收藏复习**：`favorites` → `bookmark_review` / `favorite_vocabulary_review`  
5. **设置能力**：ASR / TTS / 词典设置页（对照 CLAUDE 踩坑 TTS/ASR 节）

配合：[business-models.md](./business-models.md)（进度/收藏模型）、路由回归 `test/router/app_router_test.dart`。

---

## 5. 维护

- 在 `lib/screens` **新增整页**或改路由挂载：更新本表对应行。  
- Feature 新增大入口页：补 §3，并在 [README.md](./README.md) 学习地图挂链接（若成主路径）。  
- 页面只改布局、不改职责：可不改本文。
