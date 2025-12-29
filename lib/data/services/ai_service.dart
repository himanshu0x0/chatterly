import 'dart:convert';
import 'package:chatterly/data/secrets.dart';
import 'package:http/http.dart' as http;

class AIService {
  static const String _baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";

  static final String _apiKey = Secrets.geminiApiKey;

  /// 🔹 Core function: Get AI response from Gemini
  static Future<String> getResponse(String message) async {
    if (_apiKey.isEmpty) {
      return "⚠️ API key missing. Please check your secrets.dart file.";
    }

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl?key=$_apiKey"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": message}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
        return text?.trim() ?? "⚠️ No response from Gemini.";
      } else if (response.statusCode == 401) {
        return "⚠️ Unauthorized. Check your API key (401).";
      } else {
        return "⚠️ API Error ${response.statusCode}: ${response.body}";
      }
    } catch (e) {
      return "⚠️ Connection failed: $e";
    }
  }

  /// 🔹 Summarize text
  static Future<String> summarize(String text) async {
    final prompt = "Summarize this text in short points:\n\n$text";
    return await getResponse(prompt);
  }

  /// 🔹 Translate text
  static Future<String> translate(String text, String language) async {
    final prompt = "Translate this into $language:\n\n$text";
    return await getResponse(prompt);
  }

  /// 🔹 Explain code
  static Future<String> explainCode(String code) async {
    final prompt = "Explain this code step by step:\n\n$code";
    return await getResponse(prompt);
  }

  /// 🔹 Creative response (story/poem mode)
  static Future<String> creativeReply(String topic) async {
    final prompt =
        "Write a short, creative piece (story or poem) about:\n\n$topic";
    return await getResponse(prompt);
  }
}
