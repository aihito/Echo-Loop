# Echo Loop 学习资料索引

> 面向想读懂本仓库的开发者。按阶段学，先跑通再深入。  
> 最后更新：2026-10-14

本目录只做**学习地图**：不重复粘贴长文，而是把仓库里已有文档、代码入口按阅读顺序串起来。

---

## 0. 建议学习顺序（总览）

| 阶段 | 目标 | 大约投入 |
|------|------|----------|
| [1. 产品与跑通](#1-产品与跑通) | 知道 App 做什么，本地能跑 | 0.5～1 天 |
| [1b. 术语小词典](#1b-术语小词典前端小白向) | 看懂 NDJSON / Dio / CDN 等黑话 | 随查 |
| [2. 工程约定](#2-工程约定) | 知道怎么改代码、怎么验收 | 0.5 天 |
| [3. 骨架：启动 / 路由 / 壳](#3-骨架启动--路由--壳) | 懂页面怎么挂、壳内壳外 | 1～2 天 |
| [3b. 业务模型](#3b-业务模型) | 知道领域对象有哪些、和 DB 关系 | 0.5 天 |
| [3c. 核心服务](#3c-核心服务) | 知道 `lib/services` 里有什么、干什么 | 0.5 天 |
| [3d. 后端 API 契约](#3d-后端-api-契约) | 自家 HTTP 路径、参数、流式协议（对接/重写后端） | 0.5 天 |
| [3e. 界面一览](#3e-界面一览libscreens) | `lib/screens` 各页职责、路由、Feature 页边界 | 0.5 天 |
| [4. 核心域：学习闭环](#4-核心域学习闭环) | 盲听 / 精听 / 跟读 / 复述 / 复习 | 3～5 天 |
| [5. 横切能力](#5-横切能力) | 音频引擎、词典、播客、订阅、AI | 按兴趣选学 |
| [6. 踩坑与深水区](#6-踩坑与深水区) | 读 ADR/踩坑，避免重复踩雷 | 持续 |

---

## 1. 产品与跑通

### 必读

| 资料 | 说明 |
|------|------|
| [README.md](../../README.md) | 产品定位、功能、方法论、给开发者的快速开始 |
| [PLAN.md](../../PLAN.md) | 当前里程碑、风险、架构约束精简版 |
| [TASKS.md](../../TASKS.md) | 近期做了什么、现在在忙什么（读「当前焦点」即可） |

### 本地运行

| 资料 | 说明 |
|------|------|
| README「给开发者 → 快速开始」 | `flutter pub get` / `build_runner` / `--dart-define-from-file` |
| [local-debug-windows-android.md](../local-debug-windows-android.md) | Windows 上 Android 调试（FVM、JDK、ABI、flavor 等） |

建议第一次先跑通一个平台（macOS / Android 模拟器 / Windows 任选），点开：资源库 → 导入或播客 → 学习页，建立产品心智模型。

---

## 1b. 术语小词典（前端小白向）

读业务模型 / 核心服务时，**NDJSON、Dio、CDN、Bearer、ASR…** 等词先查：

**[glossary.md](./glossary.md)**

按主题分组（网络、流式协议、登录订阅、音频、播客、Flutter 工程），用白话解释；不必一次读完，随查即可。

---

## 2. 工程约定

改代码前先建立「仓库规矩」心智，否则容易和现有风格打架。

| 资料 | 说明 |
|------|------|
| [CLAUDE.md](../../CLAUDE.md) | Claude Code 工作规范：分层、Riverpod、测试、收尾流程 |
| [AGENTS.md](../../AGENTS.md) | Codex/Agent 规范（与 CLAUDE 互补；注意勿改 CLAUDE 体系文件） |
| `analysis_options.yaml` | lint 规则 |
| `scripts/check.sh` | 发版/大改时的全量检查（日常改动用定向 analyze/test） |

**分层口诀（必记）：**

```text
Screen 组装页面 → Widget 纯展示
Provider/Notifier 改状态与业务
Repository 只管数据存取
Model = 业务数据；State = 界面运行态
```

单向数据流：UI 触发动作 → controller 更新 state → UI 按 state 渲染。

---

## 3. 骨架：启动 / 路由 / 壳

这是读业务前最该摸清的「房子结构」。

### 代码入口

| 路径 | 学什么 |
|------|--------|
| `lib/main.dart` | App 启动、ProviderScope、路由挂载 |
| `lib/router/app_router.dart` | `GoRouter`、全局 `redirect`、壳内/壳外 `GoRoute` |
| `lib/router/main_shell.dart` | `MainShell`：底栏 / 侧栏 + Tab 内容 |
| `lib/router/widgets/main_shell_navigation_rail.dart` | 桌面 `NavigationRail`（宽屏侧栏） |
| `lib/providers/startup_bootstrap_provider.dart` | 冷启动本地数据初始化 |

### 必懂概念（路由）

- **壳（MainShell）**：带主导航的外壳（资源库 / 学习 / 收藏 / 我的）。
- **壳内路由**：写在 `StatefulShellRoute` 的 branch 里 → 有底栏/侧栏。
- **壳外路由**：与 Shell 平级，常带 `parentNavigatorKey: rootNavigatorKey` → 全屏盖住壳。
- **嵌套子路由**：URL 带完整栈，避免 Android 重建后返回多退一层（见 CLAUDE.md §7.17）。

回归参考：`test/router/app_router_test.dart`。

---

## 3b. 业务模型

领域对象与**字段说明**见：

**[business-models.md](./business-models.md)**（按模块；含类型与业务含义）

建议先读 §1 材料、§2 学习进度、§3 收藏调度，再按需深入。注意「运行态」≠ 持久化实体。

---

## 3c. 核心服务

`lib/services/` 是非 UI 可复用能力（不全是外部 API）。速查见：

**[core-services.md](./core-services.md)**（按域分组）

- 每条有 `about` + **`does`**（具体做什么）
- 远端另有：`client` / `transport` / `auth` / `request` / `response` / `endpoints`
- 公共约定：Backend Dio header、两种 NDJSON、CDN 下载；Feature API 在 §4

优先精读：§0 公共约定 → SentenceAiApiClient → TranscriptionApiClient → MediaSession / Recording → CDN 下载。

---

## 3d. 后端 API 契约

若要**用 Go（或其它语言）实现/替换自家后端**，按客户端真实调用整理的路径与参数见：

**[backend-api.md](./backend-api.md)**

含：公共 Header、两种 NDJSON、句 AI / 转录 / 句聊 / 权益·Paddle / 配置·合集·网盘、`version.json`，以及建议实现顺序。术语不明时配合 [glossary.md](./glossary.md)。

---

## 3e. 界面一览（`lib/screens`）

摸清「房子结构」后，按页看主流程 UI：

**[screens.md](./screens.md)**

- 壳内四 Tab、材料/计划、四类练习播放器、讲解与复习、设置子页、开发者页
- Feature 内页面边界（登录、付费墙、播客、社区合集…）
- 导航鸟瞰 + 建议阅读顺序；注明 `PlayerScreen` 遗留未挂路由

读 §3 路由概念后再翻此表；深入某练习页时再进对应 `providers/`。

### 目录地图（lib/）

```text
lib/
├── main.dart           # 入口
├── router/             # 路由与壳
├── screens/            # 页面组装（偏壳内主流程页）→ 见 screens.md
├── widgets/            # 可复用 UI
├── providers/          # Riverpod（按功能域）
├── features/           # 按 feature 分包（播客、订阅、chatbot…）
├── services/           # 平台/网络/TTS/ASR 等服务
├── database/           # Drift 数据库
├── models/             # 业务模型
├── analytics/          # 埋点
└── l10n/               # ARB 国际化
```

---

## 4. 核心域：学习闭环

产品主链路：**导入音频 → 字幕 → 学习计划 → 各阶段练习 → 收藏/复习**。

### 4.1 建议阅读顺序

1. **材料与进度**  
   - `lib/providers/audio_library_provider.dart`  
   - `lib/providers/learning_plan_provider.dart`  
   - `lib/providers/learning_progress_provider.dart`  
   - `lib/screens/study_screen.dart` / `learning_plan_screen.dart`

2. **播放与任务页**（壳外全屏居多）  
   - 随心听：`media_playback_screen.dart` + `providers/media_playback/`  
   - 盲听：`blind_listen_player_screen.dart` + `providers/blind_flow/`  
   - 精听：`intensive_listen_player_screen.dart` + `providers/intensive_annotation/`  
   - 跟读：`listen_and_repeat_player_screen.dart` + `providers/listen_and_repeat/`  
   - 复述：`retell_player_screen.dart` + `providers/repeat_flow/`（及 retell 相关 provider）

3. **收藏与复习**  
   - 收藏页：`favorites_screen.dart`  
   - 句子/词汇生命周期：`favorite_*_lifecycle_provider.dart`  
   - 调度：`features/memory_scheduler/` + [memory-scheduler-infrastructure-plan.md](../memory-scheduler-infrastructure-plan.md)  
   - 闪卡：`features/scheduled_flashcard/` + [favorite-sentence-flashcard-review-plan.md](../favorite-sentence-flashcard-review-plan.md)

### 4.2 专题计划文档

| 文档 | 主题 |
|------|------|
| [memory-scheduler-infrastructure-plan.md](../memory-scheduler-infrastructure-plan.md) | 间隔复习调度基础设施 |
| [favorite-sentence-flashcard-review-plan.md](../favorite-sentence-flashcard-review-plan.md) | 收藏句闪卡复习 |
| [paragraph-retell-video-implementation-plan.md](../paragraph-retell-video-implementation-plan.md) | 段落复述与视频相关 |
| [video-support.md](../video-support.md) | 视频支持说明 |

---

## 5. 横切能力

按兴趣选学，不必一次读完。

| 能力 | 代码入口 | 文档 |
|------|----------|------|
| 播客订阅 / RSS | `lib/features/podcast/` | （解析器只认 RSS 2.0 + enclosure） |
| 社区合集 | `lib/features/community_collections/` | — |
| 认证登录 | `lib/features/auth/` | README 环境变量说明 |
| 订阅支付 | `lib/features/subscription/` | [subscription-setup.md](../subscription-setup.md)、[subscription-single-source-plan.md](../subscription-single-source-plan.md) |
| AI Chatbot | `lib/features/chatbot/` | [chatbot-implementation-plan.md](../chatbot-implementation-plan.md) |
| 词典面板 / 选区 | `lib/widgets/dictionary/`、`lib/widgets/selection/` | CLAUDE.md §7.25～7.28 |
| TTS | `lib/providers/tts/` | CLAUDE.md §7.18～7.24、ADR 相关 |
| 离线 ASR / 录音 | `lib/providers/speech/`、`asr_*` | PLAN 当前风险；CLAUDE.md §7.1、7.4 |
| 音频引擎 / 锁屏 | `lib/providers/audio_engine/`、`media_engine/` | CLAUDE.md §7.6～7.16 |
| 地区路由 API/CDN | `lib/features/user_region/`、`lib/config/` | README 给开发者、订阅文档 |
| iOS 发布 / Universal Links | — | [ios-release-publish.md](../ios-release-publish.md)、[ios-universal-links.md](../ios-universal-links.md)、[ios-app-store-checklist.md](../ios-app-store-checklist.md) |

---

## 6. 踩坑与深水区

| 资料 | 说明 |
|------|------|
| [CLAUDE.md §7 Troubleshooting](../../CLAUDE.md) | 精简踩坑清单（锁屏、TTS、选区、路由塌栈、i18n 回退等） |
| [docs/reference/claude-summary.md](../reference/claude-summary.md) | 规范摘要 |
| [docs/reference/claude-2026-07-12-full.md](../reference/claude-2026-07-12-full.md) | 长版参考（需要时再翻） |
| `docs/tasks-archive/` | 历史任务归档，查「某功能何时做成」 |
| `docs/plan-archive/` | 历史规划归档 |

读代码时：**先搜测试**。`test/` 下与功能同路径的 `*_test.dart` 往往比文档更能说明预期行为。

---

## 7. 推荐「第一周」打卡清单

- [ ] 按 README 跑起 App，走一遍导入 → 学习计划 → 任一练习页  
- [ ] 读完 PLAN.md「产品目标 / 架构约束」  
- [ ] 跟读 `app_router.dart`：标出 3 个壳内路由、3 个壳外全屏路由  
- [ ] 从 `StudyScreen` 点进一条材料，顺着 provider 找到「任务如何推进」  
- [ ] 跑一组小测试：`flutter test test/router/app_router_test.dart`  
- [ ] 改一条文案或加一条日志，走完 analyze + 相关 test（体验收尾流程）

---

## 8. 本目录约定

- 新的**学习向**笔记、读书笔记、架构草图：可继续放在 `docs/learning/`（例如 `notes-路由.md`）。业务模型增删时同步 [business-models.md](./business-models.md)；重要服务增删时同步 [core-services.md](./core-services.md)；API 路径/字段变更同步 [backend-api.md](./backend-api.md)；新黑话补进 [glossary.md](./glossary.md)。  
- **功能规格 / 实现计划**：仍放在 `docs/` 根下或对应 feature 文档，并在上面表格中挂链接。  
- **任务进度**：只写 `TASKS.md` / 归档，不在本目录重复记待办。

有新专题文档时，优先更新本 README 的表格，保持「一张地图」。
