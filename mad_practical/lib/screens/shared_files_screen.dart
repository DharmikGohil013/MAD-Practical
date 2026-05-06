import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../widgets/file_card.dart';

class SharedFilesScreen extends StatefulWidget {
  const SharedFilesScreen({super.key});

  @override
  State<SharedFilesScreen> createState() => _SharedFilesScreenState();
}

class _SharedFilesScreenState extends State<SharedFilesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<FileProvider>();
      if (prov.files.isEmpty) prov.fetchFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Files'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => context.read<FileProvider>().fetchFiles(),
          ),
        ],
      ),
      body: Consumer<FileProvider>(
        builder: (context, prov, _) {
          final shared = prov.files.where((f) => f.isShared).toList();

          if (prov.isLoading && prov.files.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (shared.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.share_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No shared files', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('Share a file from the home screen', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: shared.length,
            itemBuilder: (_, i) => FileCard(file: shared[i]),
          );
        },
      ),
    );
  }
}
