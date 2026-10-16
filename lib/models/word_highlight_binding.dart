import 'dart:async';

/// 逐词高亮对应的播放生命周期。
enum WordHighlightPlaybackStatus {
  /// 播放尚未开始，或播放器已停止。
  idle,

  /// 音频正在播放。
  playing,

  /// 播放开始后被暂停或定位。
  paused,

  /// 播放自然结束。
  completed;

  /// 当前状态是否保留时间轴上的逐词高亮。
  bool get allowsHighlight =>
      this == WordHighlightPlaybackStatus.playing ||
      this == WordHighlightPlaybackStatus.paused;
}

/// 播放位置来源；由页面把当前任务实际使用的播放器注入字幕展示层。
class WordHighlightSource {
  /// 对应词级时间戳所属的音频。
  final String audioItemId;

  /// 音频绝对时间位置流。
  final Stream<Duration> positionStream;

  /// 订阅位置流前的当前绝对位置。
  final Duration currentPosition;

  /// 当前播放器的生命周期状态。
  final WordHighlightPlaybackStatus playbackStatus;

  /// 播放器生命周期状态流。
  final Stream<WordHighlightPlaybackStatus> playbackStatusStream;

  const WordHighlightSource({
    required this.audioItemId,
    required this.positionStream,
    required this.currentPosition,
    required this.playbackStatus,
    required this.playbackStatusStream,
  });
}

/// 当前句子与播放时间轴的绑定。
class WordHighlightBinding {
  /// 当前句子的原音位置来源。
  final WordHighlightSource source;

  /// 句子起止时间（毫秒）。
  final int sentenceStartMs;
  final int sentenceEndMs;

  const WordHighlightBinding({
    required this.source,
    required this.sentenceStartMs,
    required this.sentenceEndMs,
  });
}
