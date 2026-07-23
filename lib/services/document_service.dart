import 'dart:io';

import '../models/document.dart';
import '../platform/document_channel.dart';
import 'package:flutter/services.dart';

class DocumentService {
  Future<bool> hasStoragePermission() =>
      DocumentChannel.hasStoragePermission();

  Future<bool> requestStoragePermission() =>
      DocumentChannel.requestStoragePermission();

  Future<List<Document>> getDocuments() async {
    final documents = await DocumentChannel.getDocuments();

    return documents.map((document) {
      return Document(
        name: document['name'] as String,
        uri: document['uri'] as String,
        size: document['size'] as int,
        extension: document['extension'] as String,
      );
    }).toList();
  }

  Future<String?> getDocumentFilePath(Document document) async {
    final uri = Uri.tryParse(document.uri);

    if (uri == null || uri.scheme.isEmpty || uri.scheme == 'file') {
      final path = uri == null || uri.scheme.isEmpty
          ? document.uri
          : uri.toFilePath();
      final file = File(path);
      if (await file.exists()) {
        return file.path;
      }
    }

    return DocumentChannel.getDocumentFilePath(
      uri: document.uri,
      name: document.name,
      extension: document.extension,
    );
  }

  Future<String> renameDocument(Document document, String newName) async {
    final uri = Uri.tryParse(document.uri);

    if (uri == null || uri.scheme.isEmpty || uri.scheme == 'file') {
      final filePath = uri == null || uri.scheme.isEmpty
          ? document.uri
          : uri.toFilePath();
      final sourceFile = File(filePath);

      if (!await sourceFile.exists()) {
        throw Exception('Document not found.');
      }

      final targetFile = File(
        '${sourceFile.parent.path}${Platform.pathSeparator}$newName',
      );

      if (await targetFile.exists()) {
        throw Exception('A file with this name already exists.');
      }

      final moved = await sourceFile.rename(targetFile.path);
      return moved.path;
    }

    try {
      return await DocumentChannel.renameDocument(
        uri: document.uri,
        newName: newName,
      );
    } on MissingPluginException {
      throw Exception('Rename is not supported on this platform.');
    }
  }

  Future<Document?> getPendingDocument() async {
    final pending = await DocumentChannel.getPendingDocument();

    if (pending == null) return null;

    return Document(
      name: pending['name'] as String,
      uri: pending['uri'] as String,
      size: pending['size'] as int,
      extension: pending['extension'] as String,
    );
  }
}