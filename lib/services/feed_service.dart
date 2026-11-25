import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/feed_post.dart';
import '../models/post_comment.dart';

/// Abstraksi sumber data feed.
abstract class FeedService {
  bool get isRemote;

  /// Ambil daftar postingan (terbaru di atas).
  Future<List<FeedPost>> fetchPosts({int limit = 30});

  /// Buat postingan baru.
  Future<FeedPost> createPost({
    required String content,
    required String imageUrl,
  });

  /// Toggle like, mengembalikan status liked terbaru.
  Future<bool> toggleLike(FeedPost post);

  /// Ambil URL foto publik untuk postingan.
  Future<String> uploadPostImage({
    required List<int> bytes,
    required String fileName,
  });

  /// Daftar komentar sebuah postingan.
  Future<List<PostComment>> fetchComments(String postId);

  /// Kirim komentar baru.
  Future<PostComment> addComment({
    required String postId,
    required String content,
  });

  /// Hapus postingan (hanya pemiliknya).
  Future<void> deletePost(String postId);
}

/// Factory: pilih sumber data feed sesuai konfigurasi Supabase.
FeedService createFeedService({bool useSupabase = false}) {
  if (useSupabase) {
    return SupabaseFeedService(sb.Supabase.instance.client);
  }
  return DemoFeedService.instance;
}

// IMPLEMENTASI SUPABASE
// ============================================================
class SupabaseFeedService implements FeedService {
  SupabaseFeedService(this._client);

  final sb.SupabaseClient _client;

  /// True jika tabel `posts` belum dibuat di project Supabase.
  /// Dalam kondisi ini feed memakai data contoh agar aplikasi tetap
  /// bisa dipakai/dipresentasikan.
  bool postsTableMissing = false;

  @override
  bool get isRemote => true;

  String? get _uid => _client.auth.currentUser?.id;

  bool _isTableMissing(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('pgrst205') ||
        msg.contains('could not find the table') ||
        msg.contains('does not exist');
  }

  @override
  Future<List<FeedPost>> fetchPosts({int limit = 30}) async {
    try {
      final rows = await _client
          .from('posts')
          .select('*, profiles(full_name, username, occupation, avatar_url)')
          .order('created_at', ascending: false)
          .limit(limit);

      postsTableMissing = false;

      final posts = <FeedPost>[];
      final likedIds = await _likedPostIds();

      for (final row in rows as List) {
        final map = Map<String, dynamic>.from(row as Map);
        posts.add(
          FeedPost.fromSupabase(
            map,
            liked: likedIds.contains(map['id'].toString()),
          ),
        );
      }
      return posts;
    } catch (e) {
      if (_isTableMissing(e)) {
        // Tabel belum dibuat -> pakai data contoh (read-only).
        postsTableMissing = true;
        return DemoFeedService.instance.samplePosts();
      }
      rethrow;
    }
  }

  /// Ambil semua post_id yang disukai pengguna ini (1 request).
  Future<Set<String>> _likedPostIds() async {
    final uid = _uid;
    if (uid == null) return {};
    try {
      final rows = await _client
          .from('post_likes')
          .select('post_id')
          .eq('user_id', uid);
      return (rows as List)
          .map((r) => (r as Map)['post_id'].toString())
          .toSet();
    } catch (_) {
      return {};
    }
  }

  @override
  Future<FeedPost> createPost({
    required String content,
    required String imageUrl,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw Exception('Sesi berakhir. Silakan login ulang.');
    }

    try {
      // PENTING: `Prefer: return=representation` wajib ada.
      // Tanpa header ini Supabase mengembalikan body kosong sehingga
      // `.single()` gagal -> "Gagal membagikan".
      final row = await _client
          .from('posts')
          .insert({
            'author_id': uid,
            'content': content,
            'image_url': imageUrl,
          })
          .select('*, profiles(full_name, username, occupation, avatar_url)')
          .single();

      return FeedPost.fromSupabase(Map<String, dynamic>.from(row));
    } on sb.PostgrestException catch (e) {
      if (_isTableMissing(e)) {
        throw Exception(
          'Tabel "posts" belum dibuat di Supabase. Jalankan '
          'supabase/complete_schema.sql di SQL Editor.',
        );
      }
      throw Exception('Gagal membagikan: ${e.message}');
    } catch (e) {
      if (_isTableMissing(e)) {
        throw Exception(
          'Tabel "posts" belum dibuat di Supabase. Jalankan '
          'supabase/complete_schema.sql di SQL Editor.',
        );
      }
      throw Exception('Gagal membagikan: $e');
    }
  }

