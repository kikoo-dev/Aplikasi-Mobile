/// Satu komentar pada postingan.
class PostComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final DateTime createdAt;

  const PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar = '',
    required this.content,
    required this.createdAt,
  });

  factory PostComment.fromSupabase(Map<String, dynamic> row) {
    final author = row['profiles'];
    final map = author is Map ? Map<String, dynamic>.from(author) : null;
    return PostComment(
      id: (row['id'] ?? '').toString(),
      postId: (row['post_id'] ?? '').toString(),
      authorId: (row['author_id'] ?? '').toString(),
      authorName: (map?['full_name'] ?? 'Pengguna').toString(),
      authorAvatar: (map?['avatar_url'] ?? '').toString(),
      content: (row['content'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((row['created_at'] ?? '').toString())?.toLocal() ??
              DateTime.now(),
    );
  }
}
