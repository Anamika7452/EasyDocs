/// A folder the user has chosen for EasyDocs to scan.
///
/// [uri] is the opaque SAF tree-URI (the stable identity used to add/remove).
/// [name] and [path] are display-only, derived on the Android side.
class ScanFolder {
  final String uri;
  final String name;
  final String? path;

  /// Default folders (Download, Documents) are fixed, always-scanned, and
  /// cannot be removed. Custom folders are user-added via the SAF picker.
  final bool isDefault;

  const ScanFolder({
    required this.uri,
    required this.name,
    this.path,
    this.isDefault = false,
  });

  factory ScanFolder.fromMap(Map<String, dynamic> map) {
    final path = map['path'] as String?;

    return ScanFolder(
      uri: map['uri'] as String,
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? map['name'] as String
          : 'Selected folder',
      path: (path != null && path.trim().isNotEmpty) ? path : null,
      isDefault: map['isDefault'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ScanFolder && other.uri == uri;

  @override
  int get hashCode => uri.hashCode;
}
