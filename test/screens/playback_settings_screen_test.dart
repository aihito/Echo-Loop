import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:echo_loop/providers/settings_provider.dart';
import 'package:echo_loop/screens/playback_settings_screen.dart';

import '../helpers/mock_providers.dart';
import '../helpers/test_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('播放设置中的逐词高亮开关默认关闭并保存选择', (tester) async {
    await tester.pumpWidget(
      createTestApp(
        const PlaybackSettingsScreen(),
        overrides: [
          appSettingsProvider.overrideWith(
            () => TestAppSettings(const AppSettingsState()),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final switchFinder = find.byWidgetPredicate((widget) {
      if (widget is! SwitchListTile) return false;
      final title = widget.title;
      return title is Text && title.data == 'Highlight Words During Playback';
    });
    expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('word_highlight_enabled'), isTrue);
  });
}
