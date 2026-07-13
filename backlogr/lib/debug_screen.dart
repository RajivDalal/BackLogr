import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// Import the global `db` variable we created in main.dart
import 'main.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // 1. Authenticate with Supabase
  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged in successfully! PowerSync will now connect.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => _isLoading = false);
  }

  // 2. Insert into the LOCAL database only
  Future<void> _addDummyMovie() async {
    // We generate a UUID locally. PowerSync requires UUIDs for sync.
    final id = const Uuid().v4();

    // db.execute runs directly against the local SQLite file. It is instant.
    await db.execute(
      '''
      INSERT INTO media_items (id, title, type, release_date) 
      VALUES (?, ?, ?, ?)
      ''',
      [id, 'The Matrix ${DateTime.now().second}', 'movie', '1999-03-31'],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if the user is currently logged in
    final session = Supabase.instance.client.auth.currentSession;

    return Scaffold(
      appBar: AppBar(title: const Text('Offline Sync Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- LOGIN UI ---
            if (session == null) ...[
              const Text(
                '1. Log in to authenticate PowerSync',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
              const Divider(),
            ] else ...[
              Text(
                'Logged in as: ${session.user.email}',
                style: const TextStyle(color: Colors.green),
              ),
              const Divider(),
            ],

            // --- SYNC STATUS ---
            const Text(
              '2. PowerSync Connection Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            StreamBuilder(
              // db.statusStream constantly broadcasts whether the app is uploading/downloading
              stream: db.statusStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text('Waiting for status...');
                }
                final status = snapshot.data!;
                return Text(
                  'Connected: ${status.connected}\nUploading: ${status.uploading}\nDownloading: ${status.downloading}',
                  style: const TextStyle(fontFamily: 'monospace'),
                );
              },
            ),
            const Divider(),

            // --- LOCAL DATABASE UI ---
            const Text(
              '3. Local Database (media_items)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: _addDummyMovie,
              child: const Text('Add Dummy Movie (Works Offline)'),
            ),
            Expanded(
              child: StreamBuilder(
                // db.watch automatically rebuilds the UI whenever the local table changes!
                stream: db.watch(
                  'SELECT * FROM media_items ORDER BY release_date DESC',
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final movies = snapshot.data!;

                  if (movies.isEmpty) {
                    return const Text('No movies in local database.');
                  }

                  return ListView.builder(
                    itemCount: movies.length,
                    itemBuilder: (context, index) {
                      final movie = movies[index];
                      return ListTile(
                        title: Text(movie['title'] as String),
                        subtitle: Text(movie['type'] as String),
                        trailing: const Icon(
                          Icons.cloud_done,
                          color: Colors.blue,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
