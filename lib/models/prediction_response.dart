import 'pathology_item.dart';
import 'gradcam_data.dart';

class PatientMeta {
  final String viewPos;
  final int age;
  final String gender;

  PatientMeta({
    required this.viewPos,
    required this.age,
    required this.gender,
  });

  factory PatientMeta.fromJson(Map<String, dynamic> json) {
    return PatientMeta(
      viewPos: json['view_pos']?.toString() ?? 'PA',
      age: json['age'] is num ? (json['age'] as num).toInt() : 50,
      gender: json['gender']?.toString() ?? 'M',
    );
  }
}

class PredictionResponse {
  final String status;
  final String? requestId;
  final int inferenceMs;
  final bool isNormal;
  final double noFindingConfidence;
  final String overallRisk;
  final String clinicalSummary;
  final PatientMeta? patientMeta;
  final List<PathologyItem> positiveFindings;
  final List<PathologyItem> topFindings;
  final List<PathologyItem> allFindings;
  final GradcamData? gradcam;
  final String? disclaimer;

  PredictionResponse({
    required this.status,
    this.requestId,
    this.inferenceMs = 0,
    required this.isNormal,
    this.noFindingConfidence = 0.0,
    required this.overallRisk,
    required this.clinicalSummary,
    this.patientMeta,
    required this.positiveFindings,
    required this.topFindings,
    required this.allFindings,
    this.gradcam,
    this.disclaimer,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    final List<PathologyItem> allList = [];
    if (json['all_findings'] is List) {
      for (final item in json['all_findings']) {
        if (item is Map<String, dynamic>) {
          allList.add(PathologyItem.fromJson(item));
        }
      }
    }

    final List<PathologyItem> posList = [];
    if (json['positive_findings'] is List) {
      for (final item in json['positive_findings']) {
        if (item is Map<String, dynamic>) {
          posList.add(PathologyItem.fromJson(item));
        }
      }
    }

    final List<PathologyItem> topList = [];
    if (json['top_findings'] is List) {
      for (final item in json['top_findings']) {
        if (item is Map<String, dynamic>) {
          topList.add(PathologyItem.fromJson(item));
        }
      }
    }

    return PredictionResponse(
      status: json['status']?.toString() ?? 'success',
      requestId: json['request_id']?.toString(),
      inferenceMs: json['inference_ms'] is num ? (json['inference_ms'] as num).toInt() : 0,
      isNormal: json['is_normal'] == true,
      noFindingConfidence: (json['no_finding_confidence'] is num)
          ? (json['no_finding_confidence'] as num).toDouble()
          : 0.0,
      overallRisk: json['overall_risk']?.toString() ?? (posList.isNotEmpty ? 'HIGH' : 'LOW'),
      clinicalSummary: json['clinical_summary']?.toString() ?? '',
      patientMeta: json['patient_meta'] is Map<String, dynamic>
          ? PatientMeta.fromJson(json['patient_meta'] as Map<String, dynamic>)
          : null,
      positiveFindings: posList,
      topFindings: topList,
      allFindings: allList,
      gradcam: json['gradcam'] is Map<String, dynamic>
          ? GradcamData.fromJson(json['gradcam'] as Map<String, dynamic>)
          : null,
      disclaimer: json['disclaimer']?.toString(),
    );
  }
}

