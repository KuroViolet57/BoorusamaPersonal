// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import '../../configs/config/types.dart';
import '../../configs/manage/providers.dart';
import 'providers/preview_controller.dart';

/// Opens the floating preview overlay for [tag].
///
/// When [fromAuth] is provided, the overlay's selected booru defaults to
/// the matching config; otherwise it falls back to the current booru.
void openTagPreview(
  WidgetRef ref, {
  required String tag,
  BooruConfigAuth? fromAuth,
}) {
  final configs = ref.read(booruConfigProvider);
  if (configs.isEmpty) return;

  final fallbackId = ref.read(currentBooruConfigProvider).id;
  final preferredId = fromAuth != null
      ? configs
          .where(
            (c) =>
                c.auth.booruType == fromAuth.booruType &&
                c.auth.url == fromAuth.url,
          )
          .map((c) => c.id)
          .firstOrNull
      : null;

  ref.read(previewControllerProvider.notifier).open(
    tag: tag,
    configId: preferredId ?? fallbackId,
  );
}
