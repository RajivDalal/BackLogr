import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';
import '../models/user_list.dart';
import '../models/media_item.dart';
import '../models/list_entry.dart';

class MediaRepository {
  final PowerSyncDatabase db;
  final _uuid = const Uuid();

  MediaRepository(this.db);

  Stream<List<UserList>> watchUserLists(String userId) {
    return db
        .watch(
          'SELECT * FROM user_lists WHERE user_id = ? ORDER BY created_at DESC',
          parameters: [userId],
        )
        .map((rows) => rows.map((r) => UserList.fromMap(r)).toList());
  }

  Future<void> createList(String userId, String name) async {
    final id = _uuid.v4();
    final createdAt = DateTime.now().toIso8601String();
    await db.execute(
      '''
      INSERT INTO user_lists (id, user_id, name, created_at)
      VALUES (?, ?, ?, ?)
      ''',
      [id, userId, name, createdAt],
    );
  }

  // Returns joined data between list_entries and media_items
  Stream<List<Map<String, dynamic>>> watchListEntries(String listId) {
    return db
        .watch(
          '''
      SELECT e.*, m.title, m.type, m.poster_url, m.release_date, m.description, m.author
      FROM list_entries e
      JOIN media_items m ON e.media_id = m.id
      WHERE e.list_id = ?
      ORDER BY e.updated_at DESC
      ''',
          parameters: [listId],
        )
        .map((rows) => rows.toList());
  }

  Future<void> addMediaToList(
    MediaItem item,
    String listId,
    String userId,
  ) async {
    // 1. Insert media item if it doesn't exist
    // PowerSync tables are exposed as views locally, so UPSERT (ON CONFLICT) is not supported.
    final existing = await db.getAll('SELECT id FROM media_items WHERE id = ?', [item.id]);

    if (existing.isEmpty) {
      await db.execute(
        '''
        INSERT INTO media_items (id, title, type, external_id, poster_url, release_date, description, author)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          item.id,
          item.title,
          item.type,
          item.externalId,
          item.posterUrl,
          item.releaseDate,
          item.description,
          item.author,
        ],
      );
    } else {
      await db.execute(
        '''
        UPDATE media_items
        SET title = ?, poster_url = ?, description = ?, author = ?
        WHERE id = ?
        ''',
        [item.title, item.posterUrl, item.description, item.author, item.id],
      );
    }

    // 2. Insert list entry
    final entryId = _uuid.v4();
    final updatedAt = DateTime.now().toIso8601String();

    await db.execute(
      '''
      INSERT INTO list_entries (id, user_id, list_id, media_id, progress, score, status, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        entryId,
        userId,
        listId,
        item.id,
        0, // progress
        null, // score
        'Planned', // default status
        updatedAt,
      ],
    );
  }

  Future<void> updateListEntry(
    String entryId, {
    int? progress,
    double? score,
    String? status,
  }) async {
    final updatedAt = DateTime.now().toIso8601String();

    final sets = <String>[];
    final args = <dynamic>[];

    if (progress != null) {
      sets.add('progress = ?');
      args.add(progress);
    }
    if (score != null) {
      sets.add('score = ?');
      args.add(score);
    }
    if (status != null) {
      sets.add('status = ?');
      args.add(status);
    }

    sets.add('updated_at = ?');
    args.add(updatedAt);
    args.add(entryId);

    if (sets.isNotEmpty) {
      final setString = sets.join(', ');
      await db.execute('UPDATE list_entries SET $setString WHERE id = ?', args);
    }
  }

  Future<void> removeMediaFromList(String entryId) async {
    await db.execute('DELETE FROM list_entries WHERE id = ?', [entryId]);
  }
}
