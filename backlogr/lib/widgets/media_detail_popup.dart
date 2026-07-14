import 'package:flutter/material.dart';
import '../repositories/media_repository.dart';

class MediaDetailPopup extends StatelessWidget {
  final Map<String, dynamic> entry;
  final MediaRepository repository;

  const MediaDetailPopup({
    super.key,
    required this.entry,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    final title = entry['title'] as String? ?? 'Unknown Title';
    final releaseDate = entry['release_date'] as String?;
    final year = releaseDate != null && releaseDate.length >= 4 
        ? releaseDate.substring(0, 4) 
        : 'N/A';
    
    final score = entry['score']?.toString() ?? '8.0'; 
    final description = entry['description'] as String? ?? 'No description available.';
    final author = entry['author'] as String? ?? 'Unknown';
    final posterUrl = entry['poster_url'] as String?;
    final status = entry['status'] as String? ?? 'Planned';
    final type = entry['type'] as String? ?? 'media';
    final entryId = entry['id'] as String;

    String actionText = 'Play';
    if (type.toLowerCase() == 'book') actionText = 'Read';
    if (type.toLowerCase() == 'movie' || type.toLowerCase() == 'show') actionText = 'Watch';

    Widget buildStatColumn(String label, IconData? icon, String value, {String? subValue}) {
      return Expanded(
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            if (icon != null) Icon(icon, size: 24, color: Colors.grey),
            if (icon == null) const SizedBox(height: 10),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (subValue != null)
              Text(subValue, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () => _showEditDialog(context, title, score, status),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () async {
                    await repository.removeMediaFromList(entryId);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Removed $title from list')),
                      );
                    }
                  },
                ),
              ],
            ),
            Center(
              child: Container(
                width: 180,
                height: 270,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 8))
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: posterUrl != null
                    ? Image.network(
                        posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Icon(Icons.image_not_supported, size: 50),
                      )
                    : const Icon(Icons.image, size: 80),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            const Divider(),
            IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    buildStatColumn('Added', Icons.add_circle, '1y ago'),
                    const VerticalDivider(),
                    buildStatColumn('Rating', Icons.star, score, subValue: 'of 10'),
                    const VerticalDivider(),
                    buildStatColumn('Release date', null, year),
                    const VerticalDivider(),
                    buildStatColumn('Runtime', Icons.schedule, '2h 10m'),
                  ],
                ),
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(fontSize: 15, color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 24),
            const Text('Genre', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(type.toUpperCase(), style: const TextStyle(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 16),
            Text(type.toLowerCase() == 'book' ? 'Written by' : 'Directed by', style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(author, style: const TextStyle(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: status == 'Completed' ? null : () async {
                  await repository.updateListEntry(entryId, status: 'Completed');
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Marked $title as Completed!')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(status == 'Completed' ? 'Completed' : actionText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, String title, String currentScoreStr, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) {
        String newStatus = currentStatus;
        TextEditingController scoreController = TextEditingController(text: currentScoreStr);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit $title'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: ['Planned', 'In Progress', 'Completed', 'Dropped'].contains(newStatus) ? newStatus : 'Planned',
                    items: ['Planned', 'In Progress', 'Completed', 'Dropped']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => newStatus = val);
                    },
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: scoreController,
                    decoration: const InputDecoration(labelText: 'Score (out of 10)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newScore = double.tryParse(scoreController.text);
                    await repository.updateListEntry(
                      entry['id'] as String,
                      status: newStatus,
                      score: newScore,
                    );
                    if (context.mounted) {
                      Navigator.pop(context); // close dialog
                      Navigator.pop(context); // close popup
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
  }
}
