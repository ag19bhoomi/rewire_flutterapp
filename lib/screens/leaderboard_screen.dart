import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_data_provider.dart';
import '../widgets/app_header.dart';

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
              child: Text("No subjects available."),
            )
                : ListView(
              padding: const EdgeInsets.all(16),
              children: subjectsData.entries.map((entry) {
                final subject = entry.key;
                final data = entry.value;
                final score = data['score'] ?? 0;
                final total = data['total'] ?? 1;
                final percent = ((score / total) * 100).toInt();

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
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
                          value: score / total,
                          backgroundColor: Colors.deepPurple[50],
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(height: 4),
                        Text("$percent%",
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: Text("$score / $total"),
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
