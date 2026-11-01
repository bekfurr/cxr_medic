import 'package:flutter/material.dart';
import '../core/theme/medical_theme.dart';
import '../models/pathology_item.dart';

class PathologyCard extends StatelessWidget {
  final PathologyItem item;
  final bool isSelected;
  final bool isLoadingCam;
  final VoidCallback onTap;

  const PathologyCard({
    super.key,
    required this.item,
    required this.isSelected,
    this.isLoadingCam = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPos = item.positive;
    final Color barColor = isPos
        ? (item.riskCode == 'HIGH' ? MedicalColors.riskHigh : MedicalColors.riskModerateHigh)
        : (item.prob >= item.threshold * 0.75
            ? MedicalColors.riskModerateLow
            : MedicalColors.primaryTeal);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? MedicalColors.primaryCyan.withValues(alpha: 0.08)
              : MedicalColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? MedicalColors.primaryCyan
                : (isPos ? MedicalColors.riskHigh.withValues(alpha: 0.5) : MedicalColors.border),
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: MedicalColors.primaryCyan.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Disease Names (Uzbek + English Label), Risk badge, and Target selector
            Row(
              children: [
                // Positive indicator icon or normal icon
                Icon(
                  isPos ? Icons.report_problem_rounded : Icons.check_circle_outline_rounded,
                  color: isPos ? MedicalColors.riskHigh : MedicalColors.riskLow,
                  size: 16,
                ),
                const SizedBox(width: 8),

                // Name and English label
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: item.nameUz,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isPos ? Colors.white : MedicalColors.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: ' (${item.label})',
                          style: const TextStyle(
                            fontSize: 11,
                            color: MedicalColors.textSecondary,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Grad-CAM inspect indicator
                if (isLoadingCam && isSelected)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: MedicalColors.primaryCyan,
                    ),
                  )
                else if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: MedicalColors.primaryCyan,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Grad-CAM',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  )
                else
                  Text(
                    'CAM ko‘rish',
                    style: TextStyle(
                      fontSize: 10,
                      color: MedicalColors.primaryCyan.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            // Row 2: Numerical Metrics (Prob %, Threshold, Risk Level)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 2,
              children: [
                // Probability %
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${item.probPercent}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isPos ? MedicalColors.riskHigh : MedicalColors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Threshold tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: MedicalColors.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: MedicalColors.borderLight),
                      ),
                      child: Text(
                        'Chegara: ${(item.threshold * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 10,
                          color: MedicalColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                // Risk level label
                Text(
                  item.riskLevel.isNotEmpty
                      ? item.riskLevel
                      : (isPos ? 'Musbat' : 'Manfiy'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPos ? MedicalColors.riskHigh : MedicalColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Row 3: Custom Probability Bar with White Vertical Threshold Tick
            LayoutBuilder(
              builder: (context, constraints) {
                final double totalWidth = constraints.maxWidth;
                final double probWidth = (item.prob.clamp(0.0, 1.0) * totalWidth);
                final double tickPosition = (item.threshold.clamp(0.0, 1.0) * totalWidth);

                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    // Base background bar
                    Container(
                      width: totalWidth,
                      height: 10,
                      decoration: BoxDecoration(
                        color: MedicalColors.surface,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: MedicalColors.border, width: 0.8),
                      ),
                    ),

                    // Filled Probability Bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: probWidth,
                      height: 10,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),

                    // White Vertical Threshold Tick
                    Positioned(
                      left: tickPosition - 1.0,
                      top: -2,
                      bottom: -2,
                      child: Container(
                        width: 2.2,
                        decoration: BoxDecoration(
                          color: MedicalColors.thresholdTick,
                          borderRadius: BorderRadius.circular(1),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
