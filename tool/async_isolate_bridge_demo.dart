/// 学习用：模拟「DAO / Drift createInBackground」一类机制。
///
/// ## 你要建立的图景
///
/// ```text
/// 主 isolate（类似 App UI 线程）          后台 isolate（类似 DB worker）
/// ──────────────────────────            ──────────────────────────
/// 1. 开收件箱 ready
/// 2. spawn(worker, ready.sendPort) ──►  3. 启动，开自己的 inbox
/// 3'. await ready.first                 4. 把 inbox.sendPort 发回主侧
/// 4'. 得到 workerSendPort ◄────────────
/// 5. await dao.getAllActive()
///    发 Query + 本次 reply 地址 ──────►  6. 同步「查库」
/// 7. complete Future ◄────────────────  7. 往 reply 地址 send 结果
/// 8. await 被唤醒，拿到列表
/// ```
///
/// ## 两个易混概念
///
/// - [ReceivePort]：本 isolate 的「收件箱」，只能在本侧 listen。
/// - [SendPort]：收件箱对外的「邮寄地址」，可以发给别的 isolate，对方用
///   `sendPort.send(消息)` 把数据寄回来。
///
/// 运行（仓库根目录）：
///   fvm dart run tool/async_isolate_bridge_demo.dart
library;

import 'dart:async';
import 'dart:isolate';

// ---------------------------------------------------------------------------
// 主 isolate：假 DAO
// ---------------------------------------------------------------------------

/// 主 isolate 上的「假 DAO」：对外只暴露 [Future]，内部把活丢给后台。
///
/// 业务代码只写：`final items = await dao.getAllActive();`
/// 不必知道后面有没有 isolate。
class FakeAudioDao {
  /// [workerSendPort]：后台 isolate 收件箱的地址（握手阶段拿到，见 main）。
  FakeAudioDao(this._workerSendPort);

  /// 只能「发」，不能在主侧 listen；真正听消息的是后台的 ReceivePort。
  final SendPort _workerSendPort;

  /// 每次查询用不同 id，方便日志区分（真实 Drift 也有请求编号一类机制）。
  int _nextId = 0;

  /// 对应业务里的：`await dao.getAllActive()`。
  ///
  /// 流程：
  /// 1. 建 Completer → 得到尚未完成的 Future（收据）
  /// 2. 建本次专用的 reply 收件箱，listen 到结果后 complete
  /// 3. 把「查询 + reply.sendPort」发给后台
  /// 4. **立刻** return completer.future（此时还是 pending）
  /// 5. 调用方 await 时挂起；后台做完寄回结果 → complete → 被唤醒
  Future<List<String>> getAllActive() {
    final id = _nextId++;

    // Completer = 「我以后会手动给这张 Future 填上结果」的控制器。
    final completer = Completer<List<String>>();

    // 本次查询专用的回信收件箱（只在主 isolate 使用）。
    final reply = ReceivePort();

    // listen：以后有人往 reply.sendPort 寄东西，这里的回调会在主 isolate 执行。
    reply.listen((message) {
      // 一次查询只收一封回信，用完关掉，避免泄漏。
      reply.close();

      if (message is List<String>) {
        // complete = 异步任务的「唤醒扳机」：
        // Future 变为已完成，并把 await 后面的续体丢进事件队列。
        print('[main] got reply for #$id, complete Future');
        completer.complete(message);
      } else if (message is String && message.startsWith('error:')) {
        completer.completeError(StateError(message));
      }
    });

    // 发给后台：查询 id + 「结果请寄到这个地址」。
    // reply.sendPort 可以跨 isolate 传递；ReceivePort 本身不能传。
    print('[main] send query #$id to worker, then await');
    _workerSendPort.send(_Query(id, reply.sendPort));

    // 注意：这里没有 await。函数同步返回 pending 的 Future。
    // 调用方写 await dao.getAllActive() 时，才会挂起等 complete。
    return completer.future;
  }
}

