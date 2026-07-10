// Dart imports:
import 'dart:convert';
import 'dart:math';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import '../../../../foundation/toast.dart';
import '../../../cache/providers.dart';
import '../../../config_widgets/website_logo.dart';
import '../../../configs/config/types.dart';
import '../../../configs/manage/providers.dart';
import '../../../search/search/routes.dart';
import '../../../search_tabs/providers.dart';
import 'tag_preview_grid.dart';
import 'tag_preview_provider.dart';

const kTagPreviewGeometryKey = 'tag_preview_geometry';

const _kMinWindowSize = Size(240, 300);
const _kBubbleSize = 52.0;

/// Hosts the floating tag preview window above the whole app so it survives
/// navigation between pages.
class TagPreviewWindowHost extends ConsumerStatefulWidget {
  const TagPreviewWindowHost({super.key});

  @override
  ConsumerState<TagPreviewWindowHost> createState() =>
      _TagPreviewWindowHostState();
}

class _TagPreviewWindowHostState extends ConsumerState<TagPreviewWindowHost> {
  Offset? _position;
  Size? _size;

  @override
  void initState() {
    super.initState();
    _loadGeometry();
  }

  void _loadGeometry() {
    try {
      final raw = ref.read(miscDataBoxProvider).get(kTagPreviewGeometryKey);
      if (raw == null || raw.isEmpty) return;

      final json = jsonDecode(raw);
      if (json case {
        'dx': final num dx,
        'dy': final num dy,
        'w': final num w,
        'h': final num h,
      }) {
        _position = Offset(dx.toDouble(), dy.toDouble());
        _size = Size(w.toDouble(), h.toDouble());
      }
    } catch (_) {
      // Corrupted geometry data, fall back to defaults.
    }
  }

  void _saveGeometry() {
    final position = _position;
    final size = _size;
    if (position == null || size == null) return;

    ref
        .read(miscDataBoxProvider)
        .put(
          kTagPreviewGeometryKey,
          jsonEncode({
            'dx': position.dx,
            'dy': position.dy,
            'w': size.width,
            'h': size.height,
          }),
        );
  }

  Size _defaultSize(Size screen) => Size(
    min(screen.width * 0.92, 480),
    min(screen.height * 0.62, 680),
  );

  Offset _initialPosition(Size screen, Size windowSize) => Offset(
    (screen.width - windowSize.width) / 2,
    max((screen.height - windowSize.height) / 4, 0),
  );

  void _clampToScreen(Size screen) {
    final position = _position;
    final size = _size;
    if (position == null || size == null) return;

    _size = Size(
      size.width.clamp(_kMinWindowSize.width, screen.width),
      size.height.clamp(_kMinWindowSize.height, screen.height * 0.92),
    );
    _position = Offset(
      position.dx.clamp(
        -(_size!.width - 60),
        screen.width - 60,
      ),
      position.dy.clamp(0, screen.height - 60),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tagPreviewProvider);

    if (state == null) {
      return const SizedBox.shrink();
    }

    final screen = MediaQuery.sizeOf(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);

    final size = _size ?? _defaultSize(screen);
    _size = size;
    final position = _position ?? _initialPosition(screen, size);
    _position = position;
    _clampToScreen(screen);

    return Stack(
      children: [
        Positioned(
          left: _position!.dx,
          top: _position!.dy + viewPadding.top,
          child: state.minimized
              ? _MinimizedBubble(
                  state: state,
                  onDrag: (delta) => setState(() {
                    _position = _position! + delta;
                    _clampToScreen(screen);
                  }),
                  onDragEnd: _saveGeometry,
                  onTap: () =>
                      ref.read(tagPreviewProvider.notifier).setMinimized(false),
                )
              : TagPreviewWindow(
                  state: state,
                  size: _size!,
                  onDrag: (delta) => setState(() {
                    _position = _position! + delta;
                    _clampToScreen(screen);
                  }),
                  onDragEnd: _saveGeometry,
                  onResize: (delta) => setState(() {
                    _size = Size(
                      (_size!.width + delta.dx).clamp(
                        _kMinWindowSize.width,
                        screen.width,
                      ),
                      (_size!.height + delta.dy).clamp(
                        _kMinWindowSize.height,
                        screen.height * 0.92,
                      ),
                    );
                  }),
                  onResizeEnd: _saveGeometry,
                ),
        ),
      ],
    );
  }
}

class _MinimizedBubble extends StatelessWidget {
  const _MinimizedBubble({
    required this.state,
    required this.onDrag,
    required this.onDragEnd,
    required this.onTap,
  });

