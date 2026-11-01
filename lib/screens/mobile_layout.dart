import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/cdss_disclaimer.dart';
import '../core/theme/medical_theme.dart';
import '../providers/cdss_provider.dart';
import '../widgets/clinical_summary_banner.dart';
import '../widgets/pathology_list_view.dart';
import '../widgets/patient_input_form.dart';
import '../widgets/xray_viewport.dart';

class MobileLayout extends StatefulWidget {
  const MobileLayout({super.key});

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  int _currentIndex = 1; // Default to Rentgen & Grad-CAM viewer tab

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CdssProvider>();
    final prediction = provider.prediction;
    final disclaimerText = prediction?.disclaimer ?? CdssDisclaimer.shortFooterDisclaimerUz;

    return Column(
      children: [
        // Tab Content
        Expanded(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              // Tab 0: Patient metadata & Image selector
              const Padding(
                padding: EdgeInsets.all(12),
                child: PatientInputForm(),
              ),

              // Tab 1: Interactive X-ray & Grad-CAM++ Viewport + Clinical Summary
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Expanded(
                      child: XrayViewport(),
                    ),
                    if (prediction != null) ...[
                      const SizedBox(height: 10),
                      ClinicalSummaryBanner(prediction: prediction),
                    ],
                  ],
                ),
              ),

              // Tab 2: 14 Calibrated Pathologies with White Threshold Ticks
              const Padding(
                padding: EdgeInsets.all(12),
                child: PathologyListView(),
              ),
            ],
          ),
        ),

        // Bottom Disclaimer (Google Play Compliance)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          color: MedicalColors.surface,
          child: Row(
            children: [
              const Icon(Icons.shield_outlined, size: 14, color: MedicalColors.primaryCyan),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  disclaimerText,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: MedicalColors.textMuted,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Navigation Bar
        NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: MedicalColors.surfaceElevated,
          indicatorColor: MedicalColors.primaryCyan.withValues(alpha: 0.2),
          onDestinationSelected: (idx) {
            setState(() {
              _currentIndex = idx;
            });
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: MedicalColors.primaryCyan),
              label: 'Bemor / Yuklash',
            ),
            const NavigationDestination(
              icon: Icon(Icons.image_outlined),
              selectedIcon: Icon(Icons.image, color: MedicalColors.primaryCyan),
              label: 'Rentgen & Grad-CAM',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: prediction != null && prediction.positiveFindings.isNotEmpty,
                label: Text('${prediction?.positiveFindings.length ?? 0}'),
                child: const Icon(Icons.bar_chart_outlined),
              ),
              selectedIcon: const Icon(Icons.bar_chart, color: MedicalColors.primaryCyan),
              label: '14 Patologiya',
            ),
          ],
        ),
      ],
    );
  }
}
