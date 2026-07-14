class UserList {
  final String id;
  final String userId;
  final String name;
  final String category;
  final String? createdAt;

  UserList({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.createdAt,
  });

  factory UserList.fromMap(Map<String, dynamic> map) {
    return UserList(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      category: map['category'] as String? ?? 'Games', // default fallback
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'category': category,
      'created_at': createdAt,
    };
  }
}
