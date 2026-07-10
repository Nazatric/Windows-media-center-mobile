import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:windows_media_center/core/theme/theme_settings.dart';
import 'package:windows_media_center/core/theme/vista_theme.dart';
import 'package:windows_media_center/screens/home/home_screen.dart';
import 'package:windows_media_center/services/music_player_service.dart';
import 'package:windows_media_center/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ThemeSettings defaults to Blue Vista', () async {
    final storage = await StorageService.getInstance();
    final settings = ThemeSettings(storage);
    expect(settings.variant, VistaVariant.blue);
    expect(settings.glassIntensity, closeTo(0.7, 0.001));
  });

  testWidgets('HomeScreen renders all seven category tiles', (tester) async {
    final storage = await StorageService.getInstance();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeSettings(storage)),
          ChangeNotifierProvider(create: (_) => MusicPlayerService()),
        ],
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: HomeScreen(),
        ),
      ),
    );

    // Only pump a single frame: the animated background repeats forever, so
    // pumpAndSettle would never return.
    await tester.pump();

    for (final label in ['pictures', 'videos', 'music', 'movies', 'tv', 'extras', 'settings']) {
      expect(find.text(label), findsOneWidget);
    }
  });
}
