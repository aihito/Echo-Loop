import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:echo_loop/models/word_highlight_binding.dart';
import 'package:echo_loop/models/word_timestamp.dart';
import 'package:echo_loop/providers/settings_provider.dart';
import 'package:echo_loop/providers/word_highlight_provider.dart';
import 'package:echo_loop/widgets/common/word_highlight_builder.dart';

const _timestamps = [
  WordTimestamp(
    word: 'hello',
    startTime: Duration(milliseconds: 100),
    endTime: Duration(milliseconds: 300),
  ),
  WordTimestamp(
    word: 'world',
    startTime: Duration(milliseconds: 400),
    endTime: Duration(milliseconds: 600),
  ),
];

void main() {
  testWidgets('开关关闭时保持普通文本且不加载时间戳', (tester) async {
    var loadCount = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsProvider.overrideWith(_TestSettings.disabledSettings),
          wordTimestampsProvider('audio').overrideWith((ref) async {
            loadCount++;
            return _timestamps;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: WordHighlightBuilder(
              text: 'hello world',
              binding: _binding(const Stream<Duration>.empty()),
              builder: (context, index) => Text('word:$index'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('word:null'), findsOneWidget);
    expect(loadCount, 0);
  });

  testWidgets('开启后初始播放位置和后续 seek 都更新活动词', (tester) async {
    final positions = StreamController<Duration>.broadcast();
    addTearDown(positions.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsProvider.overrideWith(_TestSettings.enabledSettings),
          wordTimestampsProvider(
            'audio',
          ).overrideWith((ref) async => _timestamps),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: WordHighlightBuilder(
              text: 'hello world',
              binding: _binding(positions.stream),
              builder: (context, index) => Text('word:$index'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('word:1'), findsOneWidget);

    positions.add(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(find.text('word:0'), findsOneWidget);
  });
}

WordHighlightBinding _binding(Stream<Duration> positionStream) =>
    WordHighlightBinding(
      source: WordHighlightSource(
        audioItemId: 'audio',
        positionStream: positionStream,
        currentPosition: const Duration(milliseconds: 450),
      ),
      sentenceStartMs: 0,
      sentenceEndMs: 1000,
    );

class _TestSettings extends AppSettings {
  _TestSettings(this.isEnabled);

  final bool isEnabled;

  @override
  AppSettingsState build() => AppSettingsState(wordHighlightEnabled: isEnabled);

  static _TestSettings disabledSettings() => _TestSettings(false);
  static _TestSettings enabledSettings() => _TestSettings(true);
}
