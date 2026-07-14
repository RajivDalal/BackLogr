import 'package:flutter/material.dart';
import '../models/user_list.dart';
import '../repositories/media_repository.dart';
import '../widgets/media_detail_popup.dart';
import 'add_media_screen.dart';

class ListDetailScreen extends StatelessWidget {
  final UserList userList;
  final MediaRepository repository;

  const ListDetailScreen({
    super.key,
    required this.userList,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userList.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Media',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddMediaScreen(
                    listId: userList.id,
                    category: userList.category,
                    repository: repository,
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: repository.watchListEntries(userList.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final entries = snapshot.data ?? [];

          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.movie_creation_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No media in this list.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddMediaScreen(
                            listId: userList.id,
                            category: userList.category,
                            repository: repository,
                          ),
                        ),
                      );
                    },
                    child: const Text('Add Media'),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 140, // 3 columns on phone, more on wider screens
              childAspectRatio: 0.55, // Adjusted to fit poster and text below
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => MediaDetailPopup(
                      entry: entry,
                      repository: repository,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Card(
                            clipBehavior: Clip.antiAlias,
                            elevation: 4,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            child: entry['poster_url'] != null
                                ? Image.network(
                                    entry['poster_url'] as String,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => const Icon(Icons.image_not_supported),
                                  )
                                : const Icon(Icons.image, size: 50),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry['title'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (entry['status'] == 'Completed') ...[
                          const Icon(Icons.check_circle, size: 14, color: Colors.blueAccent),
                          const SizedBox(width: 4),
                        ] else ...[
                          const Icon(Icons.add_circle, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            entry['release_date'] != null && entry['release_date'].toString().length >= 4 
                                ? entry['release_date'].toString().substring(0, 4) 
                                : entry['type'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddMediaScreen(
                listId: userList.id,
                category: userList.category,
                repository: repository,
              ),
            ),
          );
        },
        tooltip: 'Add Media',
        child: const Icon(Icons.add),
      ),
    );
  }
}
