// suggestion_service.dart
class SuggestionService {
  /// Returns a study suggestion based on the user's quiz score.
  static String getSuggestion(int score) {
    if (score < 40) {
      return "Your fundamentals need strengthening. Revisit the summary and revise the key concepts. Try retaking the quiz after revision.";
    }
    else if (score >= 40 && score < 70) {
      return "Good attempt! You’re improving. Review the questions you got wrong and practice one more quiz to boost your understanding.";
    }
    else if (score >= 70 && score < 90) {
      return "Great work! You have a solid understanding. You can move ahead to the next topic or chapter confidently.";
    }
    else {
      return "Excellent performance! You're mastering this subject. Maintain consistency and revise once every few days for long-term retention.";
    }
  }
}
