// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import '../types/booru_tab.dart';

class TabsStrip extends StatefulWidget {
  const TabsStrip({
    required this.tabs,
    required this.currentTabId,
    required this.onSwitch,
    required this.onClose,
    required this.onNewTab,
    required this.onOpenManager,
    super.key,
  });

  final List<BooruTab> tabs;
  final String? currentTabId;
  final void Function(String id) onSwitch;
  final void Function(String id) onClose;
  final VoidCallback onNewTab;
  final VoidCallback onOpenManager;

  @override
  State<TabsStrip> createState() => _TabsStripState();
}

class _TabsStripState extends State<TabsStrip> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant TabsStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTabId != widget.currentTabId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrent();
      });
    }
  }

  void _scrollToCurrent() {
    if (!_scrollController.hasClients) return;
    final id = widget.currentTabId;
    if (id == null) return;
    final index = widget.tabs.indexWhere((t) => t.id == id);
    if (index < 0) return;
    const approxWidth = 140.0;
    final target = (index * approxWidth).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: widget.tabs.length,
              itemBuilder: (context, i) {
                final tab = widget.tabs[i];
                final selected = tab.id == widget.currentTabId;
                return _TabChip(
                  tab: tab,
                  selected: selected,
                  onTap: () => widget.onSwitch(tab.id),
                  onClose: () => widget.onClose(tab.id),
                );
              },
            ),
          ),
          IconButton(
            tooltip: 'New tab',
            onPressed: widget.onNewTab,
            icon: const Icon(Symbols.add),
          ),
          IconButton(
            tooltip: 'Tab manager',
            onPressed: widget.onOpenManager,
            icon: const Icon(Symbols.tab),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.tab,
    required this.selected,
    required this.onTap,
    required this.onClose,
  });

  final BooruTab tab;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = selected
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHigh;
    final fg = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.only(
              left: 12,
              right: 4,
              top: 4,
              bottom: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    tab.displayTitle,
                    style: TextStyle(
                      color: fg,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: onClose,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Symbols.close,
                      size: 14,
                      color: fg.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
