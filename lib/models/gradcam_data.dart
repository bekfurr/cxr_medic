import 'dart:typed_data';
import '../core/utils/base64_helper.dart';

class GradcamData {
  final String? targetLabel;
  final String? targetNameUz;
  final double? lungFocusRatio;
  final String? originalClaheBase64;
  final String? overlayBase64;
  final String? heatmapOnlyBase64;

  final Uint8List? originalClaheBytes;
  final Uint8List? overlayBytes;
  final Uint8List? heatmapOnlyBytes;

  GradcamData({
    this.targetLabel,
    this.targetNameUz,
    this.lungFocusRatio,
    this.originalClaheBase64,
    this.overlayBase64,
    this.heatmapOnlyBase64,
    this.originalClaheBytes,
    this.overlayBytes,
    this.heatmapOnlyBytes,
  });

  factory GradcamData.fromJson(Map<String, dynamic> json) {
    final origB64 = json['original_clahe_base64']?.toString();
    final overB64 = json['overlay_base64']?.toString();
    final heatB64 = json['heatmap_only_base64']?.toString();

    return GradcamData(
      targetLabel: json['target_label']?.toString(),
      targetNameUz: json['target_name_uz']?.toString(),
      lungFocusRatio: (json['lung_focus_ratio'] is num)
          ? (json['lung_focus_ratio'] as num).toDouble()
          : null,
      originalClaheBase64: origB64,
      overlayBase64: overB64,
      heatmapOnlyBase64: heatB64,
      originalClaheBytes: Base64Helper.cleanDecode(origB64),
      overlayBytes: Base64Helper.cleanDecode(overB64),
      heatmapOnlyBytes: Base64Helper.cleanDecode(heatB64),
    );
  }
}

