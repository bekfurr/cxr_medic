import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/medical_theme.dart';
import '../providers/cdss_provider.dart';

class XrayViewport extends StatefulWidget {
  const XrayViewport({super.key});

  @override
  State<XrayViewport> createState() => _XrayViewportState();
}

class _XrayViewportState extends State<XrayViewport> {
  final TransformationController _transController = TransformationController();

  void _resetZoom() {
    _transController.value = Matrix4.identity();
  }

  void _zoomIn() {
    final current = _transController.value.clone();
    final scale = current.getMaxScaleOnAxis();
    if (scale < 4.0) {
      current.scaleByDouble(1.3, 1.3, 1.0, 1.0);
      _transController.value = current;
    }
  }

  void _zoomOut() {
    final current = _transController.value.clone();
    final scale = current.getMaxScaleOnAxis();
    if (scale > 0.8) {
      current.scaleByDouble(0.77, 0.77, 1.0, 1.0);
      _transController.value = current;
    }
  }

  @override
  void dispose() {
    _transController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CdssProvider>();
    final Uint8List? rawBytes = provider.selectedImageBytes;
    final gradcam = provider.prediction?.gradcam;
    final Uint8List? claheBytes = gradcam?.originalClaheBytes ?? rawBytes;
    final Uint8List? heatmapBytes = gradcam?.heatmapOnlyBytes;
    final bool hasHeatmap = heatmapBytes != null && heatmapBytes.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header toolbar with Target Disease tag, Lung Focus Ratio, and Zoom controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: MedicalColors.surfaceElevated,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                // Active Target Label badge
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lens_blur_rounded, color: MedicalColors.primaryCyan, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      gradcam != null
                          ? 'Grad-CAM++: ${gradcam.targetNameUz ?? gradcam.targetLabel}'
                          : 'Rentgenogramma Ko‘rinishi',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: MedicalColors.textPrimary,
                      ),
                    ),
                    if (provider.isSwitchingCam) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: MedicalColors.primaryCyan,
                        ),
                      ),
                    ],
                  ],
                ),

                // Secondary badges and zoom tools
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (gradcam?.lungFocusRatio != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: MedicalColors.primaryCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: MedicalColors.primaryCyan.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          "O'pka fokusi: ${(gradcam!.lungFocusRatio! * 100).toStringAsFixed(1)}%",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: MedicalColors.primaryCyan,
                          ),
                        ),
                      ),

                    // Zoom / Pan toolbar
                    Container(
                      decoration: BoxDecoration(
                        color: MedicalColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: MedicalColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.zoom_in, size: 18),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            tooltip: "Kattalashtirish",
                            onPressed: _zoomIn,
                          ),
                          IconButton(
                            icon: const Icon(Icons.zoom_out, size: 18),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            tooltip: "Kichraytirish",
                            onPressed: _zoomOut,
                          ),
                          IconButton(
                            icon: const Icon(Icons.restart_alt, size: 18),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            tooltip: "O'lchamni tiklash",
                            onPressed: _resetZoom,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Viewport Canvas (InteractiveViewer with dual-layer blending)
          Expanded(
            child: Container(
              color: Colors.black,
              child: claheBytes == null
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image_search_rounded, size: 54, color: MedicalColors.textMuted),
                          SizedBox(height: 12),
                          Text(
                            "Rentgen tasviri tanlanmagan",
                            style: TextStyle(color: MedicalColors.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ClipRect(
                      child: InteractiveViewer(
                        transformationController: _transController,
                        minScale: 0.5,
                        maxScale: 5.0,
                        boundaryMargin: const EdgeInsets.all(64),
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Layer 1: Base CLAHE / Original CXR image
                              Image.memory(
                                claheBytes,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 320,
                                  height: 320,
                                  color: Colors.black,
                                  child: const Center(
                                    child: Text(
                                      'Tasvirni yuklashda xatolik',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ),

                              // Layer 2: Real-time Opacity Blended Grad-CAM++ Heatmap
                              if (hasHeatmap)
                                Opacity(
                                  opacity: provider.gradcamOpacity,
                                  child: Image.memory(
                                    heatmapBytes,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          // Bottom Grad-CAM++ Opacity Slider Controller
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: MedicalColors.surfaceElevated,
              border: Border(top: BorderSide(color: MedicalColors.border)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.opacity_rounded,
                  size: 18,
                  color: MedicalColors.primaryCyan,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Grad-CAM++',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: MedicalColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${(provider.gradcamOpacity * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: MedicalColors.primaryCyan,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: provider.gradcamOpacity,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    label: '${(provider.gradcamOpacity * 100).toInt()}%',
                    onChanged: hasHeatmap ? (val) => provider.setGradcamOpacity(val) : null,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(40, 28),
                  ),
                  onPressed: hasHeatmap
                      ? () {
                          provider.setGradcamOpacity(
                            provider.gradcamOpacity > 0.05 ? 0.0 : 0.65,
                          );
                        }
                      : null,
                  child: Text(
                    provider.gradcamOpacity > 0.05 ? 'Yashirish' : 'Ko‘rsatish',
                    style: const TextStyle(fontSize: 11, color: MedicalColors.primaryCyan),
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
