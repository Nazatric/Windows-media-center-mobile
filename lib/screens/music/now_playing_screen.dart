import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_settings.dart';
import '../../core/theme/vista_theme.dart';
import '../../services/music_player_service.dart';
import '../../widgets/wmc_scaffold.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _visualizerController;

  @override
  void initState() {
    super.initState();
    _visualizerController = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _visualizerController.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicPlayerService>();
    final palette = context.watch<ThemeSettings>().palette;
    final track = music.currentTrack;

    return WmcScaffold(
      title: 'now playing',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _visualizerController,
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _VisualizerPainter(
                    t: _visualizerController.value,
                    playing: music.isPlaying,
                    color: palette.accentGlow,
                  ),
                ),
              ),
            ),
            Text(
              track?.name ?? 'Nothing playing',
              style: TextStyle(color: palette.textPrimary, fontSize: 20, fontWeight: FontWeight.w300),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              track != null ? 'from ${track.folderName}' : '',
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 18),
            StreamBuilder<Duration>(
              stream: music.player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final total = music.player.duration ?? Duration.zero;
                final max = total.inMilliseconds > 0 ? total.inMilliseconds.toDouble() : 1.0;
                final value = position.inMilliseconds.clamp(0, max.toInt()).toDouble();
                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: palette.accentGlow,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: palette.accentGlow,
                        overlayColor: palette.accentGlow.withOpacity(0.2),
                        trackHeight: 2,
                      ),
                      child: Slider(
                        value: value,
                        max: max,
                        onChanged: (v) => music.seek(Duration(milliseconds: v.round())),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_format(position), style: TextStyle(color: palette.textSecondary, fontSize: 12)),
                          Text(_format(total), style: TextStyle(color: palette.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.shuffle,
                      color: music.shuffleEnabled ? palette.accentGlow : palette.textSecondary),
                  onPressed: music.toggleShuffle,
                ),
                IconButton(
                  icon: Icon(Icons.skip_previous, color: palette.textPrimary, size: 32),
                  onPressed: music.previous,
                ),
                _PlayPauseButton(music: music, palette: palette),
                IconButton(
                  icon: Icon(Icons.skip_next, color: palette.textPrimary, size: 32),
                  onPressed: music.next,
                ),
                IconButton(
                  icon: Icon(
                    switch (music.loopMode) {
                      LoopMode.off => Icons.repeat,
                      LoopMode.all => Icons.repeat,
                      LoopMode.one => Icons.repeat_one,
                    },
                    color: music.loopMode == LoopMode.off ? palette.textSecondary : palette.accentGlow,
                  ),
                  onPressed: music.cycleRepeatMode,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final MusicPlayerService music;
  final VistaPalette palette;
  const _PlayPauseButton({required this.music, required this.palette});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: music.togglePlayPause,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [palette.accentGlow, palette.skyMid]),
          boxShadow: [BoxShadow(color: palette.accentGlow.withOpacity(0.5), blurRadius: 16, spreadRadius: 1)],
        ),
        child: Icon(music.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 30),
      ),
    );
  }
}

/// A stylized, playback-reactive bar visualizer. This is not a real-time
/// FFT of the decoded audio (that would require a native audio-analysis
/// plugin); it's an animated pattern that only moves while a track is
/// actually playing, giving the "Now Playing" screen life without
/// pretending to analyze audio it isn't actually analyzing.
class _VisualizerPainter extends CustomPainter {
  final double t;
  final bool playing;
  final Color color;

  _VisualizerPainter({required this.t, required this.playing, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 28;
    final barWidth = size.width / (barCount * 1.6);
    final paint = Paint()..color = color.withOpacity(0.75);
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final phase = (t * 2 * pi) + i * 0.45;
      final envelope = playing ? (0.35 + 0.65 * (0.5 + 0.5 * sin(phase))) : 0.08;
      final barHeight = size.height * 0.4 * envelope;
      final x = i * barWidth * 1.6 + barWidth / 2;
      final rect = Rect.fromCenter(center: Offset(x, centerY), width: barWidth, height: barHeight);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(barWidth / 2)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) => true;
}
