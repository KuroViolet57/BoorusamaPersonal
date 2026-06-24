// Package imports:
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import '../../../configs/manage/providers.dart';
import '../../../posts/post/providers.dart';
import '../../../posts/post/types.dart';
import '../types/anim_video_mode.dart';
import '../types/preview_state.dart';

final previewControllerProvider =
    NotifierProvider<PreviewController, PreviewState?>(
      PreviewController.new,
      name: 'previewControllerProvider',
    );

class PreviewController extends Notifier<PreviewState?> {
  @override
  PreviewState? build() => null;

  void open({
    required String tag,
    required int configId,
  }) {
    state = PreviewState(
      tag: tag,
      configId: configId,
    );
  }

  void close() {
    state = null;
  }

  void setConfig(int configId) {
    final s = state;
    if (s == null) return;
    state = s.copyWith(configId: configId);
  }

  void cycleAnimVideo() {
    final s = state;
    if (s == null) return;
    state = s.copyWith(mode: s.mode.next);
  }

  void setMode(AnimVideoMode mode) {
    final s = state;
    if (s == null) return;
    state = s.copyWith(mode: mode);
  }
}

final previewPostsProvider =
    FutureProvider.autoDispose<List<Post>>((ref) async {
  final state = ref.watch(previewControllerProvider);
  if (state == null) return const [];

  final configs = ref.watch(booruConfigProvider);
  final config = configs.firstWhereOrNull((c) => c.id == state.configId);

  if (config == null) return const [];

  final repo = ref.watch(postRepoProvider(config.search));
  final always = config.alwaysIncludeTags?.includedTags ?? const <String>[];
  final tags = state.effectiveQueryTags(always);

  final query = tags.join(' ');
  final result = await repo.getPosts(query, 1, limit: 30).run();

  return result.fold(
    (_) => const <Post>[],
    (r) => r.posts,
  );
});
