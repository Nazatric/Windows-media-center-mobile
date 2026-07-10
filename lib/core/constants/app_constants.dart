/// Central place for the "magic values" used across the app so screens and
/// services never have to repeat themselves.
class AppConstants {
  AppConstants._();

  static const String appName = 'Windows Media Center';

  // --- Supported file types -------------------------------------------------
  static const Set<String> imageExtensions = {
    'jpg', 'jpeg', 'png', 'bmp', 'gif', 'webp', 'heic',
  };

  static const Set<String> videoExtensions = {
    'mp4', 'mkv', 'mov', 'avi', 'webm', 'm4v', '3gp',
  };

  static const Set<String> audioExtensions = {
    'mp3', 'm4a', 'flac', 'wav', 'ogg', 'aac', 'wma',
  };

  // --- SharedPreferences keys ------------------------------------------------
  static const String prefPicturesFolder = 'folder.pictures';
  static const String prefMusicFolder = 'folder.music';
  static const String prefVideosFolder = 'folder.videos';
  static const String prefMoviesFolder = 'folder.movies';
  static const String prefResumePositions = 'playback.resume_positions';
  static const String prefThemeSettings = 'settings.theme';

  // --- Scanning guards --------------------------------------------------------
  /// Safety cap so an accidental "select /sdcard" doesn't hang the UI thread
  /// walking hundreds of thousands of files.
  static const int maxFilesPerScan = 4000;

  // --- Animation timings (multiplied by the user's "animation speed" slider) -
  static const Duration pageTransition = Duration(milliseconds: 420);
  static const Duration tileFocusScale = Duration(milliseconds: 180);
  static const Duration slideshowInterval = Duration(seconds: 5);
}
