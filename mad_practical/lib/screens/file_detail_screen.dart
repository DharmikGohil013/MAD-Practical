import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/file_model.dart';
import '../providers/file_provider.dart';
import '../widgets/version_tile.dart';
import '../widgets/comment_tile.dart';

class FileDetailScreen extends StatefulWidget {
  final FileModel file;
  const FileDetailScreen({super.key, required this.file});

  @override
  State<FileDetailScreen> createState() => _FileDetailScreenState();
}

class _FileDetailScreenState extends State<FileDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _versionNoteCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<FileProvider>();
      prov.fetchVersions(widget.file.id);
      prov.fetchComments(widget.file.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _versionNoteCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  IconData _fileIcon(String type) {
    switch (type) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc': return Icons.description;
      case 'image': return Icons.image;
      default: return Icons.insert_drive_file;
    }
  }

  Color _fileColor(String type) {
    switch (type) {
      case 'pdf': return Colors.red;
      case 'doc': return Colors.blue;
      case 'image': return Colors.green;
      default: return Colors.grey;
    }
  }

  void _showAddVersionDialog() {
    _versionNoteCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Version'),
        content: TextField(
          controller: _versionNoteCtrl,
          decoration: const InputDecoration(hintText: 'Version note'),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final prov = context.read<FileProvider>();
              await prov.createVersion(fileId: widget.file.id, note: _versionNoteCtrl.text.trim());
              if (mounted) {
                prov.fetchVersions(widget.file.id);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(prov.statusMessage),
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddCommentDialog() {
    _commentCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: _commentCtrl,
          decoration: const InputDecoration(hintText: 'Your comment'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_commentCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final prov = context.read<FileProvider>();
              await prov.addComment(fileId: widget.file.id, text: _commentCtrl.text.trim());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(prov.statusMessage),
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _showConflictDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 8), Text('Resolve Conflict')]),
        content: const Text('Choose how to resolve the version conflict:'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<FileProvider>().resolveConflict(widget.file.id, 'keep_latest');
            },
            child: const Text('Keep Latest'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<FileProvider>().resolveConflict(widget.file.id, 'keep_all');
            },
            child: const Text('Keep All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.fileName),
        actions: [
          if (widget.file.hasConflict)
            IconButton(icon: const Icon(Icons.warning, color: Colors.yellow), onPressed: _showConflictDialog, tooltip: 'Resolve Conflict'),
        ],
      ),
      body: Column(
        children: [
          // File info header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _fileColor(widget.file.fileType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_fileIcon(widget.file.fileType), size: 32, color: _fileColor(widget.file.fileType)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.file.fileName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(widget.file.fileType.toUpperCase(), style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      if (widget.file.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(widget.file.description, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                      ],
                      const SizedBox(height: 6),
                      Text('Created: ${DateFormat('MMM dd, yyyy – HH:mm').format(widget.file.createdAt)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (widget.file.isShared) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)), child: Text('Shared', style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600))),
                    if (widget.file.hasConflict) ...[const SizedBox(height: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: Text('Conflict', style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w600)))],
                  ],
                ),
              ],
            ),
          ),
          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(12)),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade700,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [Tab(text: 'Versions'), Tab(text: 'Comments')],
            ),
          ),
          const SizedBox(height: 8),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Versions tab
                Consumer<FileProvider>(
                  builder: (context, prov, _) {
                    if (prov.isLoading && prov.versions.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (prov.versions.isEmpty) {
                      return const Center(child: Text('No versions yet', style: TextStyle(color: Colors.grey)));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: prov.versions.length,
                      itemBuilder: (_, i) => VersionTile(version: prov.versions[i]),
                    );
                  },
                ),
                // Comments tab
                Consumer<FileProvider>(
                  builder: (context, prov, _) {
                    if (prov.isLoading && prov.comments.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (prov.comments.isEmpty) {
                      return const Center(child: Text('No comments yet', style: TextStyle(color: Colors.grey)));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: prov.comments.length,
                      itemBuilder: (_, i) => CommentTile(comment: prov.comments[i]),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'version',
            onPressed: _showAddVersionDialog,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.history, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'comment',
            onPressed: _showAddCommentDialog,
            child: const Icon(Icons.comment),
          ),
        ],
      ),
    );
  }
}
