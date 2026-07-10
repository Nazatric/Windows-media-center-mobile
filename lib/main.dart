import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/theme_settings.dart';
import 'screens/home/home_screen.dart';
import 'services/music_player_service.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge, gesture-nav-friendly chrome. SafeArea inside WmcScaffold
  // handles the notch / cutout / nav-bar insets from here on.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  // Both portrait and landscape are supported (per spec); we do not lock
  // orientation at the app level, only temporarily during video playback.

  final storage = await StorageService.getInstance();

  // The Media Center "start-up chime" — plays once per app launch.
  unawaited(SoundService.instance.play(SoundService.startup, volume: 0.6));

  runApp(WindowsMediaCenterApp(storage: storage));
}

class WindowsMediaCenterApp extends StatelessWidget {
  final StorageService storage;
  const WindowsMediaCenterApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeSettings(storage)),
        ChangeNotifierProvider(create: (_) => MusicPlayerService()),
      ],
      child: MaterialApp(
        title: 'Windows Media Center',
        debugShowCheckedModeBanner: false,
        // Material 3 is explicitly disabled: every visual element in this
        // app is custom-built (glass panels, tiles, transitions) rather than
        // drawn from Material's design language.
        theme: ThemeData(
          useMaterial3: false,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          fontFamily: null,
          textTheme: const TextTheme().apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
          sliderTheme: const SliderThemeData(showValueIndicator: ShowValueIndicator.never),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
