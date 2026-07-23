import 'package:flutter/material.dart';
import '../models/document.dart';
import '../services/document_service.dart';
import '../widgets/scan_locations_sheet.dart';
import 'document_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  final DocumentService _documentService = DocumentService();

  List<Document> _documents = const [];
  String _query = '';
  bool _loading = true;
  bool _hasPermission = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDocuments();
    _handlePendingDocument();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user may have just granted all-files access in Settings — re-check.
    if (state == AppLifecycleState.resumed && !_hasPermission) {
      _loadDocuments();
    }
  }

  Future<void> _loadDocuments() async {
    setState(() => _loading = true);
    try {
      final hasPermission = await _documentService.hasStoragePermission();
      if (!mounted) return;

      if (!hasPermission) {
        setState(() {
          _hasPermission = false;
          _documents = const [];
          _loading = false;
        });
        return;
      }

      final documents = await _documentService.getDocuments();
      documents.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (!mounted) return;
      setState(() {
        _hasPermission = true;
        _documents = documents;
        _loading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error loading documents: $e');
      debugPrint(stackTrace.toString());
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not scan documents.')),
      );
    }
  }

  Future<void> _requestPermission() async {
    await _documentService.requestStoragePermission();
    // Grant completes in system Settings; the resume handler re-scans.
  }

  Future<void> _handlePendingDocument() async {
    final pending = await _documentService.getPendingDocument();
    if (!mounted || pending == null) return;

    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentViewerScreen(document: pending),
      ),
    );
  }

  Future<void> _openScanLocations() async {
    await ScanLocationsSheet.show(context);
    // Folders may have changed while the sheet was open — rescan.
    if (mounted) _loadDocuments();
  }

  void _sortDocuments() {
    _documents.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> _renameDocument(Document document) async {
    final newName = await _showRenameDialog(document);
    if (newName == null || newName.trim().isEmpty) return;

    try {
      final normalizedName = _normalizeRename(newName.trim(), document.extension);
      if (normalizedName == document.name) {
        return;
      }

      final renamedUri = await _documentService.renameDocument(document, normalizedName);
      if (!mounted) return;

      setState(() {
        _documents = _documents.map((d) {
          if (d.uri == document.uri) {
            return Document(
              name: normalizedName,
              uri: renamedUri,
              size: d.size,
              extension: d.extension,
            );
          }
          return d;
        }).toList();
        _sortDocuments();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Renamed to "$normalizedName".')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rename failed: $error')),
      );
    }
  }

  Future<String?> _showRenameDialog(Document document) async {
    final controller = TextEditingController(text: document.name);

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename document'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'New file name',
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  String _normalizeRename(String name, String extension) {
    if (name.contains('.')) return name;
    if (extension.trim().isEmpty) return name;
    return '$name.$extension';
  }

  List<Document> get _filtered {
    if (_query.trim().isEmpty) return _documents;
    final q = _query.toLowerCase();
    return _documents
        .where((d) => d.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        surfaceTintColor: theme.colorScheme.background,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('EasyDocs'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Rescan',
            onPressed: _loading ? null : _loadDocuments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          color: theme.colorScheme.background,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search documents...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasPermission) {
      return _PermissionNeeded(onGrant: _requestPermission);
    }

    final docs = _filtered;

    if (docs.isEmpty) {
      return _EmptyDocuments(
        isSearching: _query.trim().isNotEmpty,
        onAddFolders: _openScanLocations,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDocuments,
      child: ListView.separated(
        itemCount: docs.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) => _DocumentTile(
          document: docs[index],
          onRename: _renameDocument,
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document, required this.onRename});

  final Document document;
  final ValueChanged<Document> onRename;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DocumentViewerScreen(document: document),
          ),
        );
      },
      onLongPress: () => onRename(document),
      leading: Icon(
        _iconData(document.extension),
        color: _iconColor(document.extension, theme),
      ),
      title: Text(
        document.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${document.extension.toUpperCase()} · ${_formatSize(document.size)}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  static IconData _iconData(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
      case 'odp':
        return Icons.slideshow;
      case 'txt':
      case 'md':
      case 'rtf':
        return Icons.notes;
      case 'html':
      case 'htm':
      case 'json':
      case 'xml':
      case 'csv':
        return Icons.code;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'heic':
      case 'heif':
        return Icons.image;
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'ogg':
      case 'm4a':
      case 'amr':
        return Icons.audiotrack;
      case 'mp4':
      case 'mkv':
      case 'mov':
      case 'avi':
      case 'flv':
      case 'wmv':
      case 'webm':
      case '3gp':
        return Icons.movie;
      default:
        return Icons.description;
    }
  }

  static Color _iconColor(String extension, ThemeData theme) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
      case 'odp':
        return Colors.orange;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'heic':
      case 'heif':
        return Colors.purple;
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'ogg':
      case 'm4a':
      case 'amr':
        return Colors.indigo;
      case 'mp4':
      case 'mkv':
      case 'mov':
      case 'avi':
      case 'flv':
      case 'wmv':
      case 'webm':
      case '3gp':
        return Colors.teal;
      default:
        return theme.colorScheme.primary;
    }
  }

  static String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'kB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    final value = size >= 10 || unit == 0
        ? size.toStringAsFixed(0)
        : size.toStringAsFixed(1);
    return '$value ${units[unit]}';
  }
}

class _PermissionNeeded extends StatelessWidget {
  const _PermissionNeeded({required this.onGrant});

  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_off_outlined, size: 72, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'Storage access needed',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'EasyDocs needs all-files access to find documents in your '
              'folders. Grant "Allow access to manage all files" in Settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onGrant,
            icon: const Icon(Icons.settings),
            label: const Text('Grant access'),
          ),
        ],
      ),
    );
  }
}

class _EmptyDocuments extends StatelessWidget {
  const _EmptyDocuments({
    required this.isSearching,
    required this.onAddFolders,
  });

  final bool isSearching;
  final VoidCallback onAddFolders;

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return const Center(
        child: Text(
          'No documents match your search.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.description_outlined,
            size: 72,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'No documents found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Your documents will appear here after scanning your device.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onAddFolders,
            icon: const Icon(Icons.folder_open),
            label: const Text('Scan locations'),
          ),
        ],
      ),
    );
  }
}