  final TagPreviewState state;
  final void Function(Offset delta) onDrag;
  final VoidCallback onDragEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onPanUpdate: (details) => onDrag(details.delta),
      onPanEnd: (_) => onDragEnd(),
      child: Material(
        elevation: 6,
        shape: const CircleBorder(),
        color: colorScheme.primaryContainer,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: _kBubbleSize,
            height: _kBubbleSize,
            child: Icon(
              Symbols.preview,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class TagPreviewWindow extends ConsumerWidget {
  const TagPreviewWindow({
    required this.state,
    required this.size,
    required this.onDrag,
    required this.onDragEnd,
    required this.onResize,
    required this.onResizeEnd,
    super.key,
  });

  final TagPreviewState state;
  final Size size;
  final void Function(Offset delta) onDrag;
  final VoidCallback onDragEnd;
  final void Function(Offset delta) onResize;
  final VoidCallback onResizeEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifier = ref.watch(tagPreviewProvider.notifier);
    final configs = ref.watch(booruConfigProvider);
    final config = configs.firstWhereOrNull((e) => e.id == state.configId);

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(12),
      color: colorScheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Column(
          children: [
            _WindowHeader(
              state: state,
              config: config,
              onDrag: onDrag,
              onDragEnd: onDragEnd,
            ),
            _BooruSelectorStrip(
              configs: configs,
              state: state,
              onConfigSelected: notifier.selectConfig,
              onFilterCycle: notifier.cycleFilterMode,
            ),
            Expanded(
              child: config == null
                  ? Center(
                      child: Text(
                        'No booru profile selected',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: TagPreviewGrid(
                            key: ValueKey(
                              (state.configId, state.effectiveQuery),
                            ),
                            config: config,
                            query: state.effectiveQuery,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onPanUpdate: (details) => onResize(details.delta),
                            onPanEnd: (_) => onResizeEnd(),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              color: Colors.transparent,
                              child: Icon(
                                Symbols.south_east,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowHeader extends ConsumerWidget {
  const _WindowHeader({
    required this.state,
    required this.config,
    required this.onDrag,
    required this.onDragEnd,
  });

  final TagPreviewState state;
  final BooruConfig? config;
  final void Function(Offset delta) onDrag;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifier = ref.watch(tagPreviewProvider.notifier);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) => onDrag(details.delta),
      onPanEnd: (_) => onDragEnd(),
      child: Container(
        color: colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.only(left: 10, right: 2),
        height: 40,
        child: Row(
          children: [
            Icon(
              Symbols.drag_indicator,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                state.effectiveQuery,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            _HeaderIconButton(
              icon: Symbols.tab_new_right,
              onPressed: () {
                final config = this.config;
                if (config == null) return;

                ref
                    .read(searchTabsProvider.notifier)
                    .add(
                      query: state.effectiveQuery,
                      configId: config.id,
                      activate: false,
                    );

                showSuccessToast(context, 'Added to tabs');
              },
            ),
            _HeaderIconButton(
              icon: Symbols.open_in_new,
              onPressed: () {
                final config = this.config;

                if (config != null &&
                    ref.read(currentBooruConfigProvider).id != config.id) {
                  ref.read(currentBooruConfigProvider.notifier).update(config);
                }

                goToSearchPage(ref, tag: state.effectiveQuery);
              },
            ),
            _HeaderIconButton(
              icon: Symbols.minimize,
              onPressed: () => notifier.setMinimized(true),
            ),
            _HeaderIconButton(
              icon: Symbols.close,
              onPressed: notifier.close,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _BooruSelectorStrip extends StatelessWidget {
  const _BooruSelectorStrip({
    required this.configs,
    required this.state,
    required this.onConfigSelected,
    required this.onFilterCycle,
  });

  final List<BooruConfig> configs;
  final TagPreviewState state;
  final void Function(int configId) onConfigSelected;
  final VoidCallback onFilterCycle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: configs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                final config = configs[index];
                final selected = config.id == state.configId;

                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onConfigSelected(config.id),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: selected
                          ? colorScheme.secondaryContainer
                          : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? colorScheme.primary
                            : Colors.transparent,
                      ),
                    ),
                    child: ConfigAwareWebsiteLogo.fromConfig(
                      config.auth,
                      width: 22,
                      height: 22,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 4),
          _FilterCycleButton(
            mode: state.filterMode,
            onPressed: onFilterCycle,
          ),
        ],
      ),
    );
  }
}

class _FilterCycleButton extends StatelessWidget {
  const _FilterCycleButton({
    required this.mode,
    required this.onPressed,
  });

  final TagPreviewFilterMode mode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = mode != TagPreviewFilterMode.off;

    return Material(
      color: active ? colorScheme.primary : colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                switch (mode) {
                  TagPreviewFilterMode.off => Symbols.animation,
                  TagPreviewFilterMode.animated => Symbols.animation,
                  TagPreviewFilterMode.video => Symbols.videocam,
                },
                size: 16,
                color: active
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                switch (mode) {
                  TagPreviewFilterMode.off => 'all',
                  TagPreviewFilterMode.animated => 'animated',
                  TagPreviewFilterMode.video => 'video',
                },
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
