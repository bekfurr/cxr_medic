import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/pathology_constants.dart';
import '../core/theme/medical_theme.dart';
import '../models/pathology_item.dart';
import '../providers/cdss_provider.dart';
import 'pathology_card.dart';

class PathologyListView extends StatefulWidget {
  const PathologyListView({super.key});

  @override
  State<PathologyListView> createState() => _PathologyListViewState();
}

class _PathologyListViewState extends State<PathologyListView> {
  bool _onlyPositive = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CdssProvider>();
    final prediction = provider.prediction;

    // Use prediction findings if available, else fallback list with calibrated thresholds
    final List<PathologyItem> items = prediction != null
        ? List.from(prediction.allFindings)
        : AppPathologies.list.map((m) {
            return PathologyItem(
              index: m.index,
              label: m.label,
              nameUz: m.nameUz,
              descriptionUz: m.descriptionUz,
              prob: 0.0,
              probPercent: 0.0,
              threshold: m.threshold,
              positive: false,
              riskCode: 'LOW',
              riskLevel: 'Kutilmoqda',
            );
          }).toList();

    // Sort items: positive first, then descending probability
    items.sort((a, b) {
      if (a.positive && !b.positive) return -1;
      if (!a.positive && b.positive) return 1;
      return b.prob.compareTo(a.prob);
    });

    final displayedItems = _onlyPositive
        ? items.where((p) => p.positive).toList()
        : items;

    final String? selectedTarget = provider.selectedPathologyLabel ??
        prediction?.gradcam?.targetLabel;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with count and filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: MedicalColors.surfaceElevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.analytics_outlined, color: MedicalColors.primaryCyan, size: 18),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '14 Ta Patologiya Ehtimolligi',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: MedicalColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (prediction != null && prediction.positiveFindings.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: MedicalColors.riskHigh.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: MedicalColors.riskHigh),
                        ),
                        child: Text(
                          '${prediction.positiveFindings.length} musbat',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: MedicalColors.riskHigh,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Threshold Tick Legend & Filter chips
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // Legend for vertical tick
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 2.5,
                          height: 12,
                          color: MedicalColors.thresholdTick,
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Kalibrlangan chegara',
                          style: TextStyle(fontSize: 10.5, color: MedicalColors.textSecondary),
                        ),
                      ],
                    ),
                    // Filter chip
                    ChoiceChip(
                      label: Text(
                        'Faqat musbat (${prediction?.positiveFindings.length ?? 0})',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: _onlyPositive ? Colors.black : MedicalColors.textSecondary,
                          fontWeight: _onlyPositive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: _onlyPositive,
                      selectedColor: MedicalColors.primaryCyan,
                      backgroundColor: MedicalColors.surface,
                      visualDensity: VisualDensity.compact,
                      onSelected: (val) {
                        setState(() {
                          _onlyPositive = val;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable list of pathology cards
          Expanded(
            child: displayedItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _onlyPositive
                            ? "Musbat patologiya aniqlanmadi (Norma)"
                            : "Patologiyalar ro'yxati bo'sh",
                        style: const TextStyle(color: MedicalColors.textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: displayedItems.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = displayedItems[index];
                      final bool isSelected = selectedTarget != null &&
                          selectedTarget.toLowerCase() == item.label.toLowerCase();

                      return PathologyCard(
                        item: item,
                        isSelected: isSelected,
                        isLoadingCam: provider.isSwitchingCam,
                        onTap: () {
                          // Tap triggers inspect GradCAM for this pathology
                          provider.inspectPathologyCam(item.label);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
