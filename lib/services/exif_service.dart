import 'dart:io';

import 'package:exif/exif.dart';

class PhotoMetadata {
  final String? cameraMake;
  final String? cameraModel;
  final String? dateTaken;
  final String? exposureTime;
  final String? fNumber;
  final String? iso;
  final String? dimensions;

  const PhotoMetadata({
    this.cameraMake,
    this.cameraModel,
    this.dateTaken,
    this.exposureTime,
    this.fNumber,
    this.iso,
    this.dimensions,
  });

  bool get isEmpty =>
      cameraMake == null &&
      cameraModel == null &&
      dateTaken == null &&
      exposureTime == null &&
      fNumber == null &&
      iso == null;
}

class ExifService {
  Future<PhotoMetadata> read(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final tags = await readExifFromBytes(bytes);
      if (tags.isEmpty) return const PhotoMetadata();

      String? tag(String key) => tags[key]?.printable;

      final width = tag('EXIF ExifImageWidth') ?? tag('Image ImageWidth');
      final height = tag('EXIF ExifImageLength') ?? tag('Image ImageLength');

      return PhotoMetadata(
        cameraMake: tag('Image Make'),
        cameraModel: tag('Image Model'),
        dateTaken: tag('EXIF DateTimeOriginal') ?? tag('Image DateTime'),
        exposureTime: tag('EXIF ExposureTime'),
        fNumber: tag('EXIF FNumber'),
        iso: tag('EXIF ISOSpeedRatings'),
        dimensions: (width != null && height != null) ? '$width × $height' : null,
      );
    } catch (_) {
      return const PhotoMetadata();
    }
  }
}
