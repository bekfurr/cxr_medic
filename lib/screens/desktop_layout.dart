import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/cdss_disclaimer.dart';
import '../core/theme/medical_theme.dart';
import '../providers/cdss_provider.dart';
import '../widgets/clinical_summary_banner.dart';
import '../widgets/pathology_list_view.dart';
import '../widgets/patient_input_form.dart';
import '../widgets/xray_viewport.dart';

class DesktopLayout extends StatelessWidget {
  const DesktopLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CdssProvider>();
    final prediction = provider.prediction;
    final disclaimerText = prediction?.disclaimer ?? CdssDisclaimer.shortFooterDisclaimerUz;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 3-Column Workstation Grid
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Column 1 (Left): Patient Input Form & Dropzone & Server Info (width: 330)
                const SizedBox(
                  width: 330,
                  child: PatientInputForm(),
                ),

                const SizedBox(width: 14),

                // Column 2 (Center): Zoomable Interactive Viewport + Summary Banner
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Interactive Dual-Layer Grad-CAM++ Viewport
                      const Expanded(
                        child: XrayViewport(),
                      ),

                      // Clinical Summary Banner (if prediction is ready)
                      if (prediction != null) ...[
                        const SizedBox(height: 12),
                        ClinicalSummaryBanner(prediction: prediction),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // Column 3 (Right): 14-Pathology Probability Bars with White Vertical Ticks
                const SizedBox(
                  width: 380,
                  child: PathologyListView(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Google Play Policy Compliance Disclaimer Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: MedicalColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: MedicalColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 16,
                  color: MedicalColors.primaryCyan,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    disclaimerText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: MedicalColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

