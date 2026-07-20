import '../models/scan_folder.dart';
import '../platform/document_channel.dart';

/// Coordinates folder management with the Android side.
///
/// This service holds no state itself — Android is the source of truth for
/// which folders are persisted. Each call returns the freshest list so the UI
/// can simply re-render.
class FolderService {
  Future<List<ScanFolder>> getSelectedFolders() async {
    final folders = await DocumentChannel.getSelectedFolders();
    return _toModels(folders);
  }

  /// Launches the native picker. Returns the refreshed list on success, or
  /// `null` if the user cancelled or the folder was a duplicate.
  Future<List<ScanFolder>?> addFolder() async {
    final folders = await DocumentChannel.pickFolder();
    if (folders == null) return null;
    return _toModels(folders);
  }

  Future<List<ScanFolder>> removeFolder(String uri) async {
    final folders = await DocumentChannel.removeFolder(uri);
    return _toModels(folders);
  }

  List<ScanFolder> _toModels(List<Map<String, dynamic>> raw) {
    return raw.map(ScanFolder.fromMap).toList();
  }
}
