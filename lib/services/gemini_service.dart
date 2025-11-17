import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:rewire_app/services/pdf_service.dart';

class GeminiService {
  // Load API key from .env
  static final String? _apiKey = dotenv.env['GEMINI_API_KEY'];

  // Use stable model
  static const String _modelName = "gemini-2.0-flash";

  // -------------------- SUMMARY --------------------
  static Future<String> generateSummary(String pdfPath) async {
    try {
      if (_apiKey == null || _apiKey!.isEmpty) {
        return "❌ GEMINI_API_KEY missing in .env";
      }

      // Extract raw text from PDF file
      final extractedText = await PdfService.extractText(pdfPath);

      if (extractedText.trim().isEmpty) {
        return "❌ PDF has no readable text.";
      }

      final model = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey!,
      );

      final prompt =
          "Summarize the following text in 80–120 words with clear points:\n$extractedText";

      final response = await model.generateContent([Content.text(prompt)]);

      return response.text ?? "❌ No summary generated.";
    } catch (e) {
      return "❌ Error generating summary: $e";
    }
  }

  // -------------------- QUIZ --------------------
  static Future<List<Map<String, dynamic>>> generateQuiz(String pdfPath) async {
    try {
      if (_apiKey == null || _apiKey!.isEmpty) {
        return _fallbackQuiz("Missing API key");
      }

      final extractedText = await PdfService.extractText(pdfPath);

      if (extractedText.trim().isEmpty) {
        return _fallbackQuiz("Empty PDF");
      }

      final model = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey!,
      );

      final prompt = """
Generate EXACTLY 5 multiple-choice questions (MCQs) from the given text.
Each question must have 4 options.
Return ONLY a valid JSON array in this format:

[
  {
    "question": "",
    "options": ["A", "B", "C", "D"],
    "correctIndex": 0
  }
]

Text:
$extractedText
""";

      final response = await model.generateContent([
        Content.text(prompt)
      ]);

      final reply = response.text ?? "";

      // Extract JSON from AI response
      final start = reply.indexOf('[');
      final end = reply.lastIndexOf(']');

      if (start == -1 || end == -1) {
        return _fallbackQuiz("JSON not found");
      }

      final jsonString = reply.substring(start, end + 1);

      final parsed = jsonDecode(jsonString);

      return List<Map<String, dynamic>>.from(parsed);
    } catch (e) {
      return _fallbackQuiz("Exception: $e");
    }
  }

  // -------------------- FALLBACK QUIZ --------------------
  static List<Map<String, dynamic>> _fallbackQuiz(String reason) {
    return [
      {
        "question": "Fallback question (Reason: $reason)",
        "options": ["A", "B", "C", "D"],
        "correctIndex": 0
      }
    ];
  }
}
