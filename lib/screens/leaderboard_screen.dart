import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_data_provider.dart';
import '../widgets/app_header.dart';
import 'package:rewire_app/services/suggestion_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final studyData = Provider.of<StudyDataProvider>(context);
    final subjectsData = studyData.getAllSubjectsWithScores();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const AppHeader(title: "Leaderboard 🏆"),
          Expanded(
            child: subjectsData.isEmpty
                ? const Center(
              child: Text(
                "No subjects available.",
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            )
                : ListView(
              padding: const EdgeInsets.all(16),
              children: subjectsData.entries.map((entry) {
                final subject = entry.key;
                final data = entry.value;

                // Convert to double first
                final score = (data['score'] ?? 0).toDouble();
                final total = (data['total'] ?? 0).toDouble();

                // Avoid division by zero
                final progress = total > 0 ? (score / total) : 0.0;
                final percent = (progress * 100).toInt();

                // Convert score to int for SuggestionService
                final scoreInt = score.toInt();

                // Get suggestion for this subject
                final suggestion = SuggestionService.getSuggestion(scoreInt);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple[100],
                      child: Text(
                        subject[0].toUpperCase(),
                        style: const TextStyle(color: Colors.deepPurple),
                      ),
                    ),
                    title: Text(subject),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: Colors.deepPurple[50],
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$percent%",
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        // Display suggestion
                        Text(
                          suggestion,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    trailing: Text("$scoreInt / ${total.toInt()}"),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
