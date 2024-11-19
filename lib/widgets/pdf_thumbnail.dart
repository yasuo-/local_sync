import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PDFThumbnail extends StatefulWidget {
  final String filePath;

  PDFThumbnail({required this.filePath});

  @override
  _PDFThumbnailState createState() => _PDFThumbnailState();
}

class _PDFThumbnailState extends State<PDFThumbnail> {
  late PdfDocument _document;
  bool _isLoaded = false;
  late PdfPageImage _pageImage;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  void _loadThumbnail() async {
    _document = await PdfDocument.openFile(widget.filePath);
    final page = await _document.getPage(1);
    final pageImage = await page.render(
      width: page.width,
      height: page.height,
      format: PdfPageImageFormat.png,
    );
    await page.close();
    setState(() {
      _pageImage = pageImage!;
      _isLoaded = true;
    });
  }

  @override
  void dispose() {
    _document.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _pageImage != null) {
      return Image.memory(_pageImage.bytes);
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }
}
