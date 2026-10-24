# Dart「异步」运行逻辑（心智模型）

> 用**简化结构**理解 `async` / `await` / `Future` 怎么跑。  
> **不是** Kotlin 协程实现拷贝，也不等价于 Dart VM 源码；只保留方便读业务代码的核心。  
> 结合本仓库：`await dao.getAllActive()`、`addPostFrameCallback`、Riverpod 写 `state`。  
> 最后更新：2026-10-24（补充「异步任务一般怎么执行」完整流程）

---

## 0. 先纠正一个叫法

Dart **没有**官方名叫「协程」的运行时原语。

| 你可能熟悉的 | Dart 里对应什么 |
|--------------|-----------------|
| Lua `coroutine` / libcopp task | `async` 函数（编译成**无栈状态机**）+ `await` |
| `yield` 等某个结果 | `await someFuture` |
| 外部 `resume` | Future **complete** 后由**事件循环**调度续体 |
| Job / Deferred | `Future` |
| 调度器 | **事件循环**（event loop）+ microtask / event 队列 |

下面说的「挂起 / 恢复」，语义接近协程；机制是：**状态机断点 + Future 完成后入队 resume**，不是换栈。

若你熟 Lua / libcopp，可先读 [§7](#7-用-lua--libcopp-术语对照) 再回头看总图。  
想先建立「任务怎么跑完」的主线，直接读 [§3](#3-异步任务一般怎么执行完整流程)。

---

## 1. 一张总图

```text
┌─────────────────────────────────────────────┐
│              主 Isolate（单线程）              │
│                                             │
│   正在执行的一段同步 Dart 代码                   │
│         │                                   │
│         │ 碰到 await Future                  │
│         ▼                                   │
│   当前函数「挂起」，把「后续代码」登记成回调        │
│         │                                   │
│         ▼                                   │
│   ┌─────────────┐   ┌─────────────────────┐ │
│   │ microtask 队列│   │ event 队列           │ │
│   │（更优先）     │   │ IO完成/定时器/UI事件… │ │
│   └─────────────┘   └─────────────────────┘ │
│         ▲                     ▲             │
│         └──────── 事件循环 ────┘             │
│              反复取任务执行                    │
└─────────────────────────────────────────────┘
```

原则：

1. **同一时刻只跑一段同步代码**（主 isolate）  
2. 异步结果靠「任务入队 → 循环稍后执行」回来  
3. `await` = 登记续体 + 让出线程，不是开新线程  

---

## 2. 核心数据结构（简化版）

只要记住四个东西：

### 2.1 `Future`（一张「将来会好的收据」）

```text
Future {
  状态: pending | completed | error
  结果: value 或 error
  等待者: [回调1, 回调2, ...]   // await / .then 登记的续体
}
```

- 查库、网络返回 → 把状态改成 completed，**把等待者丢进队列**  
- `await f` → 若还没好：把「await 后面的代码」挂到等待者上，然后返回事件循环  

### 2.1b 异步任务完成时，「通知」到底是什么（重点）

没有魔法广播，也没有你手写的 `resume(co)`。  
**通知 = Future 完成时，把它上面挂着的「续体回调」丢进事件循环队列；循环稍后执行这些回调 = 恢复挂起的 async 函数。**

用 Lua / libcopp 说：

```text
await 时：
  把「从下一行继续」登记到 Future.等待者
  然后 yield（让出）

任务完成时（通知）：
  Future.complete(结果)
  for 每个等待者:
      排进 microtask/event 队列   // 预约 resume，此刻还不跑
  （当前同步代码若还在跑，先跑完）

事件循环稍后：
  取出该回调并执行              // 真正的 resume(co, 结果)
  → await 表达式得到「结果」
  → async 函数从断点继续
```

分三步记：

| 步骤 | 谁做 | 像什么 |
|------|------|--------|
| ① 登记 | `await` / `.then` | `co` 把自己挂到 Future 的等待者列表 |
| ② 完成（通知发生的瞬间） | IO/定时器/业务 `complete` | 改 Future 状态，**把等待者入队**（还没执行业务续体） |
| ③ 恢复 | 事件循环取队列 | `resume(co, value)`，跑 `await` 后面的代码 |

所以：

- **「通知完毕」≠ 立刻同步跑完 `await` 后面所有逻辑**  
- **「通知」= complete + 入队；真正接着跑是循环下一次（或紧接着的 microtask）**  
- 多个地方 `await` 同一个 Future：等待者列表里多个回调，完成时**都会被入队**（各自 resume）

极简伪代码：

```text
function Future.complete(self, value):
  self.状态 = completed
  self.结果 = value
  for cb in self.等待者:
    队列.push(() => cb(value))   // 通知：预约 resume
  self.等待者.clear()

// 事件循环
cb = 队列.pop()
cb()   // 这里才真正回到 await 之后
```

对照查库：`dao.getAllActive()` 的 Future 在 SQL 结果就绪时走上面的 `complete`；  
你在 `loadLibrary` 里 `await` 时挂上的续体，被入队后执行，于是继续 `state = copyWith(...)`。  
**没有单独的「协程完成监听器 API」——监听器就是 Future 的等待者列表。**

### 2.2 两个队列

| 队列 | 典型来源 | 优先级 |
|------|----------|--------|
| **microtask** | `scheduleMicrotask`、`Future.then` 里很多续体 | 更高：先清空再处理 event |
| **event** | 定时器、文件/DB/网络完成、用户点击、一帧结束 | 较低：每次处理一个 event |

（真实实现更细，理解「两档优先级」即可。）

### 2.3 事件循环（伪代码）

```text
loop:
  while microtask 非空:
      取出一个 → 执行

  if event 非空:
      取出一个 → 执行
  else:
      等待下一次外部事件
```

### 2.4 `async` 函数（编译器帮你拆成状态机）

你写：

```dart
Future<void> loadLibrary() async {
  state = state.copyWith(isLoading: true);
  final dbItems = await dao.getAllActive();  // 断点 A
  state = state.copyWith(audioItems: map(dbItems)); // 断点 A 之后
}
```

心智上等价于：

```text
调用 loadLibrary()
  → 立刻返回一个 Future（给调用方 await）
  → 开始跑函数体
  → 跑到 await getAllActive()：
        若 Future 未完成：
          保存「从断点 A 继续」为回调
          本轮同步执行结束，回到事件循环
  → DB 完成后：回调入队
  → 循环跑到该回调：从断点 A 继续，赋值 state …
```

---

## 3. 异步任务一般怎么执行（完整流程）

本节讲**通用路径**：一个异步任务从「被调用」到「调用方拿到结果」怎么走。  
§4 再用本仓库查库例子对照同一条链路。

### 3.1 先约定「异步任务」指什么

在 Dart / Flutter 业务里，通常指下面之一（机制相同，都是 Future）：

| 形态 | 例子 |
|------|------|
| `async` 函数 | `Future<void> loadLibrary() async { ... }` |
| API 直接返回的 Future | `dao.getAllActive()`、`http.get(...)` |
| 你自己造的 Future | `Completer`、`Future.delayed`、`Future(() { ... })` |

调用方用 `await` / `.then` 等结果；**真正干活的可能是**：本 isolate 稍后跑的代码、定时器、平台通道、插件里的 IO 线程等——对读业务代码而言可先当黑盒，只盯 Future 的 pending → completed。

### 3.2 总流程（九步）

```text
① 调用方发起
   foo() 或 await foo()
        │
        ▼
② 创建 / 取得一个 Future（多数立刻返回给调用方，此时多为 pending）
        │
        ▼
③ 任务「启动段」同步执行
   · async 函数：从函数开头跑到第一个未完成的 await
   · 非 async API：同步发起 IO / 注册回调后立刻返回 Future
        │
        ├─ 若启动段里 Future 已经 completed（少见，如 Future.value）
        │     → 续体仍会入队（通常 microtask），不会在同一同步栈里「假同步跑完整个后续」
        │
        ▼
④ 碰到未完成的 await（或 .then）
   · 把「await 后面的代码」登记为 Future 的等待者（续体）
   · 当前 async 函数挂起，让出主 isolate
        │
        ▼
⑤ 回到事件循环
   · 可处理：UI 帧、点击、其它已入队的 microtask / event
   · 底层 IO / 定时器等在「别处」推进（黑盒）
        │
        ▼
⑥ 结果就绪 → Future.complete(value) 或 completeError(e)
   · 改状态；把所有等待者回调推进队列（通知 = 入队，见 §2.1b）
        │
        ▼
⑦ 事件循环取出续体并执行（resume）
   · await 表达式得到 value（或抛错进入 catch）
   · 从断点继续跑同步代码，直到下一个 await 或函数结束
        │
        ├─ 若又遇到未完成的 await → 回到 ④（可多轮）
        │
        ▼
⑧ async 函数跑完
   · 把它「一开始返回给调用方的那个 Future」也 complete
   · 于是外层 await foo() 的续体同样被入队、稍后 resume
        │
        ▼
⑨ 调用链上所有相关 await 依次恢复；若无人 await 且出错 → 未处理异步错误风险
```

串成一句：

**发起 → 拿 Future → 同步跑到 await → 挂起让出 → 循环干别的 → complete 入队 → 循环 resume → 可能再 await → 函数结束 complete 外层 Future。**

### 3.3 时序示意（单层 await）

```text
时间 →

调用方 / async 体          事件循环              底层工作(黑盒)
─────────────────         ──────────            ────────────
开始跑 sync 段
  await f  (f pending)
  登记续体，挂起  ──────►  继续跑队列
                          画帧 / 点按 / …
                                              IO 完成
                          ◄── complete 入队 ──
                          执行续体 resume
从 await 后继续
函数结束 → 完成「自己的」Future
（若外层在 await 我）
                          再入队外层续体 …
```

### 3.4 三种常见启动方式（细节不同，骨架相同）

**A. `async` 函数（本仓库最常见）**

```dart
Future<int> load() async {
  final a = await step1(); // 可能挂起
  final b = await step2(); // 再挂起
  return a + b;            // 结束 → 完成 load() 返回的那个 Future
}
```

- 调用 `load()`：**马上**得到 `Future<int>`，函数体开始跑。  
- 每个 `await`：未完成就挂起一轮；完成则 resume 后继续。  
- `return` / 函数结束：把结果写进「调用 `load()` 时拿到的那个 Future」。

**B. 已经封装好的异步 API**

```dart
final rows = await dao.getAllActive();
```

- `getAllActive()` 内部创建 pending Future、发起查库、返回 Future。  
- 你的 `async` 函数在 `await` 处挂起；查库完成后走 §3.2 ⑥⑦。

**C. 自己用 Completer 桥接回调**

```dart
final c = Completer<String>();
somePlugin.start(onDone: (s) => c.complete(s));
final s = await c.future;
```

- 插件回调里 `complete` = 流程 ⑥；`await c.future` = ④⑦。  
- 适合「只有回调 API、没有 Future」的平台接口。

### 3.5 执行过程中谁在跑、谁在等

| 阶段 | 主 isolate 在做什么 | 该任务 |
|------|---------------------|--------|
| ③ 启动段 | 同步执行这段 Dart | 进行中（尚未挂起） |
| ⑤ 挂起后 | 跑**别的**队列任务 / 帧 | 等待；底层可能在干活 |
| ⑦ resume 后 | 又同步执行续体 | 进行中 |
| ⑧ 已完成 | 无关 | Future 已 completed，再 await 会很快通过入队恢复 |

要点：**挂起 ≠ 线程睡眠死等**；主 isolate 去忙别的事。也**没有**因为 `await` 就自动开一条业务线程。

### 3.6 错误怎么走

```text
底层失败 / throw
  → Future.completeError(e)
  → 等待者入队（带 error）
  → resume 时在 await 处抛出
  → 被 surrounding try/catch 接住，或沿 async 函数传出
  → 该 async 函数返回的 Future 以 error 完成
  → 外层 await 同样收到错误
```

若整条链都没有 `await` / `.catchError` / `runZonedGuarded`，可能变成**未处理的异步错误**（调试期常见红屏 / 日志）。

### 3.7 几个容易误解的点

1. **`async` 不表示「函数体全部延后」**  
   从开头到第一个未完成 `await` 之间是**同步**执行的。

2. **`await` 已完成的 Future**  
   仍不会把后续代码塞进当前同步调用栈末尾「假同步跑完」；续体一般作为 microtask 尽快跑，但中间可能插入别的 microtask。

3. **多层 `await`**  
   不是一次挂起到底；每层 await 都是「挂起 → 完成 → resume → 再往下」的一轮，可重复 §3.2 ④–⑦。

4. **`unawaited(foo())`**  
   仍然走完整流程，只是**当前函数不登记等待者**；`foo` 的错误不会传到当前函数，要自己在 `foo` 内处理。

5. **和 UI 刷新**  
   `await` 恢复后你写的 `state = ...` 是同步的；UI 是否 rebuild 取决于 Riverpod/setState 等，那是另一条通知链（见 §4 末表）。

### 3.8 脑内检查清单（读代码时）

对任意一处异步调用，按序问：

1. **谁创建了 Future？**（async 函数 / 插件 / Completer）  
2. **启动段同步做了什么？**（有没有在 await 前改 state / 发起请求）  
3. **await 等的是哪一个 Future？**  
4. **完成从哪来？**（IO、定时器、别的 complete）  
5. **resume 之后改了什么可观察状态？**（provider、导航、缓存）  
6. **错误谁接？**（try/catch、`.catchError`、有没有 unawaited）

---

## 4. 标准流程（对照 DAO）

以本仓库为例，把 §3 的九步落在查库上：

```dart
final dbItems = await dao.getAllActive();
```

```text
①② loadLibrary() 被调用，立刻返回 Future；函数体开始跑
③ 例如先 state = isLoading（同步）
④ 跑到 await dao.getAllActive()：
     getAllActive() / Drift .get() 返回 pending 的 Future
     登记续体，loadLibrary 挂起
     （外层若 await loadLibrary()，也可能已挂起）
⑤ 事件循环继续：绘制帧、点击、其它 Future…
   底层发起异步查库（可能在后台 isolate / 平台线程，细节可黑盒）

⑥ 查库完成 → Future.complete(行列表)     ← 通知：状态变更 + 续体入队
⑦ 事件循环执行该回调（= resume）：
     dbItems = 结果
     state = copyWith(audioItems: ...)
⑧ loadLibrary 结束 → 完成「调用 loadLibrary() 时」那个 Future
⑨ 外层 await loadLibrary() 的续体再入队、resume；
   Riverpod 因 state= 通知 UI watch → 安排 rebuild
```

两层「通知」别混：

| 层级 | 含义 |
|------|------|
| Future → async 函数 | complete + 入队 + 循环 resume（§2.1b / §3） |
| Notifier `state=` → Widget | Riverpod 订阅表，和 Future 无关 |

**异步任务完成通知 async 函数**：只有第一层。

---

## 5. 和 Flutter 帧的关系

Flutter 在事件循环之上还有**帧**：

```text
vsync 到了（一个 event）
  → build / layout / paint
  → 执行本帧登记的 addPostFrameCallback（帧后再入队/执行）
```

所以：

- `await dao...`：等 **IO Future**  
- `addPostFrameCallback`：等 **这一帧画完**  

都是「入队稍后执行」，只是事件来源不同。

---

## 6. 和「真多线程」的边界

| 做法 | 是否并行跑 Dart 业务逻辑 |
|------|--------------------------|
| `async`/`await` | 否，仍是协作式单线程穿插 |
| `Future` 所包装的 IO | 等待期间别人的同步代码可跑 |
| `Isolate` / `compute` | 是，另一个 isolate 真并行（另有端口通信） |

**长时间占满 CPU 的同步循环**会卡住事件循环 → 掉帧、点击无响应。重计算应拆 `await`、下沉 isolate，或缩短同步段。

---

## 7. 用 Lua / libcopp 术语对照

### 7.1 一张映射表

| Lua / libcopp | Dart | 说明 |
|---------------|------|------|
| `coroutine.create(f)` / 创建 task | 调用 `foo() async { ... }` | 立刻得到一个 `Future`（像「task 句柄」），函数体开始跑 |
| `yield(x)` 主动让出 | `await future` | 挂起当前 async 状态机；`future` 的结果 ≈ resume 时传回的值 |
| `coroutine.resume(co, …)` | Future **complete** → 事件循环执行续体 | **你很少手写 resume**；IO/定时器完成时运行时帮你 resume |
| 协作式、同线程 | 主 isolate 协作式 | 一样：同步代码跑完一段才会切换 |
| **有栈协程**（Lua C、libcopp 常见） | **无栈**（状态机） | 关键差别见下 |
| 调度器 / 主循环里 `resume` | 事件循环捞队列 | microtask / event 队列里的回调就是「该 resume 谁了」 |
| `coroutine.status` | Future 未完成 / 已完成 / 已失败 | pending / completed / error |
| 通道 / 邮箱（若你在 copp 上自建） | `Stream` / 自己的广播 | 语言层没有 CSP channel |

### 7.2 用 resume/yield 描述一次 `await dao.getAllActive()`

```text
loadLibrary 像一个 copp task / Lua co：

  resume(loadLibrary)
    → 跑到 await getAllActive()
    → 等价 yield(「等这个 Future」)     // 主动让出
    → 当前 task 挂起，主循环继续干别的（画 UI、点按钮…）

  （底层查库结束）
    → Future:complete(rows)
    → 调度器：resume(loadLibrary, rows) // 把结果当 resume 参数塞回来
    → 从 await 下一行继续，写 state
```

和 Lua 的差别：**谁来 resume？**

- Lua：常是你的主循环或别的 co `resume(co)`  
- Dart：几乎总是「Future 完成 → 把续体丢进事件队列 → 循环自动 resume」  
  你写的是 `await`，不是 `resume`

### 7.3 有栈 vs 无栈（最重要）

| | Lua / libcopp（典型有栈） | Dart `async` |
|--|---------------------------|--------------|
| 挂起时保存什么 | 整段调用栈（可在很深的同步函数里 yield） | 状态机断点 + 局部变量；**只有 async 函数能 await** |
| 深层同步函数 | 可以直接 `yield` | **不能**：必须一路 `async`/`await` 传上来 |
| 实现直觉 | 换栈 / 拷栈 | 编译成 `switch(state)` 式状态机（像生成器） |

因此：

- 把 Dart `async` 想成 **「只能在 async 边界 yield 的无栈协程」** 最贴切  
- 不要想成 libcopp 那种「任意 C++ 调用深度都能 yield」  

### 7.4 事件循环 ≈ 你的主循环里不断 resume

Lua 里你常写：

```lua
while true do
  -- 处理 IO 完成事件
  coroutine.resume(some_co, result)
end
```

Dart 运行时内置了这个 while：IO/定时器完成 → 入队 → 循环 `resume` 对应 Future 的等待者。  
`addPostFrameCallback` ≈ 「这一帧 paint 完再 resume 这段逻辑」。

### 7.5 和 libcopp 任务生命周期对照

```text
libcopp:  create → start/resume → yield → resume → … → 结束
Dart:     调用 async 函数 → await(yield) → Future完成(resume) → … → Future 完成返回
```

`unawaited(f)` ≈ 创建并跑起来但**不在当前 co 里 await 它**（火后不管；错误要自己处理）。

---

## 8. 和 Kotlin 协程对照（方便迁移）

| Kotlin | Dart（心智） |
|--------|----------------|
| `launch { }` | `unawaited(future)` 或直接调用返回 `Future` 的函数 |
| `async { }.await()` | `await someFuture` |
| `suspend fun` | `Future<T> f() async` |
| Dispatcher.Main | 主 isolate 事件循环（Flutter UI 同此） |
| `withContext(IO)` | 常由插件/Drift 在底层做；Dart 侧仍 `await` |
| Channel / Flow | 更接近 `Stream` |

---

## 9. 读本仓库时怎么用

1. 看到异步调用：先按 [§3.8](#38-脑内检查清单读代码时) 过一遍  
2. 看到 `await`：问「等的是哪个 Future？完成后谁改 `state`？」  
3. 看到 `unawaited(...)`：火后不管，错误要自己 catch，否则可能成未处理异常  
4. 看到 `addPostFrameCallback`：不是每帧自动跑；**登记一次，帧后再跑一次**（除非再次登记）  
5. 看到 `state =`：同步执行；会马上安排监听者更新，但仍在事件循环里，不另开线程  

---

## 10. 最小可脑内模拟的例子（Future 如何被处理与唤醒）

目标：看清三件事——**Future 谁拿着**、**谁 complete**、**await 后面的代码何时再跑**。

### 10.1 用 Completer 显式「完成 / 唤醒」（推荐先看这个）

```dart
import 'dart:async';

Future<void> main() async {
  final c = Completer<String>();   // ① 造一个还没完成的 Future
  final f = c.future;              //    f 就是那张「收据」，状态 pending

  print('A 同步：准备 await');

  // ② 故意「稍后」才完成 —— 模拟 IO/定时器回调
  //    定时器到点会作为 event 进入事件队列
  Timer(const Duration(milliseconds: 10), () {
    print('C 定时器回调：调用 complete → 把等待者入队（此刻还不跑 await 后面）');
    c.complete('ok');              // ③ 唤醒的扳机：改状态 + 续体入队
  });

  print('B 同步：马上 await，Future 未完成 → 挂起 main，登记续体，让出');
  final s = await f;               // ④ 挂起；续体 =「给 s 赋值并 print D」
  print('D 被唤醒后：s=$s');       // ⑤ 事件循环执行入队的续体时才到这里
}
```

打印顺序（逻辑上）：

```text
A 同步：准备 await
B 同步：马上 await…          ← 仍在同一段同步里；await 后 main 挂起
（约 10ms，事件循环可干别的）
C 定时器回调：complete…      ← 定时器 event 被捞起；complete 只负责入队
D 被唤醒后：s=ok             ← 续体作为后续任务被执行 = resume
```

对应关系：

| 步骤 | 发生了什么 |
|------|------------|
| 造 `Completer` / 取 `.future` | Future 出生，pending |
| `await f` 且未完成 | **登记唤醒点**（续体），当前 async 让出 |
| `c.complete('ok')` | **异步处理的终点**：Future → completed，续体进队列 |
| 事件循环跑到该续体 | **唤醒**：从 `await` 下一行继续，`s == 'ok'` |

没有第二线程跑你的 `print('D')`；是**主 isolate 的事件循环**稍后执行被入队的回调。

### 10.2 更短：`Future.delayed`（定时器被包起来了）

```dart
Future<void> main() async {
  print('1');
  final s = await Future.delayed(
    const Duration(milliseconds: 10),
    () => 'ok',   // 定时到点后：先跑这个，再用返回值 complete Future
  );
  print('2 $s');
}
```

顺序：`1` →（约 10ms）→ `2 ok`。  
`Future.delayed` 内部等价于「Timer + Completer.complete」，唤醒路径与 §10.1 相同。

### 10.3 对照一张图

```text
await f          complete(value)           事件循环
────────         ───────────────           ────────
挂起当前 async
把「下一行」挂到
f.等待者列表
让出 ─────────────────────────────► 去跑别的任务
                 f.状态=completed
                 等待者 → 入队 ─────► 稍后取出执行
                                      = 唤醒 async
                                      await 得到 value
```

自己在本机跑：把 §10.1 存成 `tool/future_wake_demo.dart`，执行  
`dart run tool/future_wake_demo.dart`（或 `fvm dart run ...`）。

---

## 11. 一句话总结

**异步任务 = Future 的一生：发起后同步跑到 await → 挂起并把续体挂到 Future → 事件循环去干别的 → complete 把续体入队 → 循环 resume 继续，可多轮 await，最后完成「外层那个 Future」。**  
**Dart 的 async/await ≈ 无栈、协作式协程；`await` 是 yield，Future 完成是由事件循环代你 resume；不要按 libcopp 有栈模型去期待「任意深度同步函数里也能挂起」。**

相关：[startup-data-loading.md](./startup-data-loading.md)、[glossary.md](./glossary.md)。
