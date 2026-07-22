import '../models/document.dart';
import '../platform/document_channel.dart';

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
    return DocumentChannel.getDocumentFilePath(
      uri: document.uri,
      name: document.name,
      extension: document.extension,
    );
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