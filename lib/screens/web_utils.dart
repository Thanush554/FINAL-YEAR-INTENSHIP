// web_utils.dart
import 'dart:html' as html;
import 'dart:typed_data';

void downloadPdfForWeb(Uint8List pdfBytes) {
  final blob = html.Blob([pdfBytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', 'disease_report.pdf')
    ..click();
  html.Url.revokeObjectUrl(url);
}