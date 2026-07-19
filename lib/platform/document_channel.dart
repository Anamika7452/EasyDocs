import 'package:flutter/services.dart';

class DocumentChannel {
  static const MethodChannel _channel =
      MethodChannel('com.anamika.easydocs/documents');

  static Future<List<Map<String, dynamic>>> getDocuments() async {
    final List<dynamic>? documents =
        await _channel.invokeMethod('getDocuments');

    if (documents == null) {
      return [];
    }

    return documents
        .map((document) => Map<String, dynamic>.from(document))
        .toList();
  }
}