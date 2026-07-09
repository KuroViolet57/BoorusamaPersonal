// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import '../../../config_widgets/website_logo.dart';
import '../../../configs/config/types.dart';
import '../providers/search_tabs_provider.dart';
import '../types/search_tab.dart';

void showTabManagerSheet(
  BuildContext context, {
  required void Function(SearchTab tab) onTabSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => TabManagerView(
        scrollController: scrollController,
        onTabSelected: onTabSelected,
      ),
    ),
  );
}

class TabManagerView extends ConsumerWidget {
  const TabManagerView({
    required this.onTabSelected,
    super.key,
    this.scrollController,
  });

  final void Function(SearchTab tab) onTabSelected;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchTabsProvider);
    final notifier = ref.watch(searchTabsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Text(
                'Tab manager',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: state.tabs.isEmpty
                    ? null
                    : () => _confirmClearAll(context, ref),
                icon: const Icon(Symbols.delete_sweep, size: 20),
                label: const Text('Clear all'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: state.tabs.isEmpty
              ? Center(
                  child: Text(
                    'No tabs',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                )
              : ReorderableListView.builder(
                  scrollController: scrollController,
                  itemCount: state.tabs.length,
                  onReorder: notifier.reorder,
                  itemBuilder: (context, index) {
                    final tab = state.tabs[index];
                    final selected = tab.id == state.activeId;

                    return _TabManagerTile(
                      key: ValueKey(tab.id),
                      tab: tab,
                      selected: selected,
                      onTap: () {
                        Navigator.of(context).pop();
                        onTabSelected(tab);
                      },
                      onRemove: () => notifier.remove(tab.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Close all tabs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(searchTabsProvider.notifier).clear();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Close all'),
          ),
        ],
      ),
    );
  }
}

class _TabManagerTile extends ConsumerWidget {
  const _TabManagerTile({
    required this.tab,
    required this.selected,
    required this.onTap,
    required this.onRemove,
    super.key,
  });

  final SearchTab tab;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(searchTabConfigProvider(tab.configId));
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      selected: selected,
      leading: config != null
          ? ConfigAwareWebsiteLogo.fromConfig(
              config.auth,
              width: 24,
              height: 24,
            )
          : Icon(
              Symbols.error,
              color: colorScheme.error,
            ),
      title: Text(
        tab.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        config?.name ?? 'Missing booru profile',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Symbols.close),
            onPressed: onRemove,
          ),
          ReorderableDragStartListener(
            index: _indexOf(ref),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Symbols.drag_handle),
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  int _indexOf(WidgetRef ref) {
    final tabs = ref.read(searchTabsProvider).tabs;

    return tabs.indexWhere((e) => e.id == tab.id);
  }
}
