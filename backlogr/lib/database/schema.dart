import 'package:powersync/powersync.dart';

const schema = Schema([
  Table('profiles', [Column.text('username'), Column.text('created_at')]),
  Table('media_items', [
    Column.text('title'),
    Column.text('type'),
    Column.text('external_id'),
    Column.text('poster_url'),
    Column.text('release_date'),
  ]),
  Table('user_lists', [
    Column.text('user_id'),
    Column.text('name'),
    Column.text('created_at'),
  ]),
  Table('list_entries', [
    Column.text('user_id'),
    Column.text('list_id'),
    Column.text('media_id'),
    Column.integer('progress'),
    Column.real('score'),
    Column.text('status'),
    Column.text('updated_at'),
  ]),
  Table('media_journals', [
    Column.text('user_id'),
    Column.text('media_id'),
    Column.text('review_text'),
    Column.text('favorite_character'),
    Column.integer(
      'is_exported_to_obsidian',
    ), // SQLite doesn't have booleans, uses 0/1
    Column.text('completed_at'),
  ]),
]);
