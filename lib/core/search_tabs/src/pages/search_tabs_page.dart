// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import '../../../config_widgets/website_logo.dart';
import '../../../configs/config/types.dart';
import '../../../configs/manage/providers.dart';
import '../../../search/search/routes.dart';
import '../providers/search_tabs_provider.dart';
import '../types/search_tab.dart';
import '../widgets/search_tab_view.dart';
import 'tab_manager_sheet.dart';

class SearchTabsPage extends ConsumerStatefulWidget {
  const SearchTabsPage({super.key});

  @override
  ConsumerState<SearchTabsPage> createState() => _SearchTabsPageState();
}

class _SearchTabsPageState extends ConsumerState<SearchTabsPage> {
  // LRU list of mounted tab ids, most recently used last
  final List<int> _live = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final tab = ref.read(searchTabsProvider).activeTab;
      if (tab != null) {
        _syncConfig(tab);
      }
    });
  }

  void _syncConfig(SearchTab tab) {
    final config = ref.read(searchTabConfigProvider(tab.configId));

    if (config != null &&
        ref.read(currentBooruConfigProvider).id != config.id) {
      ref.read(currentBooruConfigProvider.notifier).update(config);
    }
  }

  void _activate(SearchTab tab) {
    ref.read(searchTabsProvider.notifier).activate(tab.id);
    _syncConfig(tab);
  }

  void _addTab() {
    goToQuickSearchPage(
      context,
      ref: ref,
      onSubmitted: (context, text, isRaw) {
        Navigator.of(context).pop();
        _createTab(text);
      },
      onSelected: (tag, isRaw) {
        _createTab(tag);
      },
    );
  }

  void _createTab(String query) {
    if (query.trim().isEmpty) return;

    final tab = ref
        .read(searchTabsProvider.notifier)
        .add(
          query: query.trim(),
          configId: ref.read(currentBooruConfigProvider).id,
        );

    _activate(tab);
  }

  void _openTabManager() {
    showTabManagerSheet(
      context,
      onTabSelected: _activate,
    );
  }

  void _updateLiveTabs(SearchTabsState state) {
    final liveIds = state.tabs.map((e) => e.id).toSet();
    _live.removeWhere((id) => !liveIds.contains(id));

    final activeId = state.activeTab?.id;
    if (activeId != null) {
      _live
        ..remove(activeId)
        ..add(activeId);

      while (_live.length > kMaxLiveSearchTabs) {
        _live.removeAt(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchTabsProvider);
    final activeTab = state.activeTab;

    _updateLiveTabs(state);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.tabs.isEmpty ? 'Tabs' : 'Tabs (${state.tabs.length})',
        ),
        actions: [
          IconButton(
            icon: const Icon(Symbols.add),
            tooltip: 'New tab',
            onPressed: _addTab,
          ),
          IconButton(
            icon: const Icon(Symbols.stacks),
            tooltip: 'Tab manager',
            onPressed: state.tabs.isEmpty ? null : _openTabManager,
          ),
        ],
      ),
      body: state.tabs.isEmpty
          ? _EmptyTabsView(onAddTab: _addTab)
          : Column(
              children: [
                _TabStrip(
                  state: state,
                  onTabTap: _activate,
                  onTabLongPress: (tab) => _showTabOptions(context, tab),
                  onAddTab: _addTab,
                ),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      for (final id in _live)
                        if (state.tabs.where((e) => e.id == id).firstOrNull
                            case final tab?)
                          Offstage(
                            offstage: tab.id != activeTab?.id,
                            child: TickerMode(
                              enabled: tab.id == activeTab?.id,
                              child: SearchTabView(
                                key: ValueKey(tab.id),
                                tab: tab,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _showTabOptions(BuildContext context, SearchTab tab) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                tab.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Symbols.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _showRenameDialog(tab);
              },
            ),
            ListTile(
              leading: const Icon(Symbols.search),
              title: const Text('Open in search page'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                goToSearchPage(ref, tag: tab.query);
              },
            ),
            ListTile(
              leading: const Icon(Symbols.tab_close),
              title: const Text('Close other tabs'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                ref.read(searchTabsProvider.notifier).closeOthers(tab.id);
              },
            ),
            ListTile(
              leading: const Icon(Symbols.close),
              title: const Text('Close tab'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                ref.read(searchTabsProvider.notifier).remove(tab.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(SearchTab tab) {
    final controller = TextEditingController(text: tab.label ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename tab'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Leave empty to use the query',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(searchTabsProvider.notifier)
                  .rename(tab.id, controller.text);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }
}

class _TabStrip extends ConsumerWidget {
  const _TabStrip({
    required this.state,
    required this.onTabTap,
    required this.onTabLongPress,
    required this.onAddTab,
  });

  final SearchTabsState state;
  final void Function(SearchTab tab) onTabTap;
  final void Function(SearchTab tab) onTabLongPress;
  final VoidCallback onAddTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: state.tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final tab = state.tabs[index];
                final selected = tab.id == state.activeId;

                return _TabChip(
                  tab: tab,
                  selected: selected,
                  onTap: () => onTabTap(tab),
                  onLongPress: () => onTabLongPress(tab),
                  onClose: selected
                      ? () =>
                            ref.read(searchTabsProvider.notifier).remove(tab.id)
                      : null,
                );
              },
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Symbols.add,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: onAddTab,
          ),
        ],
      ),
    );
  }
}

class _TabChip extends ConsumerWidget {
  const _TabChip({
    required this.tab,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    this.onClose,
  });

  final SearchTab tab;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final config = ref.watch(searchTabConfigProvider(tab.configId));

    return Material(
      color: selected
          ? colorScheme.secondaryContainer
          : colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (config != null) ...[
                ConfigAwareWebsiteLogo.fromConfig(
                  config.auth,
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: 6),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  tab.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (onClose != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onClose,
                  child: Icon(
                    Symbols.close,
                    size: 16,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTabsView extends StatelessWidget {
  const _EmptyTabsView({
    required this.onAddTab,
  });

  final VoidCallback onAddTab;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Symbols.tab,
            size: 56,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          const Text(
            'No tabs yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Long-press any tag and pick "Add to tab", or create one manually.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAddTab,
            icon: const Icon(Symbols.add),
            label: const Text('New tab'),
          ),
        ],
      ),
    );
  }
}
