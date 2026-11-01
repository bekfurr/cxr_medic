class PredictionRequest {
  final String imageBase64;
  final String viewPos; // "PA" or "AP"
  final int age;
  final String gender; // "M" or "F"
  final bool withCam;
  final String? targetLabel;
  final String lang; // "uz"

  PredictionRequest({
    required this.imageBase64,
    this.viewPos = 'PA',
    this.age = 50,
    this.gender = 'M',
    this.withCam = true,
    this.targetLabel,
    this.lang = 'uz',
  });

  Map<String, dynamic> toJson() {
    return {
      'image_base64': imageBase64,
      'view_pos': viewPos,
      'age': age,
      'gender': gender,
      'with_cam': withCam,
      'target_label': targetLabel,
      'lang': lang,
    };
  }
}

