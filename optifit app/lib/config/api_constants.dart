import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // Gemini API configuration (new primary API)
  static const String geminiApiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  static final String geminiApiKey = dotenv.env['GEMINI_API_KEY']!;

  // New: Centralized endpoint for chat functionalities
  static const String chatApiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  // API endpoints for squat analysis server
  static final String squatServerUpload =
      '${dotenv.env['NGROK_FORWARDING_URL']!}/upload';
  static final String squatServerResult =
      '${dotenv.env['NGROK_FORWARDING_URL']!}/result';

  // API headers for Gemini
  static Map<String, String> get geminiHeaders => {
    'Content-Type': 'application/json',
    'x-goog-api-key': geminiApiKey,
  };
}
