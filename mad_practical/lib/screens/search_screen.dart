import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../widgets/file_card.dart';
import '../models/file_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  String _filterType = 'all';
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<FileProvider>();
      if (prov.files.isEmpty) prov.fetchFiles();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<FileModel> _filteredFiles(List<FileModel> files) {
    var result = files;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      result = result.where((f) => f.fileName.toLowerCase().contains(q) || f.description.toLowerCase().contains(q)).toList();
    }
    if (_filterType != 'all') {
      result = result.where((f) => f.fileType == _filterType).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search & Filter')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search files...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); })
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip('All', 'all'),
                const SizedBox(width: 8),
                _chip('PDF', 'pdf'),
                const SizedBox(width: 8),
                _chip('Doc', 'doc'),
                const SizedBox(width: 8),
                _chip('Image', 'image'),
                const SizedBox(width: 8),
                _chip('Other', 'other'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Results
          Expanded(
            child: Consumer<FileProvider>(
              builder: (context, prov, _) {
                final results = _filteredFiles(prov.files);
                if (prov.isLoading && prov.files.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('No files found', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: results.length,
                  itemBuilder: (_, i) => FileCard(file: results[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filterType = value),
      selectedColor: const Color(0xFF1565C0),
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w500),
      backgroundColor: Colors.grey.shade200,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