  // ------------------------------------------------------------
  // KOMENTAR
  // ------------------------------------------------------------
  @override
  Future<List<PostComment>> fetchComments(String postId) async {
    try {
      final rows = await _client
          .from('post_comments')
          .select('*, profiles(full_name, avatar_url)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return (rows as List)
          .map((r) => PostComment.fromSupabase(
                Map<String, dynamic>.from(r as Map),
              ))
          .toList();
    } on sb.PostgrestException catch (e) {
      if (_isTableMissing(e)) {
        throw Exception(
          'Tabel komentar belum dibuat. Jalankan '
          'supabase/comments_schema.sql di SQL Editor.',
        );
      }
      throw Exception('Gagal memuat komentar: ${e.message}');
    }
  }

  @override
  Future<PostComment> addComment({
    required String postId,
    required String content,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Sesi berakhir. Silakan login ulang.');

    try {
      final row = await _client
          .from('post_comments')
          .insert({
            'post_id': postId,
            'author_id': uid,
            'content': content,
          })
          .select('*, profiles(full_name, avatar_url)')
          .single();

      // Naikkan counter (abaikan bila RPC belum ada).
      try {
        await _client.rpc('increment_comment', params: {'post_id': postId});
      } catch (_) {}

      return PostComment.fromSupabase(Map<String, dynamic>.from(row));
    } on sb.PostgrestException catch (e) {
      if (_isTableMissing(e)) {
        throw Exception(
          'Tabel komentar belum dibuat. Jalankan '
          'supabase/comments_schema.sql di SQL Editor.',
        );
      }
      throw Exception('Gagal mengirim komentar: ${e.message}');
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    final uid = _uid;
    if (uid == null) throw Exception('Sesi berakhir. Silakan login ulang.');

    try {
      // RLS memastikan hanya pemilik postingan yang bisa menghapus.
      // Hapus baris lalu verifikasi benar-benar hilang.
      await _client.from('posts').delete().eq('id', postId).eq(
            'author_id',
            uid,
          );

      final check = await _client
          .from('posts')
          .select('id')
          .eq('id', postId)
          .maybeSingle();

      if (check != null) {
        throw Exception(
          'Postingan tidak terhapus. Pastikan policy RLS untuk DELETE '
          'sudah dibuat (lihat supabase/schema.sql).',
        );
      }
    } on sb.PostgrestException catch (e) {
      if (_isTableMissing(e)) {
        throw Exception('Tabel "posts" tidak ditemukan.');
      }
      throw Exception('Gagal menghapus postingan: ${e.message}');
    }
  }

  @override
  Future<bool> toggleLike(FeedPost post) async {
    final uid = _uid;
    if (uid == null) throw Exception('Sesi berakhir.');

    try {
      final existing = await _client
          .from('post_likes')
          .select('id')
          .eq('post_id', post.id)
          .eq('user_id', uid)
          .maybeSingle();

      if (existing != null) {
        await _client.from('post_likes').delete().eq('id', existing['id']);
        await _client.rpc('decrement_like', params: {'post_id': post.id});
        return false;
      }

      await _client.from('post_likes').insert({
        'post_id': post.id,
        'user_id': uid,
      });
      await _client.rpc('increment_like', params: {'post_id': post.id});
      return true;
    } catch (e) {
      if (_isTableMissing(e)) {
        throw Exception(
          'Tabel feed belum dibuat. Jalankan supabase/complete_schema.sql.',
        );
      }
      throw Exception('Gagal menyukai postingan: $e');
    }
  }

  @override
  Future<String> uploadPostImage({
    required List<int> bytes,
    required String fileName,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Sesi berakhir.');

    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    final path = '$uid/post_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('posts').uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: const sb.FileOptions(upsert: true),
        );

    return _client.storage.from('posts').getPublicUrl(path);
  }
}

// ============================================================
// IMPLEMENTASI DEMO (LOKAL)
// ============================================================
class DemoFeedService implements FeedService {
  DemoFeedService._();

  static final DemoFeedService instance = DemoFeedService._();

  static const String _kPosts = 'demo_feed_posts';
  static const String _kLikes = 'demo_feed_likes';

  @override
  bool get isRemote => false;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Data contoh (dipakai mode demo & fallback saat tabel belum ada).
  List<FeedPost> samplePosts() {
    final now = DateTime.now();
    return [
      FeedPost(
        id: 'seed_1',
        authorId: 'u_1',
        authorName: 'Rizky Pratama',
        authorUsername: 'rizkypratama',
        authorHeadline: 'Teknik Informatika 2022',
        content:
            'Selesai juga praktikum Struktur Data hari ini! Seru banget '
            'belajar implementasi Binary Search Tree langsung pakai Dart. '
            'Terima kasih asisten dosen yang sabar menjelaskan 🌳',
        imageUrl: 'https://picsum.photos/seed/itenas1/800/600',
        createdAt: now.subtract(const Duration(minutes: 12)),
        likeCount: 128,
        commentCount: 14,
      ),
      FeedPost(
        id: 'seed_2',
        authorId: 'u_2',
        authorName: 'Siti Nurhaliza',
        authorUsername: 'sitinur',
        authorHeadline: 'Teknik Sipil 2021',
        content:
            'Kunjungan lapangan ke proyek jembatan di Padalarang. Banyak '
            'pelajaran nyata yang tidak didapat di kelas 🏗️',
        imageUrl: 'https://picsum.photos/seed/itenas2/800/600',
        createdAt: now.subtract(const Duration(hours: 3)),
        likeCount: 342,
        commentCount: 27,
      ),
      FeedPost(
        id: 'seed_3',
        authorId: 'u_3',
        authorName: 'Dimas Anggara',
        authorUsername: 'dimasanggara',
        authorHeadline: 'Desain Komunikasi Visual 2023',
        content:
            'Poster untuk pameran desain akhir semester. Tema tahun ini '
            '"Warisan Nusantara" — semua elemen dibuat manual 🎨',
        imageUrl: 'https://picsum.photos/seed/itenas3/800/600',
        createdAt: now.subtract(const Duration(hours: 8)),
        likeCount: 891,
        commentCount: 56,
      ),
      FeedPost(
        id: 'seed_4',
        authorId: 'u_4',
        authorName: 'Ayu Lestari',
        authorUsername: 'ayulestari',
        authorHeadline: 'Teknik Industri 2022',
        content:
            'Workshop Lean Manufacturing bersama alumni di kampus. Ilmu yang '
            'sangat aplikatif untuk dunia kerja nanti 📈',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        likeCount: 76,
        commentCount: 8,
      ),
      FeedPost(
        id: 'seed_5',
        authorId: 'u_5',
        authorName: 'Fajar Ramadhan',
        authorUsername: 'fajarrmdhn',
        authorHeadline: 'Arsitektur 2021',
        content:
            'Maket studio arsitektur nusantara. Butuh 3 minggu pengerjaan, '
            'tapi hasilnya memuaskan! 🏛️',
        imageUrl: 'https://picsum.photos/seed/itenas5/800/600',
        createdAt: now.subtract(const Duration(days: 2)),
        likeCount: 512,
        commentCount: 41,
      ),
      FeedPost(
        id: 'seed_6',
        authorId: 'u_6',
        authorName: 'Nadia Putri',
        authorUsername: 'nadiap',
        authorHeadline: 'Teknik Elektro 2023',
        content:
            'Tim robotik ITENAS juara 2 kompetisi nasional! Bangga banget '
            'bisa bawa nama kampus 🤖🏆',
        imageUrl: 'https://picsum.photos/seed/itenas6/800/600',
        createdAt: now.subtract(const Duration(days: 4)),
        likeCount: 1420,
        commentCount: 98,
      ),
    ];
  }

  Future<Map<String, dynamic>> _savedPosts() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_kPosts);
    if (raw == null || raw.isEmpty) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<Set<String>> _likedIds() async {
    final prefs = await _prefs;
    return (prefs.getStringList(_kLikes) ?? <String>[]).toSet();
  }

  @override
  Future<List<FeedPost>> fetchPosts({int limit = 30}) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));

