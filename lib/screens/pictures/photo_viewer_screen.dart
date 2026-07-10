import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/media_file.dart';
import '../../services/exif_service.dart';

/// A single zoomable page: pinch-to-zoom and momentum panning come for free
/// from [InteractiveViewer]; double-tap-to-zoom is added on top since
/// InteractiveViewer doesn't provide that gesture itself.
class _ZoomablePhoto extends StatefulWidget {
  final File file;
  const _ZoomablePhoto({required this.file});

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto> with SingleTickerProviderStateMixin {
  final _transformController = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    const zoomedScale = 2.5;
    final isZoomed = _transformController.value != Matrix4.identity();
    if (isZoomed) {
      _transformController.value = Matrix4.identity();
      return;
    }
    final position = _doubleTapDetails?.localPosition ?? Offset.zero;
    final matrix = Matrix4.identity()
      ..translate(-position.dx * (zoomedScale - 1), -position.dy * (zoomedScale - 1))
      ..scale(zoomedScale);
    _transformController.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformController,
        minScale: 1,
        maxScale: 6,
        child: Center(
          child: Image.file(
            widget.file,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image_outlined, color: Colors.white38, size: 64),
          ),
        ),
      ),
    );
  }
}

class PhotoViewerScreen extends StatefulWidget {
  final List<MediaFile> photos;
  final int initialIndex;
  final bool slideshow;

  const PhotoViewerScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
    this.slideshow = false,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late int _index;
  bool _chromeVisible = true;
  bool _slideshowRunning = false;
  bool _showInfo = false;
  double _rotationTurns = 0;
  Timer? _slideshowTimer;
  final _exifService = ExifService();
  PhotoMetadata? _metadata;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
    _slideshowRunning = widget.slideshow;
    if (_slideshowRunning) _startSlideshow();
    _loadMetadata();
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startSlideshow() {
    _slideshowTimer?.cancel();
    _slideshowTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_index < widget.photos.length - 1) {
        _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      } else {
        _pageController.animateToPage(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
    });
  }

  void _stopSlideshow() {
    _slideshowTimer?.cancel();
    setState(() => _slideshowRunning = false);
  }

  Future<void> _loadMetadata() async {
    final meta = await _exifService.read(widget.photos[_index].file);
    if (mounted) setState(() => _metadata = meta);
  }

  void _onPageChanged(int index) {
    setState(() {
      _index = index;
      _rotationTurns = 0;
      _metadata = null;
    });
    _loadMetadata();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_index];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _chromeVisible = !_chromeVisible),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final isCurrent = index == _index;
                return AnimatedRotation(
                  turns: isCurrent ? _rotationTurns : 0,
                  duration: const Duration(milliseconds: 250),
                  child: _ZoomablePhoto(file: widget.photos[index].file),
                );
              },
            ),
            if (_chromeVisible) _buildTopBar(photo),
            if (_chromeVisible) _buildBottomBar(),
            if (_chromeVisible && _showInfo) _buildInfoPanel(photo),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(MediaFile photo) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  photo.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w300),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.rotate_right, color: Colors.white),
                tooltip: 'Rotate',
                onPressed: () => setState(() => _rotationTurns += 0.25),
              ),
              IconButton(
                icon: Icon(Icons.info_outline, color: _showInfo ? Colors.lightBlueAccent : Colors.white),
                tooltip: 'Metadata',
                onPressed: () => setState(() => _showInfo = !_showInfo),
              ),
              IconButton(
                icon: Icon(
                  _slideshowRunning ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                tooltip: _slideshowRunning ? 'Pause slideshow' : 'Play slideshow',
                onPressed: () {
                  if (_slideshowRunning) {
                    _stopSlideshow();
                  } else {
                    setState(() => _slideshowRunning = true);
                    _startSlideshow();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.0)],
          ),
        ),
        child: SizedBox(
          height: 64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: widget.photos.length,
            itemBuilder: (context, index) {
              final selected = index == _index;
              return GestureDetector(
                onTap: () => _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: selected ? 56 : 48,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected ? Colors.lightBlueAccent : Colors.white24,
                      width: selected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Image.file(
                      widget.photos[index].file,
                      fit: BoxFit.cover,
                      cacheWidth: 120,
                      errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black38),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel(MediaFile photo) {
    final meta = _metadata;
    return Positioned(
      top: 70,
      right: 12,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(photo.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text('Modified: ${photo.modified}'),
              Text('Size: ${(photo.sizeBytes / 1024).toStringAsFixed(0)} KB'),
              if (meta == null) const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Reading EXIF…'),
              ),
              if (meta != null && meta.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('No EXIF data found.'),
                ),
              if (meta != null && !meta.isEmpty) ...[
                if (meta.dimensions != null) Text('Dimensions: ${meta.dimensions}'),
                if (meta.dateTaken != null) Text('Date taken: ${meta.dateTaken}'),
                if (meta.cameraMake != null || meta.cameraModel != null)
                  Text('Camera: ${meta.cameraMake ?? ''} ${meta.cameraModel ?? ''}'.trim()),
                if (meta.fNumber != null) Text('Aperture: f/${meta.fNumber}'),
                if (meta.exposureTime != null) Text('Exposure: ${meta.exposureTime}s'),
                if (meta.iso != null) Text('ISO: ${meta.iso}'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
