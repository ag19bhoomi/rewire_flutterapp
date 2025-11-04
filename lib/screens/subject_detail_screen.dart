import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/study_data_provider.dart';

class SubjectDetailScreen extends StatefulWidget {
  final String subjectName;
  final String? pdfPath;

  const SubjectDetailScreen({
    Key? key,
    required this.subjectName,
    this.pdfPath,
  }) : super(key: key);

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  List<Map<String, dynamic>>? _quiz;
  Map<int, int> _selectedAnswers = {};
  int? _score;
  String? _summary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedScore = prefs.getInt('${widget.subjectName}_score');
    final savedSummary = prefs.getString('${widget.subjectName}_summary');

    setState(() {
      _score = savedScore;
      _summary = savedSummary;
    });
  }

  /// 🧠 Generate short summary (around 30 words)
  Future<void> _generateSummary() async {
    const pythonSummary =
        "Python is a high-level, interpreted language known for its readability, versatility, and vast libraries. It’s widely used for web development, data science, AI, automation, and scripting.";

    setState(() => _summary = pythonSummary);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${widget.subjectName}_summary', pythonSummary);
  }

  /// 📚 Generate Python-based quiz
  void _generateQuiz() {
    setState(() {
      _quiz = [
        {
          "question": "1️⃣ What is Python primarily used for?",
          "options": [
            "Web development",
            "Machine learning",
            "Data analysis",
            "All of the above"
          ],
          "correctIndex": 3,
        },
        {
          "question": "2️⃣ Who developed Python?",
          "options": [
            "James Gosling",
            "Guido van Rossum",
            "Dennis Ritchie",
            "Bjarne Stroustrup"
          ],
          "correctIndex": 1,
        },
        {
          "question": "3️⃣ Which of the following is a mutable data type in Python?",
          "options": ["Tuple", "String", "List", "Set"],
          "correctIndex": 2,
        },
        {
          "question": "4️⃣ What symbol is used for comments in Python?",
          "options": ["//", "/* */", "#", "--"],
          "correctIndex": 2,
        },
        {
          "question": "5️⃣ Which keyword is used to define a function in Python?",
          "options": ["func", "define", "def", "lambda"],
          "correctIndex": 2,
        },
      ];
      _selectedAnswers.clear();
      _score = null;
    });
  }

  /// 🧮 Calculate and save score
  Future<void> _submitQuiz() async {
    if (_quiz == null) return;

    int score = 0;
    for (int i = 0; i < _quiz!.length; i++) {
      if (_selectedAnswers[i] == _quiz![i]['correctIndex']) {
        score++;
      }
    }

    setState(() => _score = score);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${widget.subjectName}_score', score);

    // ✅ Update global StudyDataProvider for Leaderboard
    final provider = Provider.of<StudyDataProvider>(context, listen: false);
    provider.updateQuizScore(widget.subjectName, score, _quiz!.length);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ You scored $score / ${_quiz!.length}!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.subjectName),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ Generate Summary button
            ElevatedButton.icon(
              icon: const Icon(Icons.summarize, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _generateSummary,
              label: const Text("Generate Summary",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            const SizedBox(height: 10),

            // ✅ Generate Quiz button
            ElevatedButton.icon(
              icon: const Icon(Icons.quiz, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _generateQuiz,
              label: const Text("Generate Quiz",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),

            const SizedBox(height: 20),

            // ✅ Show Summary
            if (_summary != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "📘 Summary:",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _summary!,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // ✅ Show Quiz
            if (_quiz != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "🧠 Python Quiz:",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple),
                  ),
                  const SizedBox(height: 10),
                  ..._quiz!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final q = entry.value;
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q['question'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(q['options'].length, (optIndex) {
                              return RadioListTile<int>(
                                value: optIndex,
                                groupValue: _selectedAnswers[index],
                                activeColor: Colors.deepPurple,
                                title: Text(q['options'][optIndex]),
                                onChanged: (val) {
                                  setState(() =>
                                  _selectedAnswers[index] = val ?? 0);
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _submitQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Submit Quiz",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),

            // ✅ Show score
            if (_score != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  "🏆 Your Last Score: $_score / 5",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
