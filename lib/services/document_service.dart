import '../models/document.dart';
import '../platform/document_channel.dart';

class DocumentService {
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
}