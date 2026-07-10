// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import '../../../configs/config/types.dart';
import '../../../images/booru_image.dart';
import '../../../posts/details/routes.dart';
import '../../../posts/post/providers.dart';
import '../../../posts/post/types.dart';

class TagPreviewGrid extends ConsumerStatefulWidget {
  const TagPreviewGrid({
    required this.config,
    required this.query,
    super.key,
  });

  final BooruConfig config;
  final String query;

  @override
  ConsumerState<TagPreviewGrid> createState() => _TagPreviewGridState();
}

class _TagPreviewGridState extends ConsumerState<TagPreviewGrid> {
  final _scrollController = ScrollController();
  final _posts = <Post>[];

  var _page = 1;
  var _loading = false;
  var _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetch();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loading || _done) return;

    if (_scrollController.position.extentAfter < 300) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    if (_loading || _done) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ref
        .read(postRepoProvider(widget.config.search))
        .getPosts(widget.query, _page)
        .run();

    if (!mounted) return;

    result.fold(
      (error) {
        setState(() {
          _loading = false;
          _error = 'Failed to load posts';
        });
      },
      (data) {
        setState(() {
          _loading = false;
          _page += 1;

          if (data.posts.isEmpty) {
            _done = true;
          } else {
            final existingIds = _posts.map((e) => e.id).toSet();
            _posts.addAll(
              data.posts.where((e) => !existingIds.contains(e.id)),
            );
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_error != null && _posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.wifi_off,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            TextButton(
              onPressed: () {
                setState(() => _error = null);
                _fetch();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return _loading
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Center(
              child: Text(
                'No posts found',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.72,
      ),
      itemCount: _posts.length + (_loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _posts.length) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final post = _posts[index];

        return _PreviewGridItem(
          post: post,
          config: widget.config,
          onTap: () => goToPostDetailsPageFromPosts(
            ref: ref,
            posts: List<Post>.of(_posts),
            initialIndex: index,
            initialThumbnailUrl: post.thumbnailImageUrl,
            configSearch: widget.config.search,
          ),
        );
      },
    );
  }
}

class _PreviewGridItem extends ConsumerWidget {
  const _PreviewGridItem({
    required this.post,
    required this.config,
    required this.onTap,
  });

  final Post post;
  final BooruConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          BooruImage(
            config: config.auth,
            imageUrl: post.thumbnailImageUrl,
            aspectRatio: null,
            forceCover: true,
            borderRadius: BorderRadius.circular(6),
          ),
          if (post.isVideo)
            const Positioned(
              top: 4,
              left: 4,
              child: Icon(
                Symbols.play_circle,
                size: 18,
                color: Colors.white,
                shadows: [
                  Shadow(blurRadius: 4),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
