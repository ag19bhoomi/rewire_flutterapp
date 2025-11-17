import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rewire_app/services/pdf_service.dart';
import 'package:rewire_app/screens/subject_detail_screen.dart';
import 'package:rewire_app/providers/study_data_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/app_header.dart';

class StudyPlannerScreen extends StatefulWidget {
  const StudyPlannerScreen({Key? key}) : super(key: key);

  @override
  State<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends State<StudyPlannerScreen> {
  final TextEditingController _subjectController = TextEditingController();
  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  // ---------------------------------------------------------------------
  // Load saved subjects
  // ---------------------------------------------------------------------
  Future<void> _loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('subjects');

    if (data != null) {
      try {
        setState(() {
          _subjects = List<Map<String, dynamic>>.from(jsonDecode(data));
        });
      } catch (e) {
        // Corrupted JSON fallback
        setState(() => _subjects = []);
      }
    }
  }

  // ---------------------------------------------------------------------
  // Save subjects
  // ---------------------------------------------------------------------
  Future<void> _saveSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subjects', jsonEncode(_subjects));
  }

  // ---------------------------------------------------------------------
  // Add subject
  // ---------------------------------------------------------------------
  void _addSubject() async {
    final name = _subjectController.text.trim();
    if (name.isEmpty) return;

    // Prevent duplicate subject names
    if (_subjects.any((s) => s['name'] == name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❗ Subject already exists!")),
      );
      return;
    }

    // Reset score in provider
    final studyData = Provider.of<StudyDataProvider>(context, listen: false);
    studyData.updateQuizScore(name, 0, 0);

    setState(() {
      _subjects.add({
        'name': name,
        'pdfPath': null,
      });
      _subjectController.clear();
    });

    await _saveSubjects();
  }

  // ---------------------------------------------------------------------
  // Upload PDF
  // ---------------------------------------------------------------------
  Future<void> _uploadPdf(int index) async {
    final String? pdfPath = await PdfService.pickPdf();
    if (pdfPath == null) return;

    setState(() {
      _subjects[index]['pdfPath'] = pdfPath;
    });

    await _saveSubjects();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("📄 PDF uploaded successfully")),
    );
  }

  // ---------------------------------------------------------------------
  // Delete subject + remove its saved summary/score
  // ---------------------------------------------------------------------
  Future<void> _deleteSubject(int index) async {
    final subjectName = _subjects[index]['name'];

    // Delete score & summary stored in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${subjectName}_score');
    await prefs.remove('${subjectName}_summary');

    // Remove from provider also
    final provider = context.read<StudyDataProvider>();
    await provider.deleteSubject(subjectName);

    // Remove from subject list UI
    setState(() => _subjects.removeAt(index));

    await _saveSubjects();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const AppHeader(title: "Study Planner"),

          // Add subject input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      hintText: "Enter Subject Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  backgroundColor: Colors.deepPurple,
                  onPressed: _addSubject,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),

          // -------------------- Subject List --------------------
          Expanded(
            child: _subjects.isEmpty
                ? const Center(
              child: Text(
                "No subjects added yet.",
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final subject = _subjects[index];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---------------- Subject Name ----------------
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SubjectDetailScreen(
                                      subjectName: subject['name'],
                                      pdfPath: subject['pdfPath'],
                                    ),
                              ),
                            );
                          },
                          child: Text(
                            subject['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.deepPurple,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ---------------- Upload PDF ----------------
                        GestureDetector(
                          onTap: () => _uploadPdf(index),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.picture_as_pdf,
                                    color: Colors.deepPurple),
                                const SizedBox(width: 8),
                                Text(
                                  subject['pdfPath'] == null
                                      ? "Upload PDF"
                                      : "📄 PDF Uploaded",
                                  style: const TextStyle(
                                      color: Colors.deepPurple),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ---------------- Delete Button ----------------
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: () => _deleteSubject(index),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
