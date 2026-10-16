import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/word_highlight_binding.dart';
import '../../providers/settings_provider.dart';
import '../../providers/word_highlight_provider.dart';
import '../../utils/word_highlight.dart';

/// 为共享句子文本渲染提供当前播放词序号。
class WordHighlightBuilder extends ConsumerWidget {
  /// 要显示的原始句子文本。
  final String text;

  /// 当前句子对应的音频与播放时间轴；null 时保持普通文本渲染。
  final WordHighlightBinding? binding;

  /// 使用当前词序号构建文本。null 表示当前没有可高亮的词。
  final Widget Function(BuildContext context, int? activeWordIndex) builder;

  const WordHighlightBuilder({
    super.key,
    required this.text,
    required this.builder,
    this.binding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBinding = binding;
    final enabled = ref.watch(
      appSettingsProvider.select((settings) => settings.wordHighlightEnabled),
    );
    if (!enabled || currentBinding == null) return builder(context, null);

    final timestamps = ref
        .watch(wordTimestampsProvider(currentBinding.source.audioItemId))
        .valueOrNull;
    if (timestamps == null || timestamps.isEmpty) {
      return builder(context, null);
    }

    final start = Duration(milliseconds: currentBinding.sentenceStartMs);
    final end = Duration(milliseconds: currentBinding.sentenceEndMs);
    final source = currentBinding.source;
    final sourceKey = (
      source.audioItemId,
      currentBinding.sentenceStartMs,
      currentBinding.sentenceEndMs,
    );
    return StreamBuilder<WordHighlightPlaybackStatus>(
      key: ValueKey((sourceKey, source.playbackStatusStream)),
      stream: source.playbackStatusStream,
      initialData: source.playbackStatus,
      builder: (context, snapshot) {
        final playbackStatus = snapshot.data;
        return StreamBuilder<Duration>(
          key: ValueKey((sourceKey, source.positionStream)),
          stream: source.positionStream,
          initialData: source.currentPosition,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data;
            final highlightEnabled =
                !snapshot.hasError && playbackStatus?.allowsHighlight == true;
            final activeWordIndex =
                !highlightEnabled ||
                    positionSnapshot.hasError ||
                    position == null
                ? null
                : resolveActiveWordIndex(
                    text: text,
                    timestamps: timestamps,
                    sentenceStart: start,
                    sentenceEnd: end,
                    position: position,
                  );
            return builder(context, activeWordIndex);
          },
        );
      },
    );
  }
}
