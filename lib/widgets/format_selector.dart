import 'package:flutter/material.dart';
import '../models/conversion_task.dart';
import '../l10n/strings.dart';

class FormatSelector extends StatelessWidget {
  final OutputFormat selectedFormat;
  final ValueChanged<OutputFormat> onFormatChanged;

  const FormatSelector({
    super.key,
    required this.selectedFormat,
    required this.onFormatChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.of('outputFormat'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: color.onSurfaceVariant,
              )),
          const SizedBox(height: 12),
          Row(
            children: OutputFormat.values.map((format) {
              final isSelected = format == selectedFormat;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: OutputFormat.values.last == format ? 0 : 6,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onFormatChanged(format),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: isSelected ? color.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? color.primary
                                : color.outlineVariant.withValues(alpha: 0.3),
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            format.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? color.onPrimary : color.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
