import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/media_item.dart';
import '../repositories/media_repository.dart';
import '../services/api_service.dart';

class AddMediaScreen extends StatefulWidget {
  final String listId;
  final MediaRepository repository;

  const AddMediaScreen({
    super.key,
    required this.listId,
    required this.repository,
  });

  @override
  State<AddMediaScreen> createState() => _AddMediaScreenState();
}

class _AddMediaScreenState extends State<AddMediaScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<MediaItem> _searchResults = [];
  bool _isSearching = false;

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final results = await _apiService.searchMedia(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _addMedia(MediaItem item) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await widget.repository.addMediaToList(item, widget.listId, userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${item.title} to list!')),
      );
      Navigator.pop(context); // Go back after adding
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Media'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for movies, games, books...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _performSearch,
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          if (_isSearching)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_searchResults.isEmpty)
            const Expanded(
              child: Center(
                child: Text('Type a query and press search to find media.'),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  return ListTile(
                    leading: item.posterUrl != null
                        ? Image.network(
                            item.posterUrl!,
                            width: 50,
                            height: 75,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const Icon(Icons.image_not_supported),
                          )
                        : const Icon(Icons.image, size: 50),
                    title: Text(item.title),
                    subtitle: Text('${item.type} • ${item.releaseDate ?? "Unknown"}'),
                    trailing: ElevatedButton(
                      onPressed: () => _addMedia(item),
                      child: const Text('Add'),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
