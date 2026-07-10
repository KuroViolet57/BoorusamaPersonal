// Flutter imports:
import 'package:flutter/widgets.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TagPreviewFilterMode {
  off,
  animated,
  video
  ;

  TagPreviewFilterMode get next => switch (this) {
    TagPreviewFilterMode.off => TagPreviewFilterMode.animated,
    TagPreviewFilterMode.animated => TagPreviewFilterMode.video,
    TagPreviewFilterMode.video => TagPreviewFilterMode.off,
  };

  String? get extraTag => switch (this) {
    TagPreviewFilterMode.off => null,
    TagPreviewFilterMode.animated => 'animated',
    TagPreviewFilterMode.video => 'video',
  };
}

class TagPreviewState extends Equatable {
  const TagPreviewState({
    required this.tag,
    required this.configId,
    this.filterMode = TagPreviewFilterMode.off,
    this.minimized = false,
  });

  final String tag;
  final int configId;
  final TagPreviewFilterMode filterMode;
  final bool minimized;

  String get effectiveQuery => switch (filterMode.extraTag) {
    final extra? => '$tag $extra',
    null => tag,
  };

  TagPreviewState copyWith({
    String? tag,
    int? configId,
    TagPreviewFilterMode? filterMode,
    bool? minimized,
  }) {
    return TagPreviewState(
      tag: tag ?? this.tag,
      configId: configId ?? this.configId,
      filterMode: filterMode ?? this.filterMode,
      minimized: minimized ?? this.minimized,
    );
  }

  @override
  List<Object?> get props => [tag, configId, filterMode, minimized];
}

final tagPreviewProvider =
    NotifierProvider<TagPreviewNotifier, TagPreviewState?>(
      TagPreviewNotifier.new,
      name: 'tagPreviewProvider',
    );

/// Each navigation depth owns its own preview slot, so a preview opened on
/// post X stays with X: pushing a new page hides it, popping back restores it
/// and discards any preview opened on deeper pages.
class TagPreviewNotifier extends Notifier<TagPreviewState?> {
  final _stack = <int, TagPreviewState>{};
  var _depth = 0;

  @override
  TagPreviewState? build() => null;

  void open({
    required String tag,
    required int configId,
  }) {
    _stack[_depth] = TagPreviewState(
      tag: tag,
      configId: configId,
    );
    state = _stack[_depth];
  }

  void close() {
    _stack.remove(_depth);
    state = null;
  }

  void selectConfig(int configId) {
    _update((s) => s.copyWith(configId: configId));
  }

  void cycleFilterMode() {
    _update((s) => s.copyWith(filterMode: s.filterMode.next));
  }

  void setMinimized(bool value) {
    _update((s) => s.copyWith(minimized: value));
  }

  void onNavDepthChanged(int depth) {
    if (depth < _depth) {
      _stack.removeWhere((key, _) => key > depth);
    }

    _depth = depth;
    state = _stack[depth];
  }

  void _update(TagPreviewState Function(TagPreviewState state) transform) {
    final current = _stack[_depth];
    if (current == null) return;

    _stack[_depth] = transform(current);
    state = _stack[_depth];
  }
}

/// Tracks page-route depth so the preview window can be tied to the page it
/// was opened from. Non-page routes (dialogs, menus, bottom sheets) are
/// ignored.
class TagPreviewRouteObserver extends NavigatorObserver {
  TagPreviewRouteObserver(this._ref);

  final Ref Function() _ref;
  var _depth = 0;

  void _notify() {
    final depth = _depth;

    Future.microtask(() {
      try {
        _ref().read(tagPreviewProvider.notifier).onNavDepthChanged(depth);
      } catch (_) {
        // Container might be disposed during app shutdown.
      }
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) {
      _depth++;
      _notify();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) {
      _depth--;
      _notify();
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) {
      _depth--;
      _notify();
    }
  }
}
