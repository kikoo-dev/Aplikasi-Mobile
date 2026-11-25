import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../models/feed_post.dart';
import '../../models/post_comment.dart';
import '../../models/user_profile.dart';
import '../../services/feed_service.dart';
import '../../widgets/profile_avatar.dart';

/// Halaman komentar sebuah postingan.
class CommentsScreen extends StatefulWidget {
  final FeedPost post;
  final FeedService feed;

  const CommentsScreen({
    super.key,
    required this.post,
    required this.feed,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();

  final List<PostComment> _comments = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.feed.fetchComments(widget.post.id);
      if (!mounted) return;
      setState(() {
        _comments
          ..clear()
          ..addAll(items);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final comment = await widget.feed.addComment(
        postId: widget.post.id,
        content: text,
      );
      if (!mounted) return;
      setState(() {
        _comments.add(comment);
        _ctrl.clear();
        _sending = false;
      });
      _focus.unfocus();
      // Scroll ke bawah
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: const Color(0xFFD93025),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myProfile = AppScope.of(context).profile ?? UserProfile.empty;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF7F3EF),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Komentar',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            Text(
              '${_comments.length} komentar',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white38 : AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : _error != null
                    ? _ErrorView(message: _error!, onRetry: _load)
                    : _comments.isEmpty
                        ? const _EmptyComments()
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                            itemCount: _comments.length,
                            itemBuilder: (context, i) => _CommentTile(
                              comment: _comments[i],
                              isMine: _comments[i].authorId ==
                                  (AppScope.read(context).user?.id ?? ''),
                            ),
                          ),
          ),
          _Composer(
            controller: _ctrl,
            focusNode: _focus,
            sending: _sending,
            profile: myProfile,
            onSend: _send,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final UserProfile profile;
  final VoidCallback onSend;
  final bool isDark;

  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.profile,
    required this.onSend,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.lineDark : AppColors.line,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ProfileAvatar(profile: profile, size: 34),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 4,
              maxLength: 500,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : AppColors.ink,
              ),
              decoration: InputDecoration(
                hintText: 'Tulis komentar...',
                counterText: '',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.orangeSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: sending ? null : onSend,
              child: Padding(
                padding: const EdgeInsets.all(11),
                child: sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final PostComment comment;
  final bool isMine;

  const _CommentTile({required this.comment, this.isMine = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatar(
            profile: UserProfile(
              id: comment.authorId,
              email: '',
              fullName: comment.authorName,
              avatarUrl: comment.authorAvatar,
            ),
            size: 36,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(13, 10, 13, 11),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isDark ? AppColors.lineDark : AppColors.line,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isMine ? 'Kamu' : comment.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        waktuRelatif(comment.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.content,
                    style: TextStyle(
                      fontSize: 12.8,
                      height: 1.5,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.88)
                          : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mode_comment_outlined,
            size: 44,
            color: isDark ? Colors.white24 : AppColors.inkMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada komentar',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Jadilah yang pertama berkomentar',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.white38 : AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 42,
              color: isDark ? Colors.white24 : AppColors.inkMuted,
            ),
            const SizedBox(height: 14),
            Text(
              message.replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: isDark ? Colors.white54 : AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(0, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
