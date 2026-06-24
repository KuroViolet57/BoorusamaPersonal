// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import '../providers/tab_manager.dart';
import '../types/booru_tab.dart';

Future<void> showTabManagerSheet(
  BuildContext context,
  WidgetRef parentRef,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _TabManagerSheet(),
  );
}

class _TabManagerSheet extends ConsumerWidget {
  const _TabManagerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tabManagerProvider);
    final notifier = ref.read(tabManagerProvider.notifier);
    final mediaSize = MediaQuery.sizeOf(context);

    return SizedBox(
      height: mediaSize.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
            child: Row(
              children: [
                Text(
                  'Tabs (${state.tabs.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: state.tabs.isEmpty
                      ? null
                      : () {
                          notifier.closeAll();
                          Navigator.of(context).pop();
                        },
                  icon: const Icon(Symbols.close),
                  label: const Text('Close all'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: state.tabs.length,
              onReorder: notifier.reorder,
              itemBuilder: (context, i) {
                final tab = state.tabs[i];
                final selected = tab.id == state.currentTabId;
                return _TabRow(
                  key: ValueKey('tab_row_${tab.id}'),
                  tab: tab,
                  selected: selected,
                  alive: state.aliveTabIds.contains(tab.id),
                  onTap: () {
                    notifier.switchTo(tab.id);
                    Navigator.of(context).pop();
                  },
                  onClose: () => notifier.close(tab.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TabRow extends StatelessWidget {
  const _TabRow({
    required this.tab,
    required this.selected,
    required this.alive,
    required this.onTap,
    required this.onClose,
    super.key,
  });

  final BooruTab tab;
  final bool selected;
  final bool alive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colorScheme.secondaryContainer : Colors.transparent,
      child: ListTile(
        title: Text(
          tab.displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          tab.tags.isEmpty ? '(no tags)' : tab.tags.join(' '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        leading: Icon(
          alive ? Symbols.tab_unselected : Symbols.tab,
          color: alive ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Close tab',
              icon: const Icon(Symbols.close),
              onPressed: onClose,
            ),
            const Icon(Symbols.drag_handle, size: 20),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
