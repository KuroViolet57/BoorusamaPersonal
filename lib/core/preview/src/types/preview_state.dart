// Package imports:
import 'package:equatable/equatable.dart';

// Project imports:
import 'anim_video_mode.dart';

class PreviewState extends Equatable {
  const PreviewState({
    required this.tag,
    required this.configId,
    this.mode = AnimVideoMode.off,
  });

  final String tag;
  final int configId;
  final AnimVideoMode mode;

  PreviewState copyWith({
    String? tag,
    int? configId,
    AnimVideoMode? mode,
  }) => PreviewState(
    tag: tag ?? this.tag,
    configId: configId ?? this.configId,
    mode: mode ?? this.mode,
  );

  List<String> effectiveQueryTags(List<String> alwaysIncluded) {
    final base = <String>[tag, ...alwaysIncluded];
    final extra = mode.extraTag;
    if (extra == null) return base;
    if (alwaysIncluded.contains(extra)) return base;
    return [...base, extra];
  }

  @override
  List<Object?> get props => [tag, configId, mode];
}
