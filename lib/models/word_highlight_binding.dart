import 'dart:async';

/// 播放位置来源；由页面把当前任务实际使用的播放器注入字幕展示层。
class WordHighlightSource {
  /// 对应词级时间戳所属的音频。
  final String audioItemId;

  /// 音频绝对时间位置流。
  final Stream<Duration> positionStream;

  /// 订阅位置流前的当前绝对位置。
  final Duration currentPosition;

  const WordHighlightSource({
    required this.audioItemId,
    required this.positionStream,
    required this.currentPosition,
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
