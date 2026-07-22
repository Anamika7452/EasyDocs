import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../models/document.dart';
import '../services/document_service.dart';

class DocumentViewerScreen extends StatefulWidget {
  const DocumentViewerScreen({super.key, required this.document});

  final Document document;

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  final DocumentService _documentService = DocumentService();

  bool _loading = true;
  String? _error;
  String? _localPath;
  File? _docxFile;
  String _textContent = '';

  @override
  void initState() {
    super.initState();
    _prepareDocument();
  }

  Future<void> _prepareDocument() async {
    setState(() {
      _loading = true;
      _error = null;
      _localPath = null;
      _docxFile = null;
      _textContent = '';
    });

    try {
      final file = await _resolveFile();
      if (!mounted) return;

      final extension = widget.document.extension.toLowerCase();

      if (extension == 'pdf') {
        setState(() {
          _localPath = file.path;
          _loading = false;
        });
        return;
      }

      if (extension == 'docx') {
        if (!mounted) return;
        setState(() {
          _docxFile = file;
          _loading = false;
        });
        return;
      }

      final content = await _readTextContent(file, extension);
      if (!mounted) return;

      setState(() {
        _textContent = content;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<File> _resolveFile() async {
    final resolvedPath = await _documentService.getDocumentFilePath(widget.document);

    if (resolvedPath == null || resolvedPath.isEmpty) {
      throw Exception('Unable to resolve document path.');
    }

    final file = File(resolvedPath);

    if (!await file.exists()) {
      throw Exception('The selected document could not be found.');
    }

    return file;
  }

  Future<String> _readTextContent(File file, String extension) async {
    if (!_isTextLike(extension)) {
      return 'This file type is not supported for inline preview.';
    }

    return file.readAsString();
  }

  bool _isTextLike(String extension) {
    final normalized = extension.toLowerCase();
    return {
      'txt',
      'md',
      'rtf',
      'json',
      'xml',
      'csv',
      'log',
      'yaml',
      'yml',
      'properties',
      'ini',
      'toml',
      'docx',
    }.contains(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final extension = widget.document.extension.toLowerCase();
    final isPdf = extension == 'pdf';
    final isDocx = extension == 'docx';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Viewer'),
      ),
      body: _buildBody(isPdf, isDocx),
    );
  }

  Widget _buildBody(bool isPdf, bool isDocx) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_outlined, size: 56),
              const SizedBox(height: 12),
              Text(
                'Unable to open this document',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (isPdf && _localPath != null) {
      return PDFView(
        filePath: _localPath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        onError: (error) {
          setState(() => _error = error.toString());
        },
      );
    }

    if (isDocx && _docxFile != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          'DOCX preview is not available in this build. The document content can be viewed as text if you open it from a text-compatible viewer.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        _textContent.isEmpty
            ? 'This document is being opened as a text preview.'
            : _textContent,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
