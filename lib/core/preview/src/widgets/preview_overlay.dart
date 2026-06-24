// Dart imports:
import 'dart:math' as math;

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import '../../../configs/config/types.dart';
import '../../../configs/manage/providers.dart';
import '../../../images/booru_image.dart';
import '../providers/preview_controller.dart';
import '../types/anim_video_mode.dart';

class PreviewOverlay extends ConsumerStatefulWidget {
  const PreviewOverlay({super.key});

  @override
  ConsumerState<PreviewOverlay> createState() => _PreviewOverlayState();
}

class _PreviewOverlayState extends ConsumerState<PreviewOverlay> {
  Offset? _offset;
  Size _size = const Size(320, 420);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(previewControllerProvider);
    if (state == null) return const SizedBox.shrink();

    final screen = MediaQuery.sizeOf(context);
    final maxW = screen.width;
    final maxH = screen.height;
    final w = math.min(_size.width, maxW - 16);
    final h = math.min(_size.height, maxH - 80);
    final offset = _offset ??
        Offset(
          (maxW - w) / 2,
          math.max((maxH - h) / 2, 40),
        );

    final clampedDx = offset.dx.clamp(0.0, maxW - w);
    final clampedDy = offset.dy.clamp(20.0, maxH - h - 20);

    return Stack(
      // No outer Material/coloring -> taps outside the panel pass through to
      // whatever route is currently mounted underneath.
      children: [
        Positioned(
          left: clampedDx,
          top: clampedDy,
          child: SizedBox(
            width: w,
            height: h,
            child: _PreviewPanel(
              onDragHandle: (delta) {
                setState(() {
                  _offset = Offset(
                    (clampedDx + delta.dx).clamp(0.0, maxW - w),
                    (clampedDy + delta.dy).clamp(20.0, maxH - h - 20),
                  );
                });
              },
              onResize: (delta) {
                setState(() {
                  _size = Size(
                    (_size.width + delta.dx).clamp(240.0, maxW - 16),
                    (_size.height + delta.dy).clamp(280.0, maxH - 80),
                  );
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewPanel extends ConsumerWidget {
  const _PreviewPanel({
    required this.onDragHandle,
    required this.onResize,
  });

  final void Function(Offset delta) onDragHandle;
  final void Function(Offset delta) onResize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(previewControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    if (state == null) return const SizedBox.shrink();

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: colorScheme.surfaceContainer,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DragHeader(
              tag: state.tag,
              onDrag: onDragHandle,
              onClose: () =>
                  ref.read(previewControllerProvider.notifier).close(),
            ),
            const _BooruSelectorStrip(),
            const Divider(height: 1, thickness: 0.5),
            const Expanded(child: _PreviewGrid()),
            _ResizeFooter(onResize: onResize),
          ],
        ),
      ),
    );
  }
}

class _DragHeader extends StatelessWidget {
  const _DragHeader({
    required this.tag,
    required this.onDrag,
    required this.onClose,
  });

  final String tag;
  final void Function(Offset delta) onDrag;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onPanUpdate: (d) => onDrag(d.delta),
      child: Container(
        color: colorScheme.surfaceContainerHigh,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            const Icon(Symbols.drag_indicator, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Preview: $tag',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Close preview',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(Symbols.close, size: 18),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

class _BooruSelectorStrip extends ConsumerWidget {
  const _BooruSelectorStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(previewControllerProvider);
    if (state == null) return const SizedBox.shrink();

    final configs = ref.watch(booruConfigProvider);
    final selectedConfig =
        configs.firstWhereOrNull((c) => c.id == state.configId);

    final always =
        selectedConfig?.alwaysIncludeTags?.includedTags ?? const <String>[];
    final isModeRedundant = state.mode.extraTag != null &&
        always.contains(state.mode.extraTag);

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: configs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final c = configs[i];
                final selected = c.id == state.configId;
                return ChoiceChip(
                  selected: selected,
                  label: Text(
                    c.name.isNotEmpty ? c.name : c.auth.booruType.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => ref
                      .read(previewControllerProvider.notifier)
                      .setConfig(c.id),
                );
              },
            ),
          ),
          _ModeToggleButton(redundant: isModeRedundant),
        ],
      ),
    );
  }
}

class _ModeToggleButton extends ConsumerWidget {
  const _ModeToggleButton({required this.redundant});

  final bool redundant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(previewControllerProvider);
    if (state == null) return const SizedBox.shrink();

    final (icon, label) = switch (state.mode) {
      AnimVideoMode.off => (Symbols.image, 'Off'),
      AnimVideoMode.animated => (Symbols.animation, 'animated'),
      AnimVideoMode.video => (Symbols.smart_display, 'video'),
    };

    return Tooltip(
      message: switch (state.mode) {
        AnimVideoMode.off => 'Add "animated" tag',
        AnimVideoMode.animated => 'Swap to "video"',
        AnimVideoMode.video => 'Disable',
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: TextButton.icon(
          onPressed: () =>
              ref.read(previewControllerProvider.notifier).cycleAnimVideo(),
          icon: Icon(icon, size: 18),
          label: Text(
            redundant ? '$label (in defaults)' : label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _PreviewGrid extends ConsumerWidget {
  const _PreviewGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(previewControllerProvider);
    final async = ref.watch(previewPostsProvider);
    final configs = ref.watch(booruConfigProvider);
    final selectedAuth = state == null
        ? null
        : configs
            .firstWhereOrNull((c) => c.id == state.configId)
            ?.auth;
    return async.when(
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No results',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          );
        }
        if (selectedAuth == null) {
          return const SizedBox.shrink();
        }
        return GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: posts.length,
          itemBuilder: (context, i) {
            final p = posts[i];
            final url = p.thumbnailImageUrl.isNotEmpty
                ? p.thumbnailImageUrl
                : p.sampleImageUrl;
            if (url.isEmpty) {
              return Container(color: Colors.black12);
            }
            return BooruImage(
              imageUrl: url,
              config: selectedAuth,
              fit: BoxFit.cover,
              forceCover: true,
              borderRadius: BorderRadius.circular(4),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            'Error: $e',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _ResizeFooter extends StatelessWidget {
  const _ResizeFooter({required this.onResize});

  final void Function(Offset delta) onResize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onPanUpdate: (d) => onResize(d.delta),
      child: Container(
        color: colorScheme.surfaceContainerHigh,
        height: 18,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 6),
        child: const Icon(
          Symbols.aspect_ratio,
          size: 14,
        ),
      ),
    );
  }
}
