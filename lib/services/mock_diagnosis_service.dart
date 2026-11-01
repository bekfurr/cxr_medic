import 'dart:math';
import '../core/constants/pathology_constants.dart';
import '../core/constants/demo_assets.dart';
import '../core/constants/cdss_disclaimer.dart';
import '../models/pathology_item.dart';
import '../models/prediction_request.dart';
import '../models/prediction_response.dart';
import '../models/gradcam_data.dart';

class MockDiagnosisService {
  static Future<PredictionResponse> simulateDiagnosis(PredictionRequest request) async {
    // Realistic CDSS processing delay
    await Future.delayed(const Duration(milliseconds: 250));

    // Base calibrated findings with test mock probabilities
    // Emphysema (0.5636 > 0.46) and Cardiomegaly (0.3840 > 0.29) are positive
    final Map<String, double> mockProbabilities = {
      'Atelectasis': 0.1820,
      'Cardiomegaly': 0.3840,
      'Effusion': 0.2150,
      'Infiltration': 0.2640,
      'Mass': 0.0810,
      'Nodule': 0.1230,
      'Pneumonia': 0.1940,
      'Pneumothorax': 0.0420,
      'Consolidation': 0.1510,
      'Edema': 0.1430,
      'Emphysema': 0.5636,
      'Fibrosis': 0.1120,
      'Pleural_Thickening': 0.1650,
      'Hernia': 0.0240,
    };

    final List<PathologyItem> allFindings = [];
    final List<PathologyItem> positiveFindings = [];

    for (final meta in AppPathologies.list) {
      double prob = mockProbabilities[meta.label] ?? (meta.threshold * 0.4);
      // Slight variation based on age / gender if desired
      if (meta.label == 'Cardiomegaly' && request.age > 60) {
        prob = min(0.95, prob + 0.05);
      }

      final bool positive = prob >= meta.threshold;
      final double probPercent = double.parse((prob * 100).toStringAsFixed(1));

      String riskCode;
      String riskLevel;
      if (positive) {
        if (prob >= meta.threshold + 0.25) {
          riskCode = 'HIGH';
          riskLevel = 'Yuqori (Musbat)';
        } else {
          riskCode = 'MODERATE_HIGH';
          riskLevel = "O'rta-Yuqori (Musbat)";
        }
      } else {
        if (prob >= meta.threshold - 0.10) {
          riskCode = 'MODERATE_LOW';
          riskLevel = "O'rta-Quyi (Chegara)";
        } else {
          riskCode = 'LOW';
          riskLevel = 'Quyi (Manfiy)';
        }
      }

      final item = PathologyItem(
        index: meta.index,
        label: meta.label,
        nameUz: meta.nameUz,
        descriptionUz: meta.descriptionUz,
        prob: prob,
        probPercent: probPercent,
        threshold: meta.threshold,
        positive: positive,
        riskCode: riskCode,
        riskLevel: riskLevel,
      );

      allFindings.add(item);
      if (positive) {
        positiveFindings.add(item);
      }
    }

    // Sort positive findings descending by prob
    positiveFindings.sort((a, b) => b.prob.compareTo(a.prob));

    // Top findings
    final List<PathologyItem> topFindings = List.from(allFindings)
      ..sort((a, b) => b.prob.compareTo(a.prob));

    // Determine target label for Grad-CAM
    String targetLabel = request.targetLabel ??
        (positiveFindings.isNotEmpty ? positiveFindings.first.label : 'Emphysema');
    final targetMeta = AppPathologies.findByLabel(targetLabel) ?? AppPathologies.list[10];

    final String heatmapBase64 = DemoAssets.getHeatmapFor(targetLabel);
    final String originalClaheBase64 = (request.imageBase64.isNotEmpty && request.imageBase64.length > 500)
        ? request.imageBase64
        : DemoAssets.sampleCxrBase64;

    final gradcam = GradcamData(
      targetLabel: targetMeta.label,
      targetNameUz: targetMeta.nameUz,
      lungFocusRatio: 0.9142,
      originalClaheBase64: 'data:image/png;base64,$originalClaheBase64',
      overlayBase64: 'data:image/png;base64,$heatmapBase64',
      heatmapOnlyBase64: 'data:image/png;base64,$heatmapBase64',
    );

    final bool isNormal = positiveFindings.isEmpty;
    final String overallRisk = isNormal ? 'NORMAL' : (positiveFindings.length >= 2 ? 'HIGH' : 'MODERATE');
    final String clinicalSummary = isNormal
        ? "Norma: 14 ta asosiy o'pka patologiyasi bo'yicha me'yordan og'ish aniqlanmadi (Ishonch darajasi: 92.4%)."
        : "Diqqat: ${positiveFindings.length} ta ehtimoliy patologiya aniqlandi: "
            "${positiveFindings.map((e) => '${e.nameUz} (${e.probPercent}%)').join(', ')}. "
            "Klinik korrelyatsiya va rentgenolog maslahati tavsiya etiladi.";

    return PredictionResponse(
      status: 'success',
      requestId: 'mock_demo_${Random().nextInt(999999).toRadixString(16)}',
      inferenceMs: 84,
      isNormal: isNormal,
      noFindingConfidence: 0.4364,
      overallRisk: overallRisk,
      clinicalSummary: clinicalSummary,
      patientMeta: PatientMeta(
        viewPos: request.viewPos,
        age: request.age,
        gender: request.gender,
      ),
      positiveFindings: positiveFindings,
      topFindings: topFindings.take(4).toList(),
      allFindings: allFindings,
      gradcam: gradcam,
      disclaimer: CdssDisclaimer.shortFooterDisclaimerUz,
    );
  }
}

