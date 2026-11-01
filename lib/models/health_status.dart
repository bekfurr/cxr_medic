import 'pathology_item.dart';

class HealthStatus {
  final String status;
  final String version;
  final String device;
  final int imgSize;
  final List<PathologyItem> pathologies;

  HealthStatus({
    required this.status,
    required this.version,
    required this.device,
    required this.imgSize,
    required this.pathologies,
  });

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    final List<PathologyItem> paths = [];
    if (json['pathologies'] is List) {
      for (final p in json['pathologies']) {
        if (p is Map<String, dynamic>) {
          paths.add(PathologyItem.fromJson(p));
        }
      }
    }
    return HealthStatus(
      status: json['status']?.toString() ?? 'healthy',
      version: json['version']?.toString() ?? 'BMI_CXR_multilabel_v2',
      device: json['device']?.toString() ?? 'cpu',
      imgSize: json['img_size'] is num ? (json['img_size'] as num).toInt() : 320,
      pathologies: paths,
    );
  }
}