    final liked = await _likedIds();
    final saved = await _savedPosts();

    // Postingan baru dari pengguna (paling atas).
    final mine = saved.values
        .map((e) => FeedPost.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    final all = <FeedPost>[
      ...mine,
      ...samplePosts().map(
        (p) => p.copyWith(liked: liked.contains(p.id)),
      ),
    ];

    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all.take(limit).toList();
  }

  @override
  Future<FeedPost> createPost({
    required String content,
    required String imageUrl,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final prefs = await _prefs;
    final saved = await _savedPosts();

    final id = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final post = FeedPost(
      id: id,
      authorId: 'me',
      authorName: 'Saya',
      authorUsername: 'saya',
      authorHeadline: 'Mahasiswa ITENAS',
      content: content,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      likeCount: 0,
      commentCount: 0,
    );

    saved[id] = post.toMap();
    await prefs.setString(_kPosts, jsonEncode(saved));
    return post;
  }

  @override
  Future<bool> toggleLike(FeedPost post) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));

    final prefs = await _prefs;
    final liked = await _likedIds();
    final isLiked = liked.contains(post.id);

    if (isLiked) {
      liked.remove(post.id);
    } else {
      liked.add(post.id);
    }
    await prefs.setStringList(_kLikes, liked.toList());
    return !isLiked;
  }

  @override
  Future<String> uploadPostImage({
    required List<int> bytes,
    required String fileName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  // ---------- Komentar (mode demo, in-memory) ----------
  final Map<String, List<PostComment>> _comments = {};

  @override
  Future<List<PostComment>> fetchComments(String postId) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return List<PostComment>.from(_comments[postId] ?? const []);
  }

  @override
  Future<PostComment> addComment({
    required String postId,
    required String content,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final comment = PostComment(
      id: 'c_${DateTime.now().microsecondsSinceEpoch}',
      postId: postId,
      authorId: 'me',
      authorName: 'Saya',
      content: content,
      createdAt: DateTime.now(),
    );
    _comments.putIfAbsent(postId, () => []).add(comment);
    return comment;
  }

  @override
  Future<void> deletePost(String postId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final prefs = await _prefs;
    final saved = await _savedPosts();

    if (saved.containsKey(postId)) {
      saved.remove(postId);
      await prefs.setString(_kPosts, jsonEncode(saved));
    } else {
      // Postingan contoh (seed) tidak bisa dihapus permanen.
      throw Exception(
        'Postingan contoh tidak bisa dihapus. Hanya postingan milikmu '
        'yang bisa dihapus.',
      );
    }
  }
}
