import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/file_version.dart';

class VersionTile extends StatelessWidget {
  final FileVersion version;
  const VersionTile({super.key, required this.version});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'v${version.versionNumber}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1565C0)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Version ${version.versionNumber}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                if (version.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(version.note, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
                const SizedBox(height: 2),
                Text(DateFormat('MMM dd, yyyy – HH:mm').format(version.timestamp), style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
          Icon(Icons.history, size: 18, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
