import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_list.dart';
import '../repositories/media_repository.dart';
import 'list_detail_screen.dart';
import '../main.dart'; // to access global db

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final MediaRepository _repository;
  final String _userId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _repository = MediaRepository(db);
  }

  Future<void> _showCreateListDialog() async {
    final controller = TextEditingController();
    String selectedCategory = 'Games';
    final categories = ['Games', 'Movies', 'Books', 'Shows', 'Anime', 'Manga'];

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create New List'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: 'e.g., Currently Playing'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedCategory = val);
                    },
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      Navigator.pop(context, {
                        'name': controller.text.trim(),
                        'category': selectedCategory,
                      });
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await _repository.createList(_userId, result['name']!, result['category']!);
    }
  }

  Future<void> _showEditListDialog(UserList list) async {
    final controller = TextEditingController(text: list.name);
    String selectedCategory = ['Games', 'Movies', 'Books', 'Shows', 'Anime', 'Manga'].contains(list.category) ? list.category : 'Games';
    final categories = ['Games', 'Movies', 'Books', 'Shows', 'Anime', 'Manga'];

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit List'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: 'e.g., Currently Playing'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedCategory = val);
                    },
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      Navigator.pop(context, {
                        'name': controller.text.trim(),
                        'category': selectedCategory,
                      });
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await _repository.updateList(list.id, result['name']!, result['category']!);
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          )
        ],
      ),
      body: StreamBuilder<List<UserList>>(
        stream: _repository.watchUserLists(_userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final lists = snapshot.data ?? [];
          
          if (lists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.list_alt, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No lists yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showCreateListDialog,
                    child: const Text('Create your first list'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              IconData getIconForCategory(String category) {
                switch (category) {
                  case 'Games': return Icons.videogame_asset;
                  case 'Movies': return Icons.movie;
                  case 'Books': return Icons.book;
                  case 'Shows': return Icons.tv;
                  case 'Anime': return Icons.animation;
                  case 'Manga': return Icons.menu_book;
                  default: return Icons.folder;
                }
              }

              return ListTile(
                leading: CircleAvatar(
                  child: Icon(getIconForCategory(list.category)),
                ),
                title: Text(list.name),
                subtitle: list.createdAt != null 
                    ? Text('Created: ${list.createdAt!.split('T').first}') 
                    : null,
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await _showEditListDialog(list);
                    } else if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete List?'),
                          content: const Text('Are you sure you want to delete this list and all its entries? This cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _repository.deleteList(list.id);
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit List'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete List', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListDetailScreen(
                        userList: list,
                        repository: _repository,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateListDialog,
        child: const Icon(Icons.add),
        tooltip: 'Create List',
      ),
    );
  }
}
