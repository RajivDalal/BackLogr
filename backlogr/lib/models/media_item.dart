class MediaItem {
  final String id;
  final String title;
  final String type;
  final String? externalId;
  final String? posterUrl;
  final String? releaseDate;

  MediaItem({
    required this.id,
    required this.title,
    required this.type,
    this.externalId,
    this.posterUrl,
    this.releaseDate,
  });

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'] as String,
      title: map['title'] as String,
      type: map['type'] as String,
      externalId: map['external_id'] as String?,
      posterUrl: map['poster_url'] as String?,
      releaseDate: map['release_date'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'external_id': externalId,
      'poster_url': posterUrl,
      'release_date': releaseDate,
    };
  }
}
