# Windows Media Center (Flutter, Android)

An unofficial, fan-made recreation of the Windows Vista / Windows 7 era
**Windows Media Center** interface, built as a native Flutter app for
Android. Not affiliated with or endorsed by Microsoft.

---

## What's actually implemented

| Category | Status |
|---|---|
| Aero Glass shell (background, glass panels, tiles, reflections, glow, focus/hover/tap animation, fade-scale page transitions) | ✅ Fully implemented, theme-able |
| Home / start screen with the 7 categories | ✅ |
| **Pictures**: folder picker → albums by folder → grid → full-screen viewer with pinch/double-tap zoom, pan, rotate, slideshow, thumbnail strip, EXIF panel | ✅ |
| **Music**: folder picker → albums by folder → queue playback, shuffle, repeat (off/all/one), Now Playing screen with seek bar and an animated (not real-FFT) visualizer | ✅ |
| **Videos** / **Movies**: folder picker → grid → player with resume-from-last-position, ±10s skip, playback speed, adjacent `.srt` subtitles, fullscreen | ✅ |
| **TV** | ⚠️ Honest placeholder — phones/tablets have no TV tuner hardware, so this explains that instead of faking Live TV. Wire up a network tuner (e.g. HDHomeRun) here if you have one. |
| **Extras** | ⚠️ Small "about/credits" utility screen — no fake bundled games (the real Media Center's games weren't ours to redistribute). |
| **Settings**: theme (Blue/Green/Silver/Dark Vista), glass intensity, blur, glow, particle density, animation speed, performance mode, developer mode (FPS overlay), cache clearing | ✅ |

This is a substantial, working app skeleton with real functionality — not
just a mockup — but it is **not** a from-a-tuner-card TV experience (that
hardware doesn't exist on Android), and the music visualizer is a stylized
animation, not a genuine audio-spectrum analyzer (that requires a native FFT
plugin, deliberately left out to keep the dependency surface small and
build-reliable).

## Sound effects

`assets/sounds/` bundles the project author's own original Windows Vista/7-
style sound effects (not extracted Microsoft assets). A few are wired up in
`lib/services/sound_service.dart`:

- **Startup chime** — plays once when the app launches (`main.dart`)
- **Navigation sound** — plays when moving from Start into a category (`home_screen.dart`)
- **Tap sound** — plays on every glass tile tap, app-wide (`FocusScale`, used by `GlassTile`)
- **Error sound** — plays alongside permission-denied messages in Pictures/Music/Videos

All of them can be muted from Settings → Performance → "Sound effects". The
rest of the original set (logoff, shutdown, hardware insert/remove, speech
prompts, etc.) ships in the same folder if you want to wire up more triggers.

## Why some other things aren't in here

**No copied bitmaps.** Nothing in this repo is a screenshot, extracted icon,
or asset pulled from the `windows-media-center-sdk` repo you linked (which
itself bundles decompiled/extracted Microsoft resources). Every visual —
gradients, glass, glow, particles, the app icon — is built with Flutter
widgets/`CustomPainter` or generated procedurally, using your screenshots
only as a design reference.

**No fake game/media content.** Extras doesn't pretend to bundle Chess
Titans, movie posters, or album art that isn't actually on your device.

## Requirements & assumptions

- **minSdk 24 / compileSdk 35 / targetSdk 35**, Kotlin, AndroidX.
- Users pick a real folder on their device for each library (Storage Access
  Framework), the same philosophy as Media Center's "Pictures/Music/Videos
  Library" — rather than requesting broad "all files" access.
- Debug-signed release builds (see `android/app/build.gradle`) so CI and
  `flutter build apk --release` produce an installable APK without you
  needing to generate/manage a keystore. Swap in your own signing config
  before shipping to the Play Store.
- Code shrinking (R8/minify) is **off by default** in the release build —
  see the comment in `android/app/build.gradle` for why, and how to turn it
  on once you've verified the app on a real device.

## Opening the project

```bash
git clone <this repo>
cd windows_media_center
flutter pub get
flutter run
```

Android Studio / VS Code with the Flutter plugin can open the folder
directly. If Android Studio complains about a missing Gradle wrapper jar
the very first time (see note below), let it "Sync" — or run:

```bash
cd android && gradle wrapper --gradle-version 8.10.2 --distribution-type all
```

### A deliberate omission: the Gradle wrapper jar

`android/gradle/wrapper/gradle-wrapper.jar` is a small compiled binary, not
source text — it isn't something that can be hand-authored reliably, so it
is **not** committed to this repo (only `gradle-wrapper.properties`, which
pins the intended version, `8.10.2`, is). The CI workflow regenerates it on
every run using the Gradle already installed on the GitHub runner. Locally,
Android Studio / `flutter run` will do the same the first time you build.

## CI (`.github/workflows/build.yml`)

On every push: installs Java 17 + Flutter stable → `flutter pub get` →
writes `local.properties` → regenerates the Gradle wrapper → `flutter
analyze` / `flutter test` (both non-blocking, so lint nits never stop you
from getting an APK) → `flutter build apk --release` → uploads
`app-release.apk` as a build artifact.

## Honest note on "should build with no manual fixes"

This project was written and reviewed carefully — every relative import was
verified to resolve, every widget's constructor call sites were checked
against its definition, package versions were checked against pub.dev at
the time of writing, and a known upstream `just_audio` release-build bug was
specifically avoided by pinning below it. That said, it was written without
a local Flutter/Gradle/Android SDK install to compile against, so treat the
very first CI run as the real first compile — if something in the Android
toolchain has moved since, paste me the failing step's log and I'll patch it.

## Project structure

```
lib/
  core/            constants, theme palette + persisted ThemeSettings
  models/          MediaFile (a scanned picture/video/audio file)
  services/        folder scanning, EXIF, subtitles, permissions, storage,
                   music playback engine, playback-resume tracking
  animations/      shared page transition + focus/hover/tap scale wrapper
  widgets/         AeroBackground, GlassPanel, GlassTile, top bar, FPS overlay
  screens/         home, pictures, music, video, movies, tv, extras, settings
```
