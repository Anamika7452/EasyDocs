import 'package:flutter/services.dart';

/// Thin wrapper over the native Android MethodChannel.
///
/// All folder selection / SAF work happens on the Android side; Flutter only
/// requests actions and receives display-ready data back.
class DocumentChannel {
  static const MethodChannel _channel =
      MethodChannel('com.anamika.easydocs/documents');

  /// Whether the app has all-files access (needed to scan documents other
  /// apps created in Download/Documents).
  static Future<bool> hasStoragePermission() async {
    final bool? granted =
        await _channel.invokeMethod('hasStoragePermission');
    return granted ?? false;
  }

  /// Opens the system "All files access" settings screen. Returns whether the
  /// permission is granted at the moment of the call (usually false, since the
  /// user grants it in Settings afterwards).
  static Future<bool> requestStoragePermission() async {
    final bool? granted =
        await _channel.invokeMethod('requestStoragePermission');
    return granted ?? false;
  }

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

  /// Returns the currently persisted scan folders.
  static Future<List<Map<String, dynamic>>> getSelectedFolders() async {
    final List<dynamic>? folders =
        await _channel.invokeMethod('getSelectedFolders');

    return _asMapList(folders);
  }

  /// Opens the native SAF folder picker. Android persists the URI permission
  /// and saves the folder.
  ///
  /// Returns the refreshed folder list on success, or `null` when the user
  /// cancelled or picked a folder that was already selected.
  static Future<List<Map<String, dynamic>>?> pickFolder() async {
    final List<dynamic>? folders = await _channel.invokeMethod('pickFolder');

    if (folders == null) return null;

    return _asMapList(folders);
  }

  /// Removes a folder from scanning by its tree-URI and returns the
  /// refreshed list.
  static Future<List<Map<String, dynamic>>> removeFolder(String uri) async {
    final List<dynamic>? folders = await _channel.invokeMethod(
      'removeFolder',
      {'uri': uri},
    );

    return _asMapList(folders);
  }

  static List<Map<String, dynamic>> _asMapList(List<dynamic>? list) {
    if (list == null) return [];

    return list
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
