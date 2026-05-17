import 'dart:io';
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:path/path.dart' as p;
import '../models/conversion_task.dart';

class AudioConverter {
  final ConversionTask task;
  final void Function(double progress)? onProgress;

  AudioConverter({required this.task, this.onProgress});

  Future<String> convert(Uint8List decryptedData, String outputDir) async {
    final baseName = _stripKgmExtension(task.fileName);
    final tempInputPath = p.join(outputDir, '${baseName}._decrypted_tmp');
    final outputPath = p.join(outputDir, task.outputFileName);

    final tempFile = File(tempInputPath);
    await tempFile.writeAsBytes(decryptedData);
    onProgress?.call(0.95);

    try {
      final args = _buildFfmpegArgs(tempInputPath, outputPath);

      final session = await FFmpegKit.executeWithArguments(args);
      final returnCode = await session.getReturnCode();
      final output = await session.getOutput();
      final failLog = await session.getFailStackTrace();

      if (returnCode != null && returnCode.isValueSuccess()) {
        onProgress?.call(1.0);

        final outputFile = File(outputPath);
        task.outputPath = outputPath;
        task.originalSize = decryptedData.length;
        task.convertedSize = await outputFile.length();

        return outputPath;
      } else {
        throw Exception('FFmpeg failed [rc=$returnCode]: $output | $failLog');
      }
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  String _stripKgmExtension(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.kgm')) return fileName.substring(0, fileName.length - 4);
    if (lower.endsWith('.vpr')) return fileName.substring(0, fileName.length - 4);
    return fileName;
  }

  List<String> _buildFfmpegArgs(String inputPath, String outputPath) {
    switch (task.outputFormat) {
      case OutputFormat.flac:
        return [
          '-y',
          '-i', inputPath,
          '-acodec', 'flac',
          '-compression_level', '8',
          outputPath,
        ];
      case OutputFormat.wav:
        return [
          '-y',
          '-i', inputPath,
          '-acodec', 'pcm_s16le',
          outputPath,
        ];
      case OutputFormat.mp3:
        return [
          '-y',
          '-i', inputPath,
          '-acodec', 'libmp3lame',
          '-b:a', '320k',
          outputPath,
        ];
      case OutputFormat.aac:
        return [
          '-y',
          '-i', inputPath,
          '-acodec', 'aac',
          '-b:a', '256k',
          outputPath,
        ];
      case OutputFormat.ogg:
        return [
          '-y',
          '-i', inputPath,
          '-acodec', 'libvorbis',
          '-q:a', '8',
          outputPath,
        ];
    }
  }
}
