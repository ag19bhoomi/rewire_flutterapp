import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/study_data_provider.dart';
import '../services/gemini_service.dart';

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
  int? _total;  // ✅ NEW: store total quiz questions
  String? _summary;

  bool _isSummaryLoading = false;
  bool _isQuizLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _score = prefs.getInt('${widget.subjectName}_score');
      _total = prefs.getInt('${widget.subjectName}_total');  // ✅ load total
      _summary = prefs.getString('${widget.subjectName}_summary');
    });
  }

  // -------------------------------------------------------------------------
  // ✔ Summary
  // -------------------------------------------------------------------------
  Future<void> _generateSummary() async {
    if (widget.pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload a PDF first!")),
      );
      return;
    }

    setState(() {
      _isSummaryLoading = true;
      _summary = null;
    });

    try {
      final generated = await GeminiService.generateSummary(widget.pdfPath!);

      setState(() => _summary = generated);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${widget.subjectName}_summary', _summary!);
    } catch (e) {
      setState(() => _summary = "❌ Error: $e");
    } finally {
      setState(() => _isSummaryLoading = false);
    }
  }

  // -------------------------------------------------------------------------
  // ✔ Quiz
  // -------------------------------------------------------------------------
  Future<void> _generateQuiz() async {
    if (widget.pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload PDF first!")),
      );
      return;
    }

    setState(() {
      _isQuizLoading = true;
      _quiz = null;
      _score = null;
      _total = null;
      _selectedAnswers.clear();
    });

    try {
      final quizList = await GeminiService.generateQuiz(widget.pdfPath!);

      if (quizList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to generate quiz.")),
        );
        return;
      }

      setState(() => _quiz = quizList);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error generating quiz: $e")),
      );
    } finally {
      setState(() => _isQuizLoading = false);
    }
  }

  // -------------------------------------------------------------------------
  // ✔ Submit Quiz
  // -------------------------------------------------------------------------
  Future<void> _submitQuiz() async {
    if (_quiz == null) return;

    int score = 0;

    for (int i = 0; i < _quiz!.length; i++) {
      if (_selectedAnswers[i] == _quiz![i]['correctIndex']) score++;
    }

    setState(() {
      _score = score;
      _total = _quiz!.length;   // ⭐ IMPORTANT FIX: save total
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${widget.subjectName}_score', score);
    await prefs.setInt('${widget.subjectName}_total', _total!);  // ⭐ SAVE TOTAL

    final provider = Provider.of<StudyDataProvider>(context, listen: false);
    provider.updateQuizScore(widget.subjectName, score, _total!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ You scored $score / $_total!")),
    );
  }

  // -------------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------------
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
            // ---------------- Summary Button ----------------
            ElevatedButton.icon(
              icon: const Icon(Icons.summarize, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _isSummaryLoading ? null : _generateSummary,
              label: const Text("Generate Summary",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),

            const SizedBox(height: 10),

            // ---------------- Quiz Button ----------------
            ElevatedButton.icon(
              icon: const Icon(Icons.quiz, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _isQuizLoading ? null : _generateQuiz,
              label: const Text("Generate Quiz",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),

            const SizedBox(height: 20),

            // ---------------- Summary Loader ----------------
            if (_isSummaryLoading)
              const CircularProgressIndicator(color: Colors.deepPurple),

            // ---------------- Summary UI ----------------
            if (!_isSummaryLoading && _summary != null)
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
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_summary!,
                        style: const TextStyle(fontSize: 15, height: 1.4)),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // ---------------- Quiz Loader ----------------
            if (_isQuizLoading)
              const CircularProgressIndicator(color: Colors.pinkAccent),

            // ---------------- Quiz UI ----------------
            if (_quiz != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "🧠 Quiz:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
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
                            Text(q['question'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16)),
                            const SizedBox(height: 8),
                            ...List.generate(q['options'].length, (optIndex) {
                              return RadioListTile<int>(
                                value: optIndex,
                                groupValue: _selectedAnswers[index],
                                activeColor: Colors.deepPurple,
                                title: Text(q['options'][optIndex]),
                                onChanged: (val) {
                                  setState(() => _selectedAnswers[index] = val!);
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }),

                  ElevatedButton(
                    onPressed: _submitQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Submit Quiz",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),

            // ---------------- Score UI ----------------
            if (_score != null && _total != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  "🏆 Your Last Score: $_score / $_total",
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
