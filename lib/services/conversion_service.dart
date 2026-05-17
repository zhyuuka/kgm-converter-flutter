import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/conversion_task.dart';
import 'kgm_decryptor.dart';
import 'audio_converter.dart';

class ConversionService {
  String? _customOutputDir;

  void setOutputDir(String? path) {
    _customOutputDir = path;
  }

  Future<String> getOutputDirectory() async {
    if (_customOutputDir != null && _customOutputDir!.isNotEmpty) {
      final dir = Directory(_customOutputDir!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return _customOutputDir!;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final outputDir = Directory(p.join(appDir.path, 'kgm_output'));
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    return outputDir.path;
  }

  Future<void> convertSingle(ConversionTask task) async {
    try {
      task.status = ConversionStatus.decrypting;
      task.progress = 0.0;

      final outputDir = await getOutputDirectory();

      final decryptor = KgmDecryptor(
        inputPath: task.inputPath,
        onProgress: (progress) {
          task.progress = progress;
        },
      );

      final decryptedData = await decryptor.decrypt();

      if (decryptedData == null || decryptedData.isEmpty) {
        throw Exception('Decryption failed: no data');
      }

      task.status = ConversionStatus.encoding;
      task.progress = 0.96;

      final converter = AudioConverter(
        task: task,
        onProgress: (progress) {
          task.progress = progress;
        },
      );

      await converter.convert(decryptedData, outputDir);

      task.status = ConversionStatus.completed;
      task.progress = 1.0;
    } catch (e) {
      task.status = ConversionStatus.failed;
      task.errorMessage = e.toString();
      task.progress = 0.0;
    }
  }

  Future<void> convertBatch(
    List<ConversionTask> tasks, {
    bool parallel = true,
  }) async {
    final toConvert = tasks
        .where((t) => t.status == ConversionStatus.pending)
        .toList();

    if (toConvert.isEmpty) return;

    if (parallel && toConvert.length > 1) {
      await Future.wait(toConvert.map((t) => convertSingle(t)));
    } else {
      for (final task in toConvert) {
        await convertSingle(task);
      }
    }
  }
}
