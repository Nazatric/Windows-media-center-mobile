import 'package:flutter/material.dart';

import '../video/video_library_screen.dart';

class MoviesScreen extends StatelessWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const VideoLibraryScreen(
      title: 'movies',
      folderPrefKey: 'folder.movies',
    );
  }
}
