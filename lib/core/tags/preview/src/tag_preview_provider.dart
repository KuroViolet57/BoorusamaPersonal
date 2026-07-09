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

class TagPreviewNotifier extends Notifier<TagPreviewState?> {
  @override
  TagPreviewState? build() => null;

  void open({
    required String tag,
    required int configId,
  }) {
    state = TagPreviewState(
      tag: tag,
      configId: configId,
    );
  }

  void close() {
    state = null;
  }

  void selectConfig(int configId) {
    state = state?.copyWith(configId: configId);
  }

  void cycleFilterMode() {
    final current = state;
    if (current == null) return;

    state = current.copyWith(filterMode: current.filterMode.next);
  }

  void setMinimized(bool value) {
    state = state?.copyWith(minimized: value);
  }
}
