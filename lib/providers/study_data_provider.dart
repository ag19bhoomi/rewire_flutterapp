import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudyDataProvider extends ChangeNotifier {
  /// Stores each subject's quiz data:
  /// {
  ///   'Python': {'score': 3, 'total': 5},
  ///   'DSA': {'score': 4, 'total': 5},
  /// }
  Map<String, Map<String, dynamic>> _subjectsData = {};

  StudyDataProvider() {
    _init();
  }

  /// Initialize provider (loads saved quiz data)
  Future<void> _init() async {
    await _loadSavedScores();
  }

  /// 📊 Get all subjects with their quiz scores
  Map<String, Map<String, dynamic>> get allSubjectsWithScores => _subjectsData;

  /// ✅ Backward-compatible method (for other screens)
  Map<String, Map<String, dynamic>> getAllSubjectsWithScores() => _subjectsData;

  /// 🎯 Get quiz score for a specific subject
  Map<String, dynamic>? getScoreForSubject(String subject) =>
      _subjectsData[subject];

  /// 🧩 Update or add a subject’s quiz score
  Future<void> updateQuizScore(String subject, int correct, int total) async {
    if (subject.trim().isEmpty) return;

    _subjectsData[subject] = {
      'score': correct,
      'total': total,
    };

    await _saveScores();
    notifyListeners();

    if (kDebugMode) {
      print("✅ Updated quiz score → $subject: $correct / $total");
    }
  }

  /// 💾 Save quiz scores to SharedPreferences
  Future<void> _saveScores() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedData = jsonEncode(_subjectsData);
    await prefs.setString('quizScores', encodedData);

    if (kDebugMode) {
      print("💾 Saved quiz data → $encodedData");
    }
  }

  /// 🔁 Load saved quiz data from SharedPreferences
  Future<void> _loadSavedScores() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString('quizScores');

    if (dataString == null) {
      _subjectsData = {};
      return;
    }

    try {
      final decoded = jsonDecode(dataString) as Map<String, dynamic>;
      _subjectsData = decoded.map(
            (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
      );

      if (kDebugMode) {
        print("📂 Loaded quiz data → $_subjectsData");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error decoding saved scores: $e");
      }
      _subjectsData = {};
    }

    notifyListeners();
  }

  /// 🗑️ Delete a specific subject’s quiz data
  Future<void> deleteSubject(String subject) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Remove stored quiz score & total
    if (_subjectsData.containsKey(subject)) {
      _subjectsData.remove(subject);
    }

    // 2. Remove local SharedPreferences score and summary (IMPORTANT FIX)
    await prefs.remove('${subject}_score');
    await prefs.remove('${subject}_summary');

    // 3. Save updated map
    await _saveScores();

    notifyListeners();

    if (kDebugMode) {
      print("🗑️ Completely removed subject → $subject");
    }
  }

  /// 🧹 Clear all saved quiz scores
  Future<void> clearAllScores() async {
    _subjectsData.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('quizScores');
    notifyListeners();

    if (kDebugMode) {
      print("🧹 All quiz scores cleared");
    }
  }
}
