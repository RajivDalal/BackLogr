class ListEntry {
  final String id;
  final String userId;
  final String listId;
  final String mediaId;
  final int? progress;
  final double? score;
  final String? status;
  final String? updatedAt;

  ListEntry({
    required this.id,
    required this.userId,
    required this.listId,
    required this.mediaId,
    this.progress,
    this.score,
    this.status,
    this.updatedAt,
  });

  factory ListEntry.fromMap(Map<String, dynamic> map) {
    return ListEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      listId: map['list_id'] as String,
      mediaId: map['media_id'] as String,
      progress: map['progress'] as int?,
      score: map['score'] != null ? (map['score'] as num).toDouble() : null,
      status: map['status'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'list_id': listId,
      'media_id': mediaId,
      'progress': progress,
      'score': score,
      'status': status,
      'updated_at': updatedAt,
    };
  }
}
