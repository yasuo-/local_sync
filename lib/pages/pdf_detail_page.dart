import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';


class PDFDetailScreen extends StatefulWidget {
  final String filePath;

  const PDFDetailScreen({super.key, required this.filePath});

  @override
  // ignore: library_private_types_in_public_api
  _PDFDetailScreenState createState() => _PDFDetailScreenState();
}

class _PDFDetailScreenState extends State<PDFDetailScreen> {
  late PdfControllerPinch _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openFile(widget.filePath),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.filePath.split('/').last),
      ),
      body: PdfViewPinch(
        controller: _pdfController,
      ),
    );
  }
}