/// 主 → 后台的一封「查询信」。
///
/// - [id]：日志用
/// - [replyPort]：后台做完后，往这里 send 结果（地址在主 isolate）
class _Query {
  _Query(this.id, this.replyPort);

  final int id;
  final SendPort replyPort;
}

// ---------------------------------------------------------------------------
// 后台 isolate：入口函数
// ---------------------------------------------------------------------------

/// 后台 isolate 的入口（类似 Drift DB worker 进程里的主循环）。
///
/// [Isolate.spawn] 要求入口是顶层函数或 static，且只能带**一个**参数。
/// 我们把「主侧 ready 收件箱的 SendPort」当作这个参数传进来，
/// 好让 worker 把自己的 inbox 地址寄回主侧（握手）。
///
/// 参数名 [mainReadyPort]：主 isolate 上某个 ReceivePort 的 sendPort。
void _workerMain(SendPort mainReadyPort) {
  // 在「后台 isolate」里新建收件箱。主 isolate 寄查询信就寄到这里。
  final inbox = ReceivePort();

  // ★ 握手关键一步：
  // 主侧现在还不知道后台 inbox 的地址。
  // 所以把 inbox.sendPort 寄到主侧传来的 mainReadyPort。
  // 主侧 await ready.first 就能拿到这个 SendPort，之后才能发查询。
  mainReadyPort.send(inbox.sendPort);

  // 后台也有自己的事件循环；listen 注册「收到一封查询怎么处理」。
  inbox.listen((message) {
    if (message is! _Query) return;

    print('[worker] run query #${message.id} (sync work on worker isolate)');

    // 假装 sqlite3 同步 SELECT：空转约 40ms。
    // 卡住的是后台 isolate，不是主 isolate（UI 线）。
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < 40) {}
    final rows = <String>['A1', 'A2', 'B1'];

    print('[worker] done #${message.id}, send rows back');

    // 寄回「这封查询附带的 reply 地址」，不是寄到 inbox。
    // 主侧 reply.listen 会收到，然后 completer.complete(rows)。
    message.replyPort.send(rows);
  });
}

// ---------------------------------------------------------------------------
// 主 isolate：程序入口
// ---------------------------------------------------------------------------

Future<void> main() async {
  print('--- start ---');

  // ---------- 握手：启动 worker，并拿到「往 worker 寄信」的地址 ----------
  //
  // ready = 主侧临时收件箱，只用来收「worker 报到时寄来的 SendPort」。
  final ready = ReceivePort();

  // Isolate.spawn(入口函数, 传给入口的唯一参数)
  // - 第一个参数：后台要跑的函数 _workerMain
  // - 第二个参数：ready.sendPort（后台用它把 inbox.sendPort 寄回来）
  //
  // await spawn：等到「isolate 已创建并开始跑」；
  // 此时后台可能还没执行到 mainReadyPort.send，所以还不能假定已有地址。
  await Isolate.spawn(_workerMain, ready.sendPort);

  // ready.first：
  // - ReceivePort 也是 Stream；.first =「等流上的第一条消息，拿到就结束」
  // - 这条消息就是 worker 里 mainReadyPort.send(inbox.sendPort) 寄来的
  // - await：主 isolate 在此挂起，直到第一条消息到达（事件循环可干别的）
  // - as SendPort：告诉编译器「我确信这是 SendPort」（学习示例里简化写法）
  //
  // 得到的 workerSendPort = 后台 inbox 的邮寄地址，之后所有查询都寄到这。
  final workerSendPort = await ready.first as SendPort;

  // 握手结束，ready 不再使用，关掉避免资源泄漏。
  ready.close();

  // 把「后台地址」交给假 DAO，之后业务只跟 DAO 打交道。
  final dao = FakeAudioDao(workerSendPort);

  // ---------- 一次查询：和 await dao.getAllActive() 同构 ----------
  print('[main] before await (UI could paint here)');

  // 这里会：发查询 → 返回 pending Future → await 挂起 →
  // worker 做完寄回 → complete → 事件循环唤醒 → items 有值。
  final items = await dao.getAllActive();

  print('[main] after await, items=$items');
  print('--- end ---');
}
