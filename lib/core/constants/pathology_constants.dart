/// 14 Pathologies calibrated for BMI CXRNetV2 DenseNet-121 multimodal model.
/// Test Macro-AUROC = 0.777.
/// Validation calibrated decision thresholds.
class PathologyMetadata {
  final int index;
  final String label;
  final String nameUz;
  final String nameEn;
  final String descriptionUz;
  final double threshold;

  const PathologyMetadata({
    required this.index,
    required this.label,
    required this.nameUz,
    required this.nameEn,
    required this.descriptionUz,
    required this.threshold,
  });
}

class AppPathologies {
  static const List<PathologyMetadata> list = [
    PathologyMetadata(
      index: 0,
      label: 'Atelectasis',
      nameUz: 'Atelektaz',
      nameEn: 'Atelectasis',
      descriptionUz: "O'pka to'qimasining kollapsi yoki qulashi, havosizlanishi.",
      threshold: 0.44,
    ),
    PathologyMetadata(
      index: 1,
      label: 'Cardiomegaly',
      nameUz: 'Kardiomegaliya',
      nameEn: 'Cardiomegaly',
      descriptionUz: "Yurak o'lchamlarining me'yordan sezilarli kattalashishi (KTI > 0.50).",
      threshold: 0.29,
    ),
    PathologyMetadata(
      index: 2,
      label: 'Effusion',
      nameUz: 'Plevral effuziya',
      nameEn: 'Pleural Effusion',
      descriptionUz: "Plevra bo'shlig'ida patologik suyuqlik to'planishi, sinuslar berkilishi.",
      threshold: 0.48,
    ),
    PathologyMetadata(
      index: 3,
      label: 'Infiltration',
      nameUz: 'Infiltratsiya',
      nameEn: 'Infiltration',
      descriptionUz: "O'pka parenximasida yallig'lanish yoki oqsil/hujayra to'planishi.",
      threshold: 0.45,
    ),
    PathologyMetadata(
      index: 4,
      label: 'Mass',
      nameUz: 'Hajmli hosila (Mass)',
      nameEn: 'Mass (>3cm)',
      descriptionUz: "O'pka sohasida 3 sm dan katta patologik zich hosila.",
      threshold: 0.39,
    ),
    PathologyMetadata(
      index: 5,
      label: 'Nodule',
      nameUz: 'Tugun (Nodule)',
      nameEn: 'Nodule (≤3cm)',
      descriptionUz: "O'pka maydonida 3 sm gacha bo'lgan aylana/tuxumsimon zichlik.",
      threshold: 0.42,
    ),
    PathologyMetadata(
      index: 6,
      label: 'Pneumonia',
      nameUz: 'Pnevmoniya',
      nameEn: 'Pneumonia',
      descriptionUz: "O'pka to'qimasining o'tkir yuqumli yallig'lanish o'chog'i.",
      threshold: 0.25,
    ),
    PathologyMetadata(
      index: 7,
      label: 'Pneumothorax',
      nameUz: 'Pnevmotoraks',
      nameEn: 'Pneumothorax',
      descriptionUz: "Plevra bo'shlig'ida erkin havo to'planishi va o'pka siqilishi.",
      threshold: 0.41,
    ),
    PathologyMetadata(
      index: 8,
      label: 'Consolidation',
      nameUz: 'Konsolidatsiya',
      nameEn: 'Consolidation',
      descriptionUz: "Alveolalarning havo o'rniga ekssudat bilan to'lishi (zichlashuv).",
      threshold: 0.40,
    ),
    PathologyMetadata(
      index: 9,
      label: 'Edema',
      nameUz: "O'pka shishi",
      nameEn: 'Pulmonary Edema',
      descriptionUz: "O'pka qon tomirlaridan to'qimalarga suyuqlik sizib chiqishi (dimlanish).",
      threshold: 0.33,
    ),
    PathologyMetadata(
      index: 10,
      label: 'Emphysema',
      nameUz: 'Emfizema',
      nameEn: 'Emphysema',
      descriptionUz: "Alveola devorlarining yemirilishi va o'pkaning me'yordan ortiq shishishi.",
      threshold: 0.46,
    ),
    PathologyMetadata(
      index: 11,
      label: 'Fibrosis',
      nameUz: 'Fibroz',
      nameEn: 'Fibrosis',
      descriptionUz: "O'pka to'qimasining chandiqlanishi va elastikligining pasayishi.",
      threshold: 0.28,
    ),
    PathologyMetadata(
      index: 12,
      label: 'Pleural_Thickening',
      nameUz: 'Plevra qalinlashuvi',
      nameEn: 'Pleural Thickening',
      descriptionUz: "Plevra varaqlarining fibroz yoki yallig'lanish tufayli qalinlashishi.",
      threshold: 0.36,
    ),
    PathologyMetadata(
      index: 13,
      label: 'Hernia',
      nameUz: 'Diafragma churrasi',
      nameEn: 'Hiatal / Diaphragmatic Hernia',
      descriptionUz: "Qorin bo'shlig'i a'zolarining ko'krak qafasiga surilishi.",
      threshold: 0.13,
    ),
  ];

  static PathologyMetadata? findByLabel(String label) {
    for (final item in list) {
      if (item.label.toLowerCase() == label.toLowerCase()) {
        return item;
      }
    }
    return null;
  }
}

