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
  String _message = '';
  String _textContent = '';

  int _currentPage = 0;
  int _totalPages = 0;
  PDFViewController? _pdfController;

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
      _textContent = '';
      _currentPage = 0;
      _totalPages = 0;
      _pdfController = null;
    });

    try {
      final file = await _resolveFile();
      if (!mounted) return;

      final extension = widget.document.extension.toLowerCase();

      if (extension == 'pdf') {
        setState(() {
          _localPath = file.path;
          _message = '';
          _loading = false;
        });
        return;
      }

      if (!_isTextLike(extension)) {
        setState(() {
          _localPath = null;
          _message = 'This file type is not supported yet. Work in progress.';
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
    }.contains(normalized);
  }

  Future<void> _jumpToPage(int page) async {
    if (_pdfController == null) return;

    try {
      await _pdfController!.setPage(page);
      setState(() {
        _currentPage = page;
      });
    } catch (_) {
      // Ignore failed jumps while PDF is still rendering.
    }
  }

  @override
  Widget build(BuildContext context) {
    final extension = widget.document.extension.toLowerCase();
    final isPdf = extension == 'pdf';

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ),
        title: Text(widget.document.name),
      ),
      body: _buildBody(isPdf),
    );
  }

  Widget _buildBody(bool isPdf) {
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
      return Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 64, bottom: 12),
            child: PDFView(
              filePath: _localPath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              fitPolicy: FitPolicy.WIDTH,
              onError: (error) {
                setState(() => _error = error.toString());
              },
              onViewCreated: (controller) {
                _pdfController = controller;
              },
              onPageChanged: (page, total) {
                setState(() {
                  _currentPage = page ?? 0;
                  _totalPages = total ?? 0;
                });
              },
              onRender: (pages) {
                setState(() {
                  _totalPages = pages ?? _totalPages;
                });
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  IconButton(
                    onPressed: _currentPage > 0
                        ? () => _jumpToPage(_currentPage - 1)
                        : null,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    tooltip: 'Previous page',
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        _totalPages > 0
                            ? 'Page ${_currentPage + 1} / $_totalPages'
                            : 'Loading…',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _currentPage < _totalPages - 1
                        ? () => _jumpToPage(_currentPage + 1)
                        : null,
                    icon: const Icon(Icons.arrow_downward_rounded),
                    tooltip: 'Next page',
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (!isPdf && _message.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 56),
              const SizedBox(height: 12),
              Text(
                _message,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We are working on support for this file type.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
