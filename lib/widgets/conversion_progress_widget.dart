import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/conversion_task.dart';
import '../l10n/strings.dart';
import 'package:path/path.dart' as p;

class ConversionProgressWidget extends StatefulWidget {
  final ConversionTask task;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenFolder;

  const ConversionProgressWidget({
    super.key,
    required this.task,
    this.onRetry,
    this.onOpenFolder,
  });

  @override
  State<ConversionProgressWidget> createState() => _ConversionProgressWidgetState();
}

class _ConversionProgressWidgetState extends State<ConversionProgressWidget> {
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;

  AudioPlayer get _player {
    _audioPlayer ??= AudioPlayer();
    return _audioPlayer!;
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (_player.source == null && widget.task.outputPath != null) {
        await _player.setSource(DeviceFileSource(widget.task.outputPath!));
        await _player.setVolume(1.0);
      }
      await _player.resume();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _statusLabel() {
    switch (widget.task.status) {
      case ConversionStatus.pending:
        return S.of('waiting');
      case ConversionStatus.decrypting:
        return S.of('decrypting');
      case ConversionStatus.encoding:
        return S.of('encoding');
      case ConversionStatus.completed:
        return S.of('done');
      case ConversionStatus.failed:
        return S.of('failed');
    }
  }

  Color _statusDot() {
    switch (widget.task.status) {
      case ConversionStatus.pending:
        return const Color(0xFF9CA3AF);
      case ConversionStatus.decrypting:
      case ConversionStatus.encoding:
        return const Color(0xFF0D9488);
      case ConversionStatus.completed:
        return const Color(0xFF059669);
      case ConversionStatus.failed:
        return const Color(0xFFDC2626);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final isProcessing = widget.task.status == ConversionStatus.decrypting ||
        widget.task.status == ConversionStatus.encoding;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: _statusDot(), shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  p.basename(widget.task.fileName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              if (widget.task.status == ConversionStatus.completed)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(Icons.check_circle_outline, size: 17, color: _statusDot()),
                )
              else if (widget.task.status == ConversionStatus.failed && widget.onRetry != null)
                GestureDetector(
                  onTap: widget.onRetry,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(Icons.refresh, size: 17, color: _statusDot()),
                  ),
                ),
            ],
          ),
          if (isProcessing) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: widget.task.progress,
                minHeight: 4,
                backgroundColor: color.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_statusLabel(), style: TextStyle(fontSize: 11, color: color.onSurfaceVariant)),
                Text('${(widget.task.progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      color: color.primary,
                    )),
              ],
            ),
          ],
          if (widget.task.status == ConversionStatus.completed &&
              widget.task.originalSize != null &&
              widget.task.convertedSize != null) ...[
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description_outlined,
                        size: 13, color: color.onSurfaceVariant.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(widget.task.outputFileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: color.onSurfaceVariant)),
                    ),
                    Text(_formatSize(widget.task.convertedSize!),
                        style: TextStyle(fontSize: 11, color: color.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      label: _isPlaying ? S.of('pause') : S.of('play'),
                      onTap: _togglePlay,
                      color: color,
                    ),
                    if (widget.onOpenFolder != null) ...[
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.folder_open_rounded,
                        label: S.of('open'),
                        onTap: widget.onOpenFolder!,
                        color: color,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
          if (widget.task.status == ConversionStatus.failed && widget.task.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(widget.task.errorMessage!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color.onPrimaryContainer),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color.onPrimaryContainer,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
