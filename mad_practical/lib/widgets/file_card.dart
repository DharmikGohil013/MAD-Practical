import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/file_model.dart';
import '../providers/file_provider.dart';
import '../screens/file_detail_screen.dart';

class FileCard extends StatelessWidget {
  final FileModel file;
  const FileCard({super.key, required this.file});

  IconData _icon(String type) {
    switch (type) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc': return Icons.description;
      case 'image': return Icons.image;
      default: return Icons.insert_drive_file;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'pdf': return Colors.red;
      case 'doc': return Colors.blue;
      case 'image': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FileDetailScreen(file: file))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // File type icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _color(file.fileType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon(file.fileType), color: _color(file.fileType), size: 28),
              ),
              const SizedBox(width: 14),
              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(file.fileName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                        if (file.hasConflict) Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)), child: Text('⚠ Conflict', style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.w600))),
                        if (file.isShared) Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)), child: Text('Shared', style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(file.fileType.toUpperCase(), style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                    if (file.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(file.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 4),
                    Text(DateFormat('MMM dd, yyyy').format(file.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                  ],
                ),
              ),
              // Action buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(file.isShared ? Icons.share : Icons.share_outlined, color: file.isShared ? Colors.green : Colors.grey, size: 20),
                    onPressed: () => context.read<FileProvider>().toggleShare(file.id, !file.isShared),
                    tooltip: file.isShared ? 'Unshare' : 'Share',
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
                    onPressed: () => _confirmDelete(context),
                    tooltip: 'Delete',
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Delete "${file.fileName}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await context.read<FileProvider>().deleteFile(file.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'File deleted' : 'Failed to delete'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
                ));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
