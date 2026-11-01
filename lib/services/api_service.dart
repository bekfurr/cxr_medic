import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/health_status.dart';
import '../models/prediction_request.dart';
import '../models/prediction_response.dart';

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  String _cleanUrl(String baseUrl, String path) {
    var base = baseUrl.trim();
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return '$base$path';
  }

  Future<HealthStatus> checkHealth(String baseUrl) async {
    final url = Uri.parse(_cleanUrl(baseUrl, '/api/v1/health'));
    try {
      final response = await _client.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return HealthStatus.fromJson(data);
      } else {
        throw Exception('Server holati xatosi (${response.statusCode}): ${response.body}');
      }
    } on TimeoutException {
      throw Exception("Serverga ulanish vaqti tugadi (8s timeout). URL to'g'riligini tekshiring.");
    } catch (e) {
      throw Exception('Serverga ulanib bo‘lmadi: $e');
    }
  }

  Future<PredictionResponse> predict(String baseUrl, PredictionRequest request) async {
    final url = Uri.parse(_cleanUrl(baseUrl, '/api/v1/predict'));
    try {
      final response = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return PredictionResponse.fromJson(data);
      } else {
        String errorMsg = 'Xatolik yuz berdi (${response.statusCode})';
        try {
          final errJson = jsonDecode(utf8.decode(response.bodyBytes));
          if (errJson['message'] != null) errorMsg = errJson['message'];
          if (errJson['error'] != null) errorMsg = errJson['error'];
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } on TimeoutException {
      throw Exception("Tahlil vaqti tugadi (45s timeout). Server yuklamasini tekshiring.");
    } catch (e) {
      throw Exception('Tahlil so‘rovi muvaffaqiyatsiz bo‘ldi: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

