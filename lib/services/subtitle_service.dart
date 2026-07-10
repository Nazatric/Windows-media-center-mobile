import 'dart:io';

class SubtitleCue {
  final Duration start;
  final Duration end;
  final String text;

  const SubtitleCue({required this.start, required this.end, required this.text});

  bool contains(Duration position) => position >= start && position <= end;
}

/// Parses a standard .srt file. This is intentionally hand-rolled instead of
/// pulling in a subtitle package: the format is simple, stable, and this
/// keeps the dependency surface (and therefore the build-risk surface)
/// smaller.
class SubtitleService {
  static final RegExp _timeLine = RegExp(
    r'(\d{2}):(\d{2}):(\d{2})[,.](\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2})[,.](\d{3})',
  );

  /// Looks for a subtitle file with the same base name as [videoPath] next to
  /// it on disk, e.g. `Movie.mp4` -> `Movie.srt`.
  Future<File?> findAdjacentSubtitle(String videoPath) async {
    final dot = videoPath.lastIndexOf('.');
    if (dot == -1) return null;
    final candidate = File('${videoPath.substring(0, dot)}.srt');
    return await candidate.exists() ? candidate : null;
  }

  Future<List<SubtitleCue>> parseFile(File file) async {
    try {
      final content = await file.readAsString();
      return parse(content);
    } catch (_) {
      return [];
    }
  }

  List<SubtitleCue> parse(String content) {
    final cues = <SubtitleCue>[];
    final blocks = content.replaceAll('\r\n', '\n').split(RegExp(r'\n\s*\n'));

    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.isEmpty) continue;

      final timeLineIndex = lines.indexWhere((l) => _timeLine.hasMatch(l));
      if (timeLineIndex == -1) continue;

      final match = _timeLine.firstMatch(lines[timeLineIndex])!;
      final start = Duration(
        hours: int.parse(match.group(1)!),
        minutes: int.parse(match.group(2)!),
        seconds: int.parse(match.group(3)!),
        milliseconds: int.parse(match.group(4)!),
      );
      final end = Duration(
        hours: int.parse(match.group(5)!),
        minutes: int.parse(match.group(6)!),
        seconds: int.parse(match.group(7)!),
        milliseconds: int.parse(match.group(8)!),
      );

      final text = lines.sublist(timeLineIndex + 1).join('\n').trim();
      if (text.isNotEmpty) {
        cues.add(SubtitleCue(start: start, end: end, text: text));
      }
    }

    return cues;
  }
}
