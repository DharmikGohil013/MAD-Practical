import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/file_comment.dart';

class CommentTile extends StatelessWidget {
  final FileComment comment;
  const CommentTile({super.key, required this.comment});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
            child: const Icon(Icons.person, size: 20, color: Color(0xFF1565C0)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.text, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 6),
                Text(DateFormat('MMM dd, yyyy – HH:mm').format(comment.timestamp), style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
