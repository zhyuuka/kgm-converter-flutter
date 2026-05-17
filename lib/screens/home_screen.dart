import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import '../models/conversion_task.dart';
import '../services/conversion_service.dart';
import '../widgets/conversion_progress_widget.dart';
import '../widgets/format_selector.dart';
import '../l10n/strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ConversionService _conversionService = ConversionService();
  final List<ConversionTask> _tasks = [];
  final TextEditingController _nameController = TextEditingController();

  OutputFormat _selectedFormat = OutputFormat.flac;
  bool _isConverting = false;
  String? _outputFolderPath;
  bool _parallelMode = true;

  int get _pendingCount =>
      _tasks.where((t) => t.status == ConversionStatus.pending).length;
  int get _completedCount =>
      _tasks.where((t) => t.status == ConversionStatus.completed).length;
  int get _failedCount =>
      _tasks.where((t) => t.status == ConversionStatus.failed).length;

  bool get _canStart => _pendingCount > 0 && !_isConverting;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        int added = 0;
        setState(() {
          for (final file in result.files) {
            if (file.path != null && file.name.toLowerCase().endsWith('.kgm')) {
              final exists = _tasks.any((t) => t.inputPath == file.path);
              if (!exists) {
                _tasks.add(ConversionTask(
                  inputPath: file.path!,
                  fileName: file.name,
                  outputFormat: _selectedFormat,
                  customName: _nameController.text.trim(),
                ));
                added++;
              }
            }
          }
        });
        if (added == 0 && result.files.isNotEmpty) {
          _showError(S.of('noKgmFiles'));
        }
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _pickOutputFolder() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: S.of('outputFolder'),
      );
      if (result != null) {
        setState(() => _outputFolderPath = result);
        _conversionService.setOutputDir(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
          );
        }
      }
    } catch (e) {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );
        if (result != null && result.files.single.path != null) {
          final file = File(result.files.single.path!);
          final dir = file.parent.path;
          setState(() => _outputFolderPath = dir);
          _conversionService.setOutputDir(dir);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(dir), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
            );
          }
        }
      } catch (e2) {
        _showError(e2.toString());
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _startConversion() async {
    if (_pendingCount == 0) return;
    setState(() => _isConverting = true);
    await _conversionService.convertBatch(_tasks, parallel: _parallelMode);
    if (mounted) setState(() => _isConverting = false);
  }

  void _clearCompleted() {
    setState(() {
      _tasks.removeWhere(
          (t) => t.status == ConversionStatus.completed || t.status == ConversionStatus.failed);
    });
  }

  void _retryTask(ConversionTask task) async {
    task.customName = _nameController.text.trim();
    task.status = ConversionStatus.pending;
    task.progress = 0.0;
    task.errorMessage = null;
    setState(() {});
    await _conversionService.convertSingle(task);
    if (mounted) setState(() {});
  }

  Future<void> _openFile(ConversionTask task) async {
    if (task.outputPath != null) {
      await OpenFilex.open(task.outputPath!);
    }
  }

  void _applyCustomNameToAll() {
    final name = _nameController.text.trim();
    setState(() {
      for (final task in _tasks) {
        if (task.status == ConversionStatus.pending) {
          task.customName = name;
        }
      }
    });
  }

  void _toggleLocale() {
    setState(() {
      S.setLocale(S.locale == 'zh' ? 'en' : 'zh');
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(color),
            FormatSelector(
              selectedFormat: _selectedFormat,
              onFormatChanged: (format) {
                setState(() => _selectedFormat = format);
                _applyCustomNameToAll();
              },
            ),
            _buildCustomNameBar(color),
            _buildOutputBar(color),
            Expanded(
              child: _tasks.isEmpty
                  ? _buildEmptyState(color)
                  : RefreshIndicator(
                      onRefresh: () async {},
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 100),
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          return ConversionProgressWidget(
                            task: _tasks[index],
                            onRetry: () => _retryTask(_tasks[index]),
                            onOpenFolder: () => _openFile(_tasks[index]),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAddButton(color),
            _buildConvertButton(color),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.of('appName'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text(S.of('appSubtitle'),
                    style: TextStyle(fontSize: 12, color: color.onSurfaceVariant, height: 1.4)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _toggleLocale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(S.locale == 'zh' ? 'EN' : '中',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color.primary)),
            ),
          ),
          if (_completedCount > 0 || _failedCount > 0) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _clearCompleted,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.close_rounded, size: 18, color: color.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomNameBar(ColorScheme color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.edit_outlined, size: 17, color: color.primary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _nameController,
              onChanged: (_) => _applyCustomNameToAll(),
              decoration: InputDecoration(
                hintText: S.of('customNameHint'),
                hintStyle: TextStyle(fontSize: 13, color: color.onSurfaceVariant.withValues(alpha: 0.5)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: color.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputBar(ColorScheme color) {
    return GestureDetector(
      onTap: _pickOutputFolder,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.folder_outlined, size: 18, color: color.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.of('outputFolder'),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.onSurfaceVariant, letterSpacing: 0.3)),
                  const SizedBox(height: 1),
                  Text(
                    _outputFolderPath ?? S.of('outputFolderDefault'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color.onSurface),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: color.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(ColorScheme color) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(14),
      color: color.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _isConverting ? null : () => _pickFiles(),
        child: Container(
          width: 56,
          height: 52,
          alignment: Alignment.center,
          child: Icon(Icons.add_rounded, size: 24, color: color.onSurface),
        ),
      ),
    );
  }

  Widget _buildConvertButton(ColorScheme color) {
    final enabled = _canStart;
    return Expanded(
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(14),
        color: enabled ? color.primary : color.surfaceContainerHighest,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? () => _startConversion() : null,
          onLongPress: () {
            setState(() => _parallelMode = !_parallelMode);
            _showError(_parallelMode ? S.of('parallelMode') : S.of('sequentialMode'));
          },
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isConverting)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(color.onPrimary),
                    ),
                  )
                else
                  Icon(Icons.play_arrow_rounded, size: 22, color: enabled ? color.onPrimary : color.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  _isConverting ? S.of('converting') : S.of('startConvert'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: enabled ? color.onPrimary : color.onSurfaceVariant,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme color) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.music_note_rounded, size: 32, color: color.onSurfaceVariant.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 18),
          Text(S.of('noFiles'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color.onSurface)),
          const SizedBox(height: 6),
          Text(S.of('noFilesHint'), style: TextStyle(fontSize: 13, color: color.onSurfaceVariant)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: ['FLAC', 'WAV', 'MP3', 'AAC', 'OGG'].map((fmt) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(fmt,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color.onSurfaceVariant, letterSpacing: 0.5)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
