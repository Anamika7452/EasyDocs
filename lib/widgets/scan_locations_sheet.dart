import 'package:flutter/material.dart';

import '../models/scan_folder.dart';
import '../services/folder_service.dart';

/// Bottom sheet that lets the user manage which folders EasyDocs scans.
///
/// All persistence happens natively (SAF + SharedPreferences); this widget is
/// purely a view over that state. It is intentionally structured so future
/// work can grow into it without a rewrite:
///  - [_FolderList] renders any list of [ScanFolder], so default folders
///    (Downloads/Documents) and custom folders can be merged in later.
///  - The header shows a live folder count.
///  - A rescan action can be added to the header actions row.
///
/// Open it with [ScanLocationsSheet.show].
class ScanLocationsSheet extends StatefulWidget {
  const ScanLocationsSheet({super.key, FolderService? folderService})
      : _injectedService = folderService;

  final FolderService? _injectedService;

  /// Shows the sheet and returns once it is dismissed.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const ScanLocationsSheet(),
    );
  }

  @override
  State<ScanLocationsSheet> createState() => _ScanLocationsSheetState();
}

class _ScanLocationsSheetState extends State<ScanLocationsSheet> {
  late final FolderService _folderService =
      widget._injectedService ?? FolderService();

  List<ScanFolder> _folders = const [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final folders = await _folderService.getSelectedFolders();
      if (!mounted) return;
      setState(() {
        _folders = folders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Could not load folders.');
    }
  }

  Future<void> _addFolder() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final folders = await _folderService.addFolder();
      if (!mounted) return;
      // null => cancelled or duplicate; leave the list untouched.
      if (folders != null) {
        setState(() => _folders = folders);
      }
    } catch (e) {
      if (mounted) _showError('Could not add folder.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeFolder(ScanFolder folder) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final folders = await _folderService.removeFolder(folder.uri);
      if (!mounted) return;
      setState(() => _folders = folders);
    } catch (e) {
      if (mounted) _showError('Could not remove folder.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Constrain height so the sheet feels like a sheet, not a full page,
    // while still scrolling gracefully when many folders are added.
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(count: _folders.length),
              const SizedBox(height: 16),
              Flexible(
                child: _buildBody(theme),
              ),
              const SizedBox(height: 16),
              _AddFolderButton(
                onPressed: _busy ? null : _addFolder,
              ),
              const SizedBox(height: 20),
              _Actions(
                onCancel: () => Navigator.of(context).pop(),
                onDone: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return _FolderList(
      folders: _folders,
      onRemove: _busy ? null : _removeFolder,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scan Locations',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose the folders EasyDocs should scan for documents.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 12),
          _CountBadge(count: count),
        ],
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FolderList extends StatelessWidget {
  const _FolderList({required this.folders, required this.onRemove});

  final List<ScanFolder> folders;
  final ValueChanged<ScanFolder>? onRemove;

  @override
  Widget build(BuildContext context) {
    final defaults = folders.where((f) => f.isDefault).toList();
    final custom = folders.where((f) => !f.isDefault).toList();

    // Build a flat list of section headers + folder tiles so the whole thing
    // scrolls as one. Sections only appear when they have content.
    final children = <Widget>[];

    if (defaults.isNotEmpty) {
      children.add(const _SectionLabel('Default (always scanned)'));
      for (final folder in defaults) {
        children.add(_FolderTile(folder: folder, onRemove: null));
      }
    }

    if (defaults.isNotEmpty) children.add(const SizedBox(height: 16));
    children.add(const _SectionLabel('Custom'));
    if (custom.isEmpty) {
      children.add(const _EmptyState());
    } else {
      for (final folder in custom) {
        children.add(_FolderTile(folder: folder, onRemove: onRemove));
      }
    }

    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: children,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({required this.folder, required this.onRemove});

  final ScanFolder folder;
  final ValueChanged<ScanFolder>? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: Icon(
            Icons.folder,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            folder.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: folder.path == null
              ? null
              : Text(
                  folder.path!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
          trailing: folder.isDefault
              // Default folders are fixed — signal "always on" instead of remove.
              ? Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : IconButton(
                  tooltip: 'Remove folder',
                  icon: const Icon(Icons.delete_outline),
                  onPressed:
                      onRemove == null ? null : () => onRemove!(folder),
                ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '📂',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'No folders selected',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Folder" to choose locations EasyDocs should scan.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFolderButton extends StatelessWidget {
  const _AddFolderButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: const Icon(Icons.add),
        label: const Text('Add Folder'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onCancel, required this.onDone});

  final VoidCallback onCancel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: onDone,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}
