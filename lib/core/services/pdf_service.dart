import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();

  factory PdfService() {
    return _instance;
  }

  PdfService._internal();

  Future<void> initialize() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await Printing.layoutPdf(
        onLayout: (_) => Uint8List(0),
        format: PdfPageFormat.a4,
      );
    }
  }

  Future<void> printDocument({
    required Future<Uint8List> Function(PdfPageFormat) onLayout,
    required String filename,
  }) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await Printing.layoutPdf(
          onLayout: onLayout,
          name: filename,
        );
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final pdfData = await onLayout(PdfPageFormat.a4);
        await Printing.layoutPdf(
          onLayout: (_) => Future.value(pdfData),
          name: filename,
        );
      } else {
        throw Exception('Unsupported platform for PDF generation');
      }
    } catch (e) {
      throw Exception('Failed to generate PDF: $e');
    }
  }
}