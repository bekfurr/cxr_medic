import 'dart:convert';
import 'dart:typed_data';

class Base64Helper {
  /// Strips any data URI prefix (e.g., "data:image/png;base64,") and decodes raw base64 string to Uint8List.
  static Uint8List? cleanDecode(String? base64Str) {
    if (base64Str == null || base64Str.trim().isEmpty) return null;
    try {
      var clean = base64Str.trim();
      if (clean.contains(',')) {
        clean = clean.split(',').last;
      }
      // Remove any whitespace or newline
      clean = clean.replaceAll(RegExp(r'\s+'), '');
      return base64Decode(clean);
    } catch (e) {
      // In case of invalid padding or corrupt string, attempt repair or return null
      return null;
    }
  }

  /// Encodes raw Uint8List bytes into clean base64 string without data URI prefix.
  static String cleanEncode(Uint8List bytes) {
    return base64Encode(bytes);
  }
}

