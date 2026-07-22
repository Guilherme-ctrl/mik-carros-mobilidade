import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/design/app_colors.dart';
import '../../../../../core/design/app_spacing.dart';
import '../../domain/entities/comment.dart';
import '../../domain/usecases/add_comment.dart';
import '../../domain/usecases/get_comments.dart';
import '../../domain/repositories/missions_repository.dart';
import 'comment_bubble.dart';

class CommentsSection extends StatefulWidget {
  final String requestId;

  const CommentsSection({super.key, required this.requestId});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  List<Comment> _comments = [];
  bool _loading = true;
  bool _sending = false;
  String? _currentUserId;
  StreamSubscription<void>? _realtimeSub;

  late final GetComments _getComments;
  late final AddComment _addComment;
  late final MissionsRepository _repository;

  @override
  void initState() {
    super.initState();
    _getComments = Modular.get<GetComments>();
    _addComment = Modular.get<AddComment>();
    _repository = Modular.get<MissionsRepository>();

    _currentUserId = Supabase.instance.client.auth.currentUser?.id;

    _load();
    _subscribeRealtime();
  }

  Future<void> _load() async {
    final result = await _getComments(widget.requestId);
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _loading = false),
      (comments) {
        setState(() {
          _comments = comments;
          _loading = false;
        });
        _scrollToBottom();
      },
    );
  }

  void _subscribeRealtime() {
    _realtimeSub = _repository.watchComments(widget.requestId).listen((_) {
      _load();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    _controller.clear();
    _focusNode.unfocus();

    final result = await _addComment(widget.requestId, text);
    if (!mounted) return;

    setState(() => _sending = false);

    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message), backgroundColor: AppColors.statusUnavailable),
      ),
      (_) => _scrollToBottom(),
    );
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.s4),
        Text(
          'COMENTÁRIOS',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceDisabled,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s4),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
            child: Text(
              'Nenhum comentário ainda.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.onSurfaceMuted),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView.separated(
              controller: _scrollController,
              shrinkWrap: true,
              itemCount: _comments.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s2),
              itemBuilder: (_, i) {
                final comment = _comments[i];
                final isOwn = comment.authorId == _currentUserId;
                final showAuthor = !isOwn &&
                    (i == 0 || _comments[i - 1].authorId != comment.authorId);
                return CommentBubble(
                  comment: comment,
                  isOwn: isOwn,
                  showAuthor: showAuthor,
                );
              },
            ),
          ),
        const SizedBox(height: AppSpacing.s3),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !_sending,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Adicionar comentário…',
                  hintStyle: const TextStyle(color: AppColors.onSurfaceDisabled),
                  filled: true,
                  fillColor: AppColors.surface2,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s3,
                    vertical: AppSpacing.s2,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.surface3),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.surface3),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.brandPink),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            _sending
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.brandPink,
                      foregroundColor: Colors.white,
                    ),
                  ),
          ],
        ),
      ],
    );
  }
}
