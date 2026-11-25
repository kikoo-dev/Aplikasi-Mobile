/// Model satu postingan pada feed (gaya LinkedIn).
class FeedPost {
  final String id;
  final String authorId;
  final String authorName;
  final String authorUsername;
  final String authorHeadline;
  final String authorAvatar;
  final String content;
  final String imageUrl;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool liked;

  const FeedPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorUsername = '',
    this.authorHeadline = '',
    this.authorAvatar = '',
    this.content = '',
    this.imageUrl = '',
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.liked = false,
  });

  FeedPost copyWith({
    int? likeCount,
    int? commentCount,
    bool? liked,
  }) {
    return FeedPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorUsername: authorUsername,
      authorHeadline: authorHeadline,
      authorAvatar: authorAvatar,
      content: content,
      imageUrl: imageUrl,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      liked: liked ?? this.liked,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'author_id': authorId,
        'author_name': authorName,
        'author_username': authorUsername,
        'author_headline': authorHeadline,
        'author_avatar': authorAvatar,
        'content': content,
        'image_url': imageUrl,
        'created_at': createdAt.toUtc().toIso8601String(),
        'like_count': likeCount,
        'comment_count': commentCount,
      };

  factory FeedPost.fromMap(Map<String, dynamic> map) {
    return FeedPost(
      id: (map['id'] ?? '').toString(),
      authorId: (map['author_id'] ?? '').toString(),
      authorName: (map['author_name'] ?? '').toString(),
      authorUsername: (map['author_username'] ?? '').toString(),
      authorHeadline: (map['author_headline'] ?? '').toString(),
      authorAvatar: (map['author_avatar'] ?? '').toString(),
      content: (map['content'] ?? '').toString(),
      imageUrl: (map['image_url'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString())?.toLocal() ??
              DateTime.now(),
      likeCount: (map['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (map['comment_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Mapping dari hasil join Supabase (`posts` + `profiles`).
  factory FeedPost.fromSupabase(Map<String, dynamic> row, {bool liked = false}) {
    final author = row['profiles'];
    final authorMap = author is Map ? Map<String, dynamic>.from(author) : null;

    return FeedPost(
      id: row['id'].toString(),
      authorId: (row['author_id'] ?? '').toString(),
      authorName: (authorMap?['full_name'] ?? 'Pengguna ITENAS').toString(),
      authorUsername: (authorMap?['username'] ?? '').toString(),
      authorHeadline: (authorMap?['occupation'] ?? '').toString(),
      authorAvatar: (authorMap?['avatar_url'] ?? '').toString(),
      content: (row['content'] ?? '').toString(),
      imageUrl: (row['image_url'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((row['created_at'] ?? '').toString())?.toLocal() ??
              DateTime.now(),
      likeCount: (row['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (row['comment_count'] as num?)?.toInt() ?? 0,
      liked: liked,
    );
  }
}
