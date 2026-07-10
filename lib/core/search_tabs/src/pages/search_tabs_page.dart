// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import '../../../../foundation/toast.dart';
import '../../../config_widgets/website_logo.dart';
import '../../../configs/config/types.dart';
import '../../../configs/manage/providers.dart';
import '../../../search/search/routes.dart';
import '../providers/search_tabs_provider.dart';
import '../routes/route_utils.dart';
import '../types/search_tab.dart';

class SearchTabsPage extends ConsumerStatefulWidget {
  const SearchTabsPage({super.key});

  @override
  ConsumerState<SearchTabsPage> createState() => _SearchTabsPageState();
}

class _SearchTabsPageState extends ConsumerState<SearchTabsPage> {
  final _scrollController = ScrollController();
  final _filterController = TextEditingController();

  var _filterText = '';
  int? _filterConfigId;

  // The booru the manager was opened from; new tabs default to it.
  late final int _contextConfigId;

  @override
  void initState() {
    super.initState();
    _contextConfigId = ref.read(currentBooruConfigProvider).id;
    _filterController.addListener(() {
      setState(() => _filterText = _filterController.text.trim());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  List<SearchTab> _visibleTabs(
    SearchTabsState state,
    SearchTabsSortMode sortMode,
    List<BooruConfig> configs,
  ) {
    var tabs = state.tabs;

    if (_filterConfigId != null) {
      tabs = tabs.where((e) => e.configId == _filterConfigId).toList();
    }

    if (_filterText.isNotEmpty) {
      final needle = _filterText.toLowerCase();
      tabs = tabs
          .where(
            (e) =>
                e.query.toLowerCase().contains(needle) ||
                (e.label?.toLowerCase().contains(needle) ?? false),
          )
          .toList();
    }

    return switch (sortMode) {
      SearchTabsSortMode.manual => tabs,
      SearchTabsSortMode.newestFirst => [
        ...tabs,
      ]..sort((a, b) => b.id.compareTo(a.id)),
      SearchTabsSortMode.oldestFirst => [
        ...tabs,
      ]..sort((a, b) => a.id.compareTo(b.id)),
      SearchTabsSortMode.alphabetical =>
        [...tabs]..sort(
          (a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ),
        ),
      SearchTabsSortMode.alphabeticalDesc =>
        [...tabs]..sort(
          (a, b) => b.displayName.toLowerCase().compareTo(
            a.displayName.toLowerCase(),
          ),
        ),
      SearchTabsSortMode.booruClusters => _clusterByBooru(tabs, configs),
    };
  }

  /// Groups tabs by booru profile (clusters follow the profile order in the
  /// booru list), ordered inside each cluster by creation time.
  List<SearchTab> _clusterByBooru(
    List<SearchTab> tabs,
    List<BooruConfig> configs,
  ) {
    final orderByConfig = {
      for (final (index, config) in configs.indexed) config.id: index,
    };

    return [...tabs]..sort((a, b) {
      final clusterA = orderByConfig[a.configId] ?? orderByConfig.length;
      final clusterB = orderByConfig[b.configId] ?? orderByConfig.length;

      if (clusterA != clusterB) return clusterA.compareTo(clusterB);

      return a.id.compareTo(b.id);
    });
  }

  void _openTab(SearchTab tab) {
    goToSearchTabViewPage(ref, tab.id);
  }

  void _createTabForConfig(BooruConfig config, {String query = ''}) {
    final tab = ref
        .read(searchTabsProvider.notifier)
        .add(query: query, configId: config.id);

    _openTab(tab);
  }

  void _quickNewTab() {
    final contextConfig = ref.read(searchTabConfigProvider(_contextConfigId));
    final fallback = ref.read(currentBooruConfigProvider);

    _createTabForConfig(contextConfig ?? fallback);
  }

  void _newTabWithBooruPicker() {
    final configs = ref.read(booruConfigProvider);

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'New tab from booru',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: configs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final config = configs[index];

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _searchThenCreateTab(config);
                    },
                    child: SizedBox(
                      width: 72,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ConfigAwareWebsiteLogo.fromConfig(
                            config.auth,
                            width: 36,
                            height: 36,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            config.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _searchThenCreateTab(BooruConfig config) {
    goToQuickSearchPage(
      context,
      ref: ref,
      initialConfig: config.auth,
      onSubmitted: (context, text, isRaw) {
        Navigator.of(context).pop();
        if (text.trim().isNotEmpty) {
          _createTabForConfig(config, query: text.trim());
        }
      },
      onSelected: (tag, isRaw) {
        if (tag.trim().isNotEmpty) {
          _createTabForConfig(config, query: tag.trim());
        }
      },
    );
  }

  void _jumpToActive(List<SearchTab> visibleTabs, int? activeId) {
    final index = visibleTabs.indexWhere((e) => e.id == activeId);
    if (index < 0 || !_scrollController.hasClients) return;

    final maxExtent = _scrollController.position.maxScrollExtent;
    final target = (index / visibleTabs.length) * maxExtent;

    _scrollController.animateTo(
      target.clamp(0, maxExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollToEdge({required bool top}) {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      top ? 0 : _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchTabsProvider);
    final sortMode = ref.watch(searchTabsSortModeProvider);
    final configs = ref.watch(booruConfigProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final visibleTabs = _visibleTabs(state, sortMode, configs);
    final filtered =
        _filterText.isNotEmpty ||
        _filterConfigId != null ||
        sortMode != SearchTabsSortMode.manual;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.tabs.isEmpty
              ? 'Tabs'
              : filtered && visibleTabs.length != state.tabs.length
              ? 'Tabs (${visibleTabs.length}/${state.tabs.length})'
              : 'Tabs (${state.tabs.length})',
        ),
        actions: [
          _SortMenuButton(sortMode: sortMode),
          PopupMenuButton<String>(
            icon: const Icon(Symbols.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'insert_position':
                  _showInsertPositionDialog();
                case 'close_all':
                  _confirmCloseAll();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'insert_position',
                child: Text('New tab position'),
              ),
              if (state.tabs.isNotEmpty)
                const PopupMenuItem(
                  value: 'close_all',
                  child: Text('Close all tabs'),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _filterController,
                    decoration: InputDecoration(
                      hintText: 'Filter tabs',
                      prefixIcon: const Icon(Symbols.search, size: 20),
                      suffixIcon: _filterText.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Symbols.close, size: 18),
                              onPressed: _filterController.clear,
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _BooruFilterButton(
                  configs: configs,
                  selectedConfigId: _filterConfigId,
                  onSelected: (configId) =>
                      setState(() => _filterConfigId = configId),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.tabs.isEmpty
                ? _EmptyTabsView(onAddTab: _quickNewTab)
                : visibleTabs.isEmpty
                ? Center(
                    child: Text(
                      'No tabs match the filter',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : _buildTabList(state, sortMode, visibleTabs),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onLongPress: _newTabWithBooruPicker,
                child: FilledButton.icon(
                  onPressed: _quickNewTab,
                  icon: const Icon(Symbols.add),
                  label: const Text('New tab'),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Symbols.my_location),
              tooltip: 'Jump to active tab',
              onPressed: () => _jumpToActive(visibleTabs, state.activeId),
            ),
            IconButton(
              icon: const Icon(Symbols.vertical_align_top),
              tooltip: 'Scroll to top',
              onPressed: () => _scrollToEdge(top: true),
            ),
            IconButton(
              icon: const Icon(Symbols.vertical_align_bottom),
              tooltip: 'Scroll to bottom',
              onPressed: () => _scrollToEdge(top: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabList(
    SearchTabsState state,
    SearchTabsSortMode sortMode,
    List<SearchTab> visibleTabs,
  ) {
    final canReorder =
        sortMode == SearchTabsSortMode.manual &&
        _filterText.isEmpty &&
        _filterConfigId == null;

    if (canReorder) {
      return ReorderableListView.builder(
        scrollController: _scrollController,
        itemCount: visibleTabs.length,
        buildDefaultDragHandles: false,
        onReorder: (oldIndex, newIndex) =>
            ref.read(searchTabsProvider.notifier).reorder(oldIndex, newIndex),
        itemBuilder: (context, index) => _buildTile(
          state,
          visibleTabs,
          index,
          reorderIndex: index,
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: visibleTabs.length,
      itemBuilder: (context, index) => _buildTile(state, visibleTabs, index),
    );
  }

  Widget _buildTile(
    SearchTabsState state,
    List<SearchTab> visibleTabs,
    int index, {
    int? reorderIndex,
  }) {
    final tab = visibleTabs[index];
    final globalIndex = state.tabs.indexWhere((e) => e.id == tab.id);

    return _TabTile(
      key: ValueKey(tab.id),
      tab: tab,
      index: globalIndex,
      selected: tab.id == state.activeId,
      reorderIndex: reorderIndex,
      onTap: () => _openTab(tab),
      onOptions: () => _showTabOptions(tab),
      onClose: () => ref.read(searchTabsProvider.notifier).remove(tab.id),
    );
  }

  void _showInsertPositionDialog() {
    final current = ref.read(searchTabInsertPositionProvider);

    showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Where should new tabs go?'),
        children: [
          for (final position in SearchTabInsertPosition.values)
            ListTile(
              title: Text(position.label),
              trailing: position == current ? const Icon(Symbols.check) : null,
              onTap: () {
                ref
                    .read(searchTabInsertPositionProvider.notifier)
                    .set(
                      position,
                    );
                Navigator.of(dialogContext).pop();
              },
            ),
        ],
      ),
    );
  }

  void _confirmCloseAll() {
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

  void _showTabOptions(SearchTab tab) {
    final configs = ref.read(booruConfigProvider);

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
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
                leading: const Icon(Symbols.manage_search),
                title: const Text('Edit query'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showEditQueryDialog(tab);
                },
              ),
              ListTile(
                leading: const Icon(Symbols.swap_horiz),
                title: const Text('Move to another booru'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showChangeBooruSheet(tab, configs);
                },
              ),
              ListTile(
                leading: const Icon(Symbols.content_copy),
                title: const Text('Duplicate tab'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  ref
                      .read(searchTabsProvider.notifier)
                      .add(
                        query: tab.query,
                        configId: tab.configId,
                        activate: false,
                      );
                  showSuccessToast(context, 'Tab duplicated');
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

  void _showEditQueryDialog(SearchTab tab) {
    final controller = TextEditingController(text: tab.query);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit query'),
        content: TextField(
          controller: controller,
          autofocus: true,
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
                  .updateQuery(tab.id, controller.text.trim());
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _showChangeBooruSheet(SearchTab tab, List<BooruConfig> configs) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final config in configs)
                ListTile(
                  leading: ConfigAwareWebsiteLogo.fromConfig(
                    config.auth,
                    width: 24,
                    height: 24,
                  ),
                  title: Text(config.name),
                  selected: config.id == tab.configId,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    ref
                        .read(searchTabsProvider.notifier)
                        .changeConfig(tab.id, config.id);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortMenuButton extends ConsumerWidget {
  const _SortMenuButton({
    required this.sortMode,
  });

  final SearchTabsSortMode sortMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<SearchTabsSortMode>(
      icon: const Icon(Symbols.sort),
      tooltip: 'Sort tabs',
      onSelected: (mode) =>
          ref.read(searchTabsSortModeProvider.notifier).set(mode),
      itemBuilder: (context) => [
        for (final mode in SearchTabsSortMode.values)
          CheckedPopupMenuItem(
            value: mode,
            checked: mode == sortMode,
            child: Text(mode.label),
          ),
      ],
    );
  }
}

class _BooruFilterButton extends StatelessWidget {
  const _BooruFilterButton({
    required this.configs,
    required this.selectedConfigId,
    required this.onSelected,
  });

  final List<BooruConfig> configs;
  final int? selectedConfigId;
  final void Function(int? configId) onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = configs.where((e) => e.id == selectedConfigId).firstOrNull;

    return PopupMenuButton<int>(
      tooltip: 'Filter by booru',
      onSelected: (value) => onSelected(value == -1 ? null : value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: -1,
          child: Text('All boorus'),
        ),
        for (final config in configs)
          PopupMenuItem(
            value: config.id,
            child: Row(
              children: [
                ConfigAwareWebsiteLogo.fromConfig(
                  config.auth,
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    config.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected != null
              ? colorScheme.secondaryContainer
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: selected != null
            ? ConfigAwareWebsiteLogo.fromConfig(
                selected.auth,
                width: 22,
                height: 22,
              )
            : Icon(
                Symbols.filter_alt,
                size: 22,
                color: colorScheme.onSurfaceVariant,
              ),
      ),
    );
  }
}

class _TabTile extends ConsumerWidget {
  const _TabTile({
    required this.tab,
    required this.index,
    required this.selected,
    required this.onTap,
    required this.onOptions,
    required this.onClose,
    this.reorderIndex,
    super.key,
  });

  final SearchTab tab;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onOptions;
  final VoidCallback onClose;
  final int? reorderIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(searchTabConfigProvider(tab.configId));
    final colorScheme = Theme.of(context).colorScheme;

    final tile = ListTile(
      selected: selected,
      selectedTileColor: colorScheme.secondaryContainer.withValues(alpha: 0.4),
      leading: config != null
          ? ConfigAwareWebsiteLogo.fromConfig(
              config.auth,
              width: 26,
              height: 26,
            )
          : Icon(Symbols.error, color: colorScheme.error),
      title: Text(
        tab.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontStyle: tab.query.isEmpty ? FontStyle.italic : FontStyle.normal,
        ),
      ),
      subtitle: Text(
        '${config?.name ?? 'Missing booru'}  ·  #${index + 1}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Symbols.tune, size: 20),
            onPressed: onOptions,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Symbols.close, size: 20),
            onPressed: onClose,
          ),
        ],
      ),
      onTap: onTap,
      // Long-press starts drag-reorder in manual sort mode, so only bind it
      // to options when reordering is unavailable.
      onLongPress: reorderIndex == null ? onOptions : null,
    );

    if (reorderIndex != null) {
      return ReorderableDelayedDragStartListener(
        key: ValueKey(tab.id),
        index: reorderIndex!,
        child: tile,
      );
    }

    return tile;
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
              'Long-press any tag and pick "Add to tab", or tap "New tab" '
              'below. Long-press "New tab" to pick a booru first.',
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
