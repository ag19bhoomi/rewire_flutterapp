import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  /// Pick a PDF file and return path
  static Future<String?> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      return result.files.single.path!;
    }
    return null;
  }

  /// Extract text from PDF using Syncfusion Library
  static Future<String> extractText(String pdfPath) async {
    final bytes = File(pdfPath).readAsBytesSync();
    final document = PdfDocument(inputBytes: bytes);

    String extractedText = PdfTextExtractor(document).extractText();

    document.dispose();

    return extractedText;
  }
}
