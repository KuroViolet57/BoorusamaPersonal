// Package imports:
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import '../../../configs/config/types.dart';
import '../../../configs/manage/providers.dart';
import '../../../posts/post/providers.dart';
import '../../../posts/post/types.dart';
import '../types/anim_video_mode.dart';
import '../types/preview_state.dart';

const int _kPreviewPageSize = 30;

final previewControllerProvider =
    NotifierProvider<PreviewController, PreviewState?>(
      PreviewController.new,
      name: 'previewControllerProvider',
    );

class PreviewController extends Notifier<PreviewState?> {
  /// LIFO stack of previews — one entry per navigation depth that opened a
  /// preview. The visible preview is whichever entry sits at the route depth
  /// reported by [PreviewRouteObserver].
  final List<_Entry> _stack = <_Entry>[];
  int _currentDepth = 0;

  @override
  PreviewState? build() => null;

  /// Push a new preview owned by the current navigation depth, replacing any
  /// existing preview already at this depth.
  void open({
    required String tag,
    required int configId,
  }) {
    _stack.removeWhere((e) => e.depth == _currentDepth);
    _stack.add(
      _Entry(
        depth: _currentDepth,
        state: PreviewState(tag: tag, configId: configId),
      ),
    );
    _recompute();
  }

  /// Manually dismiss the preview owned by the current depth.
  void close() {
    _stack.removeWhere((e) => e.depth == _currentDepth);
    _recompute();
  }

  /// Internal: called by [PreviewRouteObserver].
  void onPush() {
    _currentDepth += 1;
    _recompute();
  }

  void onPop() {
    if (_currentDepth > 0) _currentDepth -= 1;
    _stack.removeWhere((e) => e.depth > _currentDepth);
    _recompute();
  }

  void setConfig(int configId) {
    _updateTop((s) => s.copyWith(configId: configId));
  }

  void cycleAnimVideo() {
    _updateTop((s) => s.copyWith(mode: s.mode.next));
  }

  void setMode(AnimVideoMode mode) {
    _updateTop((s) => s.copyWith(mode: mode));
  }

  void _updateTop(PreviewState Function(PreviewState) update) {
    final i = _stack.lastIndexWhere((e) => e.depth == _currentDepth);
    if (i < 0) return;
    _stack[i] = _stack[i].copyWith(state: update(_stack[i].state));
    _recompute();
  }

  void _recompute() {
    if (_stack.isEmpty) {
      state = null;
      return;
    }
    final top = _stack.last;
    state = top.depth == _currentDepth ? top.state : null;
  }
}

class _Entry {
  const _Entry({required this.depth, required this.state});

  final int depth;
  final PreviewState state;

  _Entry copyWith({PreviewState? state}) =>
      _Entry(depth: depth, state: state ?? this.state);
}

final previewPostsProvider =
    AsyncNotifierProvider.autoDispose<PreviewPostsNotifier, List<Post>>(
  PreviewPostsNotifier.new,
);

class PreviewPostsNotifier extends AutoDisposeAsyncNotifier<List<Post>> {
  int _page = 1;
  bool _exhausted = false;
  bool _loadingMore = false;

  @override
  Future<List<Post>> build() async {
    // build() re-runs whenever the preview state changes (config / tag / mode
    // toggle). Reset pagination on every rebuild.
    _page = 1;
    _exhausted = false;
    _loadingMore = false;
    final s = ref.watch(previewControllerProvider);
    if (s == null) return const [];
    return _fetch(s, _page);
  }

  Future<List<Post>> _fetch(PreviewState s, int page) async {
    final configs = ref.read(booruConfigProvider);
    final config = configs.firstWhereOrNull((c) => c.id == s.configId);
    if (config == null) return const [];
    final repo = ref.read(postRepoProvider(config.search));
    final always = config.alwaysIncludeTags?.includedTags ?? const <String>[];
    final tags = s.effectiveQueryTags(always);
    final query = tags.join(' ');
    final result = await repo
        .getPosts(query, page, limit: _kPreviewPageSize)
        .run();
    return result.fold(
      (_) => const <Post>[],
      (r) {
        if (r.posts.isEmpty) _exhausted = true;
        return r.posts;
      },
    );
  }

  Future<void> loadMore() async {
    if (_loadingMore || _exhausted) return;
    final current = state.valueOrNull;
    if (current == null) return;
    final s = ref.read(previewControllerProvider);
    if (s == null) return;
    _loadingMore = true;
    try {
      final next = await _fetch(s, _page + 1);
      if (next.isEmpty) {
        _exhausted = true;
      } else {
        _page += 1;
        state = AsyncValue.data([...current, ...next]);
      }
    } finally {
      _loadingMore = false;
    }
  }

  bool get isExhausted => _exhausted;
  bool get isLoadingMore => _loadingMore;
}
