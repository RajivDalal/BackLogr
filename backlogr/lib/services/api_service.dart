import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../models/media_item.dart';

class ApiService {
  final Dio _dio = Dio();
  final _uuid = const Uuid();

  // Stub for searching media across platforms
  Future<List<MediaItem>> searchMedia(String query) async {
    // In a real implementation, this would call TMDB, IGDB, AniList, etc.
    // depending on the search configuration.
    
    // Simulating network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Returning mock data for v1 demonstration
    if (query.trim().isEmpty) return [];

    return [
      MediaItem(
        id: _uuid.v4(),
        title: 'Mock Movie: $query',
        type: 'movie',
        externalId: 'mock-123',
        posterUrl: 'https://via.placeholder.com/300x450.png?text=Movie',
        releaseDate: '2026-01-01',
        description: 'A thrilling mock movie where things happen and the hero saves the day. Truly a masterpiece of placeholder cinema.',
        author: 'John Director',
      ),
      MediaItem(
        id: _uuid.v4(),
        title: 'Mock Game: $query',
        type: 'game',
        externalId: 'mock-456',
        posterUrl: 'https://via.placeholder.com/300x450.png?text=Game',
        releaseDate: '2026-02-01',
        description: 'An interactive experience with amazing graphics and an immersive storyline.',
        author: 'GameStudio',
      ),
      MediaItem(
        id: _uuid.v4(),
        title: 'Mock Book: $query',
        type: 'book',
        externalId: 'mock-789',
        posterUrl: 'https://via.placeholder.com/300x450.png?text=Book',
        releaseDate: '2019',
        description: 'When the van door slammed on Offred\'s future at the end of The Handmaid\'s Tale, readers had no way of telling what lay ahead for her--freedom, prison or death.',
        author: 'Margaret Atwood',
      ),
    ];
  }
}
