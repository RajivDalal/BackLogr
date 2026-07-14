import 'package:flutter/material.dart';
import '../models/user_list.dart';
import '../repositories/media_repository.dart';
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

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                leading: entry['poster_url'] != null
                    ? Image.network(
                        entry['poster_url'] as String,
                        width: 50,
                        height: 75,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Icon(Icons.image_not_supported),
                      )
                    : const Icon(Icons.image, size: 50),
                title: Text(entry['title'] as String),
                subtitle: Text('${entry['type']} • Status: ${entry['status']}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'remove') {
                      repository.removeMediaFromList(entry['id'] as String);
                    } else if (value == 'complete') {
                      repository.updateListEntry(entry['id'] as String, status: 'Completed');
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'complete',
                      child: Text('Mark as Completed'),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove from list'),
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
