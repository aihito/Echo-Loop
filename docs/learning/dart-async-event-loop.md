# Dart「异步」运行逻辑（心智模型）

> 用**简化结构**理解 `async` / `await` / `Future` 怎么跑。  
> **不是** Kotlin 协程实现拷贝，也不等价于 Dart VM 源码；只保留方便读业务代码的核心。  
> 结合本仓库：`await dao.getAllActive()`、`addPostFrameCallback`、Riverpod 写 `state`。  
> 最后更新：2026-10-23（补充 Lua / libcopp 术语对照）

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

若你熟 Lua / libcopp，可先读 [§6](#6-用-lua--libcopp-术语对照) 再回头看总图。

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

## 3. 标准流程（对照 DAO）

以本仓库为例：

```dart
final dbItems = await dao.getAllActive();
```

```text
① loadLibrary 跑到 await
② getAllActive() / Drift .get() 返回 pending 的 Future
③ 向底层发起异步查库（可能在后台 isolate / 平台线程，细节可黑盒）
④ loadLibrary 挂起；MainShell 里的 await loadLibrary() 也可能一起挂起
⑤ 事件循环继续处理：绘制帧、点击、其它 Future…

⑥ 查库完成 → Future.complete(行列表)     ← 通知发生：状态变更 + 续体入队
⑦ 「loadLibrary 从 await 之后继续」已在队列里
⑧ 事件循环执行该回调（= resume）：
     dbItems = 结果
     state = copyWith(audioItems: ...)
⑨ Riverpod 再通知 UI watch → 安排 rebuild
```

两层「通知」别混：

| 层级 | 含义 |
|------|------|
| Future → async 函数 | complete + 入队 + 循环 resume（§2.1b） |
| Notifier `state=` → Widget | Riverpod 订阅表，和 Future 无关 |

**异步任务完成通知 async 函数**：只有第一层。

---

## 4. 和 Flutter 帧的关系

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

## 5. 和「真多线程」的边界

| 做法 | 是否并行跑 Dart 业务逻辑 |
|------|--------------------------|
| `async`/`await` | 否，仍是协作式单线程穿插 |
| `Future` 所包装的 IO | 等待期间别人的同步代码可跑 |
| `Isolate` / `compute` | 是，另一个 isolate 真并行（另有端口通信） |

**长时间占满 CPU 的同步循环**会卡住事件循环 → 掉帧、点击无响应。重计算应拆 `await`、下沉 isolate，或缩短同步段。

---

## 6. 用 Lua / libcopp 术语对照

### 6.1 一张映射表

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

### 6.2 用 resume/yield 描述一次 `await dao.getAllActive()`

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

### 6.3 有栈 vs 无栈（最重要）

| | Lua / libcopp（典型有栈） | Dart `async` |
|--|---------------------------|--------------|
| 挂起时保存什么 | 整段调用栈（可在很深的同步函数里 yield） | 状态机断点 + 局部变量；**只有 async 函数能 await** |
| 深层同步函数 | 可以直接 `yield` | **不能**：必须一路 `async`/`await` 传上来 |
| 实现直觉 | 换栈 / 拷栈 | 编译成 `switch(state)` 式状态机（像生成器） |

因此：

- 把 Dart `async` 想成 **「只能在 async 边界 yield 的无栈协程」** 最贴切  
- 不要想成 libcopp 那种「任意 C++ 调用深度都能 yield」  

### 6.4 事件循环 ≈ 你的主循环里不断 resume

Lua 里你常写：

```lua
while true do
  -- 处理 IO 完成事件
  coroutine.resume(some_co, result)
end
```

Dart 运行时内置了这个 while：IO/定时器完成 → 入队 → 循环 `resume` 对应 Future 的等待者。  
`addPostFrameCallback` ≈ 「这一帧 paint 完再 resume 这段逻辑」。

### 6.5 和 libcopp 任务生命周期对照

```text
libcopp:  create → start/resume → yield → resume → … → 结束
Dart:     调用 async 函数 → await(yield) → Future完成(resume) → … → Future 完成返回
```

`unawaited(f)` ≈ 创建并跑起来但**不在当前 co 里 await 它**（火后不管；错误要自己处理）。

---

## 7. 和 Kotlin 协程对照（方便迁移）

| Kotlin | Dart（心智） |
|--------|----------------|
| `launch { }` | `unawaited(future)` 或直接调用返回 `Future` 的函数 |
| `async { }.await()` | `await someFuture` |
| `suspend fun` | `Future<T> f() async` |
| Dispatcher.Main | 主 isolate 事件循环（Flutter UI 同此） |
| `withContext(IO)` | 常由插件/Drift 在底层做；Dart 侧仍 `await` |
| Channel / Flow | 更接近 `Stream` |

---

## 8. 读本仓库时怎么用

1. 看到 `await`：问「等的是哪个 Future？完成后谁改 `state`？」  
2. 看到 `unawaited(...)`：火后不管，错误要自己 catch，否则可能成未处理异常  
3. 看到 `addPostFrameCallback`：不是每帧自动跑；**登记一次，帧后再跑一次**（除非再次登记）  
4. 看到 `state =`：同步执行；会马上安排监听者更新，但仍在事件循环里，不另开线程  

---

## 9. 最小可脑内模拟的例子

```dart
Future<String> fetch() async {
  // 假装：过一会儿才 complete 的 Future
  return Future.delayed(Duration(milliseconds: 10), () => 'ok');
}

Future<void> main() async {
  print('1');
  final s = await fetch(); // yield，等 Future；由事件循环 resume
  print('2 $s');
}
```

打印顺序：`1` →（约 10ms）→ `2 ok`。

---

## 10. 一句话总结

**Dart 的 async/await ≈ 无栈、协作式协程；`await` 是 yield，Future 完成是由事件循环代你 resume；不要按 libcopp 有栈模型去期待「任意深度同步函数里也能挂起」。**

相关：[startup-data-loading.md](./startup-data-loading.md)、[glossary.md](./glossary.md)。
