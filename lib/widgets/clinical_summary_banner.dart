import 'package:flutter/material.dart';
import '../core/theme/medical_theme.dart';
import '../models/prediction_response.dart';

class ClinicalSummaryBanner extends StatelessWidget {
  final PredictionResponse prediction;

  const ClinicalSummaryBanner({
    super.key,
    required this.prediction,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNormal = prediction.isNormal;
    final int positiveCount = prediction.positiveFindings.length;
    final Color riskColor = MedicalColors.forRiskCode(prediction.overallRisk, !isNormal);

    return Container(
      decoration: BoxDecoration(
        color: MedicalColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isNormal ? MedicalColors.riskNormal.withValues(alpha: 0.4) : riskColor.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Risk Code Badge + Metrics (Inference ms, No-Finding Confidence)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Risk Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: riskColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isNormal ? Icons.verified_rounded : Icons.warning_amber_rounded,
                      color: riskColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'XAVF DARAJASI: ${prediction.overallRisk}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: riskColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Inference time
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MedicalColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: MedicalColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.speed_rounded, size: 14, color: MedicalColors.textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      '${prediction.inferenceMs} ms',
                      style: const TextStyle(
                        fontSize: 11,
                        color: MedicalColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Normal confidence
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MedicalColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: MedicalColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 14, color: MedicalColors.primaryCyan),
                    const SizedBox(width: 5),
                    Text(
                      'No-Finding: ${(prediction.noFindingConfidence * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: MedicalColors.primaryCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Clinical Summary Text
          Text(
            prediction.clinicalSummary,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: MedicalColors.textPrimary,
              height: 1.45,
            ),
          ),

          if (positiveCount > 0) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: prediction.positiveFindings.map((p) {
                return Chip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  backgroundColor: MedicalColors.riskHigh.withValues(alpha: 0.12),
                  side: BorderSide(color: MedicalColors.riskHigh.withValues(alpha: 0.3)),
                  label: Text(
                    '${p.nameUz}: ${p.probPercent}%',
                    style: const TextStyle(
                      color: MedicalColors.riskHigh,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
