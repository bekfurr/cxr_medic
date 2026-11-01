import 'package:flutter/foundation.dart';
import '../core/constants/demo_assets.dart';
import '../core/utils/base64_helper.dart';
import '../models/health_status.dart';
import '../models/prediction_request.dart';
import '../models/prediction_response.dart';
import '../services/api_service.dart';
import '../services/mock_diagnosis_service.dart';
import '../services/storage_service.dart';

class CdssProvider extends ChangeNotifier {
  final StorageService storageService;
  final ApiService _apiService;

  CdssProvider({
    required this.storageService,
    ApiService? apiService,
  })  : _apiService = apiService ?? ApiService() {
    _serverUrl = storageService.getServerUrl();
    _offlineDemoMode = storageService.getOfflineDemoMode();
    _isDisclaimerAccepted = storageService.isDisclaimerAccepted();
  }

  // State variables
  late String _serverUrl;
  late bool _offlineDemoMode;
  late bool _isDisclaimerAccepted;

  Uint8List? _selectedImageBytes;
  String _selectedImageName = 'Namuna Rentgen (Demo)';
  String _viewPos = 'PA';
  int _age = 58;
  String _gender = 'M';

  bool _isCheckingConnection = false;
  bool _isConnected = false;
  HealthStatus? _healthStatus;

  bool _isLoading = false;
  bool _isSwitchingCam = false;
  PredictionResponse? _prediction;
  String? _selectedPathologyLabel;
  double _gradcamOpacity = 0.65;
  String? _errorMessage;

  // Getters
  String get serverUrl => _serverUrl;
  bool get offlineDemoMode => _offlineDemoMode;
  bool get isDisclaimerAccepted => _isDisclaimerAccepted;
  Uint8List? get selectedImageBytes => _selectedImageBytes;
  String get selectedImageName => _selectedImageName;
  String get viewPos => _viewPos;
  int get age => _age;
  String get gender => _gender;

  bool get isCheckingConnection => _isCheckingConnection;
  bool get isConnected => _isConnected;
  HealthStatus? get healthStatus => _healthStatus;

  bool get isLoading => _isLoading;
  bool get isSwitchingCam => _isSwitchingCam;
  PredictionResponse? get prediction => _prediction;
  String? get selectedPathologyLabel => _selectedPathologyLabel;
  double get gradcamOpacity => _gradcamOpacity;
  String? get errorMessage => _errorMessage;

  // Initialization
  Future<void> init() async {
    // Load default sample radiograph in memory
    _selectedImageBytes = Base64Helper.cleanDecode(DemoAssets.sampleCxrBase64);
    notifyListeners();

    if (!_offlineDemoMode) {
      await checkServerHealth();
    }
  }

  Future<void> setDisclaimerAccepted(bool accepted) async {
    _isDisclaimerAccepted = accepted;
    await storageService.setDisclaimerAccepted(accepted);
    notifyListeners();
  }

  Future<void> setServerUrl(String url) async {
    _serverUrl = url.trim();
    await storageService.setServerUrl(_serverUrl);
    notifyListeners();
    await checkServerHealth();
  }

  Future<void> setOfflineDemoMode(bool enabled) async {
    _offlineDemoMode = enabled;
    await storageService.setOfflineDemoMode(enabled);
    _errorMessage = null;
    notifyListeners();
    if (!_offlineDemoMode) {
      await checkServerHealth();
    }
  }

  Future<void> checkServerHealth() async {
    _isCheckingConnection = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _healthStatus = await _apiService.checkHealth(_serverUrl);
      _isConnected = true;
    } catch (e) {
      _isConnected = false;
      _healthStatus = null;
      // Connection failure can quietly inform or switch to offline suggestion
    } finally {
      _isCheckingConnection = false;
      notifyListeners();
    }
  }

  void setPatientMeta({String? viewPos, int? age, String? gender}) {
    if (viewPos != null) _viewPos = viewPos;
    if (age != null) _age = age;
    if (gender != null) _gender = gender;
    notifyListeners();
  }

  void setImageBytes(Uint8List bytes, String name) {
    _selectedImageBytes = bytes;
    _selectedImageName = name;
    _prediction = null;
    _selectedPathologyLabel = null;
    _errorMessage = null;
    notifyListeners();
  }

  void loadSampleRadiograph() {
    _selectedImageBytes = Base64Helper.cleanDecode(DemoAssets.sampleCxrBase64);
    _selectedImageName = 'Namuna Rentgen (PA 58Y M)';
    _viewPos = 'PA';
    _age = 58;
    _gender = 'M';
    _prediction = null;
    _selectedPathologyLabel = null;
    _errorMessage = null;
    notifyListeners();
  }

  void setGradcamOpacity(double opacity) {
    _gradcamOpacity = opacity.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Runs CDSS diagnosis.
  /// If targetLabel is provided, queries Grad-CAM for that specific pathology.
  Future<void> runDiagnosis({String? targetLabel}) async {
    if (_selectedImageBytes == null) {
      _errorMessage = "Iltimos, avval rentgen tasvirini yuklang.";
      notifyListeners();
      return;
    }

    if (targetLabel != null) {
      _isSwitchingCam = true;
    } else {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    final imageB64 = Base64Helper.cleanEncode(_selectedImageBytes!);
    final request = PredictionRequest(
      imageBase64: imageB64,
      viewPos: _viewPos,
      age: _age,
      gender: _gender,
      withCam: true,
      targetLabel: targetLabel,
      lang: 'uz',
    );

    try {
      PredictionResponse response;
      if (_offlineDemoMode || !_isConnected) {
        // Fallback to offline calibrated mock service
        response = await MockDiagnosisService.simulateDiagnosis(request);
      } else {
        try {
          response = await _apiService.predict(_serverUrl, request);
        } catch (serverErr) {
          // Fallback to offline demo if server request fails
          _errorMessage = "Serverga ulanishda xatolik yuz berdi. Oflayn rejim natijalari ko'rsatilmoqda: $serverErr";
          response = await MockDiagnosisService.simulateDiagnosis(request);
        }
      }

      _prediction = response;
      _selectedPathologyLabel = response.gradcam?.targetLabel ?? targetLabel;
    } catch (e) {
      _errorMessage = "Tahlil jarayonida kutilmagan xatolik: $e";
    } finally {
      _isLoading = false;
      _isSwitchingCam = false;
      notifyListeners();
    }
  }

  /// Tapping any pathology card triggers re-query with target_label for Grad-CAM++
  Future<void> inspectPathologyCam(String label) async {
    if (_prediction == null) return;
    if (_selectedPathologyLabel == label && _prediction?.gradcam != null) return;
    await runDiagnosis(targetLabel: label);
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
