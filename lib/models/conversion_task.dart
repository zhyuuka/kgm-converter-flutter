enum ConversionStatus { pending, decrypting, encoding, completed, failed }

enum OutputFormat { flac, wav, mp3, aac, ogg }

extension OutputFormatExtension on OutputFormat {
  String get label {
    switch (this) {
      case OutputFormat.flac:
        return 'FLAC';
      case OutputFormat.wav:
        return 'WAV';
      case OutputFormat.mp3:
        return 'MP3';
      case OutputFormat.aac:
        return 'AAC';
      case OutputFormat.ogg:
        return 'OGG';
    }
  }

  String get extension {
    switch (this) {
      case OutputFormat.flac:
        return 'flac';
      case OutputFormat.wav:
        return 'wav';
      case OutputFormat.mp3:
        return 'mp3';
      case OutputFormat.aac:
        return 'm4a';
      case OutputFormat.ogg:
        return 'ogg';
    }
  }

  String get mimeType {
    switch (this) {
      case OutputFormat.flac:
        return 'audio/flac';
      case OutputFormat.wav:
        return 'audio/wav';
      case OutputFormat.mp3:
        return 'audio/mpeg';
      case OutputFormat.aac:
        return 'audio/mp4';
      case OutputFormat.ogg:
        return 'audio/ogg';
    }
  }
}

class ConversionTask {
  final String inputPath;
  final String fileName;
  final OutputFormat outputFormat;
  ConversionStatus status;
  double progress;
  String? errorMessage;
  String? outputPath;
  int? originalSize;
  int? convertedSize;
  String customName;

  ConversionTask({
    required this.inputPath,
    required this.fileName,
    required this.outputFormat,
    this.status = ConversionStatus.pending,
    this.progress = 0.0,
    this.errorMessage,
    this.outputPath,
    this.originalSize,
    this.convertedSize,
    this.customName = '',
  });

  String get outputFileName {
    if (customName.isNotEmpty) {
      return '$customName.${outputFormat.extension}';
    }
    final baseName = fileName.endsWith('.kgm')
        ? fileName.substring(0, fileName.length - 4)
        : fileName;
    if (baseName.endsWith('.vpr')) {
      return '${baseName.substring(0, baseName.length - 4)}.${outputFormat.extension}';
    }
    return '$baseName.${outputFormat.extension}';
  }

  String get sizeReduction {
    if (originalSize == null || convertedSize == null) return '-';
    final reduction = ((originalSize! - convertedSize!) / originalSize! * 100)
        .toStringAsFixed(1);
    return '$reduction%';
  }
}
