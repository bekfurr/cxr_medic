class PathologyItem {
  final int index;
  final String label;
  final String nameUz;
  final String descriptionUz;
  final double prob;
  final double probPercent;
  final double threshold;
  final bool positive;
  final String riskCode;
  final String riskLevel;

  PathologyItem({
    required this.index,
    required this.label,
    required this.nameUz,
    required this.descriptionUz,
    required this.prob,
    required this.probPercent,
    required this.threshold,
    required this.positive,
    required this.riskCode,
    required this.riskLevel,
  });

  factory PathologyItem.fromJson(Map<String, dynamic> json) {
    final double rawProb = (json['prob'] is num) ? (json['prob'] as num).toDouble() : 0.0;
    final double rawThresh = (json['threshold'] is num) ? (json['threshold'] as num).toDouble() : 0.5;
    final double rawPercent = (json['prob_percent'] is num)
        ? (json['prob_percent'] as num).toDouble()
        : (rawProb * 100.0);

    return PathologyItem(
      index: json['index'] is int ? json['index'] as int : 0,
      label: json['label']?.toString() ?? '',
      nameUz: json['name_uz']?.toString() ?? json['label']?.toString() ?? '',
      descriptionUz: json['description_uz']?.toString() ?? '',
      prob: rawProb,
      probPercent: rawPercent,
      threshold: rawThresh,
      positive: json['positive'] == true || (rawProb >= rawThresh),
      riskCode: json['risk_code']?.toString() ?? (rawProb >= rawThresh ? 'HIGH' : 'LOW'),
      riskLevel: json['risk_level']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'label': label,
      'name_uz': nameUz,
      'description_uz': descriptionUz,
      'prob': prob,
      'prob_percent': probPercent,
      'threshold': threshold,
      'positive': positive,
      'risk_code': riskCode,
      'risk_level': riskLevel,
    };
  }
}

