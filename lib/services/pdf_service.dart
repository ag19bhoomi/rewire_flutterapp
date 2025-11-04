import 'dart:io';
import 'package:file_picker/file_picker.dart';

class PdfService {
  /// 📄 Pick a PDF file from local storage
  static Future<File?> pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
    } catch (e) {
      print("❌ Error picking PDF: $e");
    }
    return null;
  }
}
