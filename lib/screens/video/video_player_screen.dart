import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../models/media_file.dart';
import '../../services/playback_progress_service.dart';
import '../../services/storage_service.dart';
import '../../services/subtitle_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final MediaFile video;
  final List<MediaFile> playlist;
  final int index;

  const VideoPlayerScreen({
    super.key,
    required this.video,
    required this.playlist,
    required this.index,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  final _subtitleService = SubtitleService();
  List<SubtitleCue> _cues = [];
  bool _subtitlesEnabled = true;
  bool _controlsVisible = true;
  bool _initialized = false;
  double _speed = 1.0;
  Timer? _hideControlsTimer;
  Timer? _saveProgressTimer;
  late int _currentIndex;

  static const _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _load(widget.video);
  }

  Future<void> _load(MediaFile video) async {
    _controller = VideoPlayerController.file(video.file);
    await _controller.initialize();

    final progress = PlaybackProgressService(await StorageService.getInstance());
    final resumeAt = await progress.getResumePosition(video.path);
    if (resumeAt != null && mounted) {
      final shouldResume = await _askResume(resumeAt);
      if (shouldResume) await _controller.seekTo(resumeAt);
    }

    final subtitleFile = await _subtitleService.findAdjacentSubtitle(video.path);
    if (subtitleFile != null) {
      _cues = await _subtitleService.parseFile(subtitleFile);
    } else {
      _cues = [];
    }

    await _controller.setPlaybackSpeed(_speed);
    await _controller.play();
    _resetHideControlsTimer();
    _startProgressAutosave();

    if (mounted) setState(() => _initialized = true);
  }

  Future<bool> _askResume(Duration position) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1E2E),
        title: const Text('Resume playback?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Continue from ${_format(position)}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Start over'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Resume'),
          ),
        ],
      ),
    );
    return result ?? true;
  }

  void _startProgressAutosave() {
    _saveProgressTimer?.cancel();
    _saveProgressTimer = Timer.periodic(const Duration(seconds: 5), (_) => _saveProgress());
  }

  Future<void> _saveProgress() async {
    if (!_controller.value.isInitialized) return;
    final progress = PlaybackProgressService(await StorageService.getInstance());
    await progress.saveResumePosition(
      widget.video.path,
      _controller.value.position,
      _controller.value.duration,
    );
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  Future<void> _switchTo(int newIndex) async {
    await _saveProgress();
    await _controller.pause();
    await _controller.dispose();
    setState(() {
      _initialized = false;
      _currentIndex = newIndex;
    });
    await _load(widget.playlist[newIndex]);
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _saveProgressTimer?.cancel();
    _saveProgress();
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !_initialized
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () {
                setState(() => _controlsVisible = !_controlsVisible);
                if (_controlsVisible) _resetHideControlsTimer();
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio == 0 ? 16 / 9 : _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                  if (_subtitlesEnabled) _buildSubtitle(),
                  if (_controlsVisible) _buildControls(),
                ],
              ),
            ),
    );
  }

  Widget _buildSubtitle() {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final active = _cues.where((c) => c.contains(value.position)).toList();
        if (active.isEmpty) return const SizedBox.shrink();
        return Positioned(
          left: 24,
          right: 24,
          bottom: _controlsVisible ? 120 : 40,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(4)),
            child: Text(
              active.map((c) => c.text).join('\n'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Positioned.fill(
      child: Column(
        children: [
          _topBar(),
          const Spacer(),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _topBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.65), Colors.black.withOpacity(0.0)],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Text(
                widget.playlist[_currentIndex].name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w300),
              ),
            ),
            if (_cues.isNotEmpty)
              IconButton(
                icon: Icon(
                  _subtitlesEnabled ? Icons.subtitles : Icons.subtitles_off,
                  color: Colors.white,
                ),
                onPressed: () => setState(() => _subtitlesEnabled = !_subtitlesEnabled),
              ),
            PopupMenuButton<double>(
              icon: const Icon(Icons.speed, color: Colors.white),
              color: const Color(0xFF0F1E2E),
              initialValue: _speed,
              onSelected: (speed) async {
                setState(() => _speed = speed);
                await _controller.setPlaybackSpeed(speed);
              },
              itemBuilder: (context) => _speedOptions
                  .map((s) => PopupMenuItem(value: s, child: Text('${s}x', style: const TextStyle(color: Colors.white))))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.75), Colors.black.withOpacity(0.0)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              final total = value.duration.inMilliseconds > 0 ? value.duration.inMilliseconds.toDouble() : 1.0;
              final pos = value.position.inMilliseconds.clamp(0, total.toInt()).toDouble();
              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(trackHeight: 2),
                    child: Slider(
                      value: pos,
                      max: total,
                      activeColor: Colors.lightBlueAccent,
                      inactiveColor: Colors.white24,
                      onChanged: (v) => _controller.seekTo(Duration(milliseconds: v.round())),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_format(value.position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(_format(value.duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white, size: 30),
                onPressed: () {
                  final pos = _controller.value.position - const Duration(seconds: 10);
                  _controller.seekTo(pos < Duration.zero ? Duration.zero : pos);
                },
              ),
              const SizedBox(width: 12),
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _controller,
                builder: (context, value, _) => IconButton(
                  icon: Icon(value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.white, size: 52),
                  onPressed: () {
                    if (value.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                    _resetHideControlsTimer();
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white, size: 30),
                onPressed: () {
                  final total = _controller.value.duration;
                  final pos = _controller.value.position + const Duration(seconds: 10);
                  _controller.seekTo(pos > total ? total : pos);
                },
              ),
              if (widget.playlist.length > 1) ...[
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                  onPressed: _currentIndex < widget.playlist.length - 1
                      ? () => _switchTo(_currentIndex + 1)
                      : null,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
