import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // Gemini API configuration (new primary API)
  static const String geminiApiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static final String geminiApiKey = dotenv.env['GEMINI_API_KEY']!;

  static const String chatApiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  // WORKING: Your exercise detection server (local ip v4 address used)
  static const String exerciseServerUpload = 'http://127.0.0.0:5000/upload';
  static const String exerciseServerResult = 'http://127.0.0.0:5000/result';

  static const String pushupServerUpload = exerciseServerUpload;
  static const String pushupServerResult = exerciseServerResult;
  static const String squatServerUpload = exerciseServerUpload;
  static const String squatServerResult = exerciseServerResult;

  // API headers for Gemini
  static Map<String, String> get geminiHeaders => {'Content-Type': 'application/json', 'x-goog-api-key': geminiApiKey};
}
