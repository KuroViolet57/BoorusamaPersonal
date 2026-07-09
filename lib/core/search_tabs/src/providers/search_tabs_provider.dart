// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import '../../../cache/providers.dart';
import '../../../configs/config/types.dart';
import '../../../configs/manage/providers.dart';
import '../types/search_tab.dart';

const kSearchTabsDataKey = 'search_tabs';
const kMaxLiveSearchTabs = 4;

final searchTabsProvider =
    NotifierProvider<SearchTabsNotifier, SearchTabsState>(
      SearchTabsNotifier.new,
      name: 'searchTabsProvider',
    );

class SearchTabsNotifier extends Notifier<SearchTabsState> {
  @override
  SearchTabsState build() {
    final box = ref.watch(miscDataBoxProvider);

    return SearchTabsState.fromJsonString(box.get(kSearchTabsDataKey));
  }

  SearchTab add({
    required String query,
    required int configId,
    bool activate = true,
  }) {
    final tab = SearchTab(
      id: DateTime.now().microsecondsSinceEpoch,
      query: query,
      configId: configId,
    );

    state = state.copyWith(
      tabs: [...state.tabs, tab],
      activeId: activate ? () => tab.id : null,
    );
    _save();

    return tab;
  }

  void remove(int id) {
    final tabs = state.tabs.where((e) => e.id != id).toList();
    final activeId = state.activeId == id
        ? _closestTabId(state.tabs, id, tabs)
        : state.activeId;

    state = state.copyWith(
      tabs: tabs,
      activeId: () => activeId,
    );
    _save();
  }

  int? _closestTabId(
    List<SearchTab> oldTabs,
    int removedId,
    List<SearchTab> newTabs,
  ) {
    if (newTabs.isEmpty) return null;

    final removedIndex = oldTabs.indexWhere((e) => e.id == removedId);
    final fallbackIndex = removedIndex.clamp(0, newTabs.length - 1);

    return newTabs[fallbackIndex].id;
  }

  void activate(int id) {
    if (state.tabs.every((e) => e.id != id)) return;

    state = state.copyWith(activeId: () => id);
    _save();
  }

  void reorder(int oldIndex, int newIndex) {
    final tabs = [...state.tabs];

    if (oldIndex < 0 || oldIndex >= tabs.length) return;

    final tab = tabs.removeAt(oldIndex);
    final insertIndex = (newIndex > oldIndex ? newIndex - 1 : newIndex).clamp(
      0,
      tabs.length,
    );

    tabs.insert(insertIndex, tab);

    state = state.copyWith(tabs: tabs);
    _save();
  }

  void updateQuery(int id, String query) {
    state = state.copyWith(
      tabs: [
        for (final tab in state.tabs)
          if (tab.id == id) tab.copyWith(query: query) else tab,
      ],
    );
    _save();
  }

  void rename(int id, String? label) {
    state = state.copyWith(
      tabs: [
        for (final tab in state.tabs)
          if (tab.id == id)
            tab.copyWith(
              label: () => switch (label) {
                final l? when l.trim().isNotEmpty => l.trim(),
                _ => null,
              },
            )
          else
            tab,
      ],
    );
    _save();
  }

  void changeConfig(int id, int configId) {
    state = state.copyWith(
      tabs: [
        for (final tab in state.tabs)
          if (tab.id == id) tab.copyWith(configId: configId) else tab,
      ],
    );
    _save();
  }

  void closeOthers(int id) {
    state = state.copyWith(
      tabs: state.tabs.where((e) => e.id == id).toList(),
      activeId: () => id,
    );
    _save();
  }

  void clear() {
    state = const SearchTabsState.empty();
    _save();
  }

  void _save() {
    ref.read(miscDataBoxProvider).put(kSearchTabsDataKey, state.toJsonString());
  }
}

final searchTabConfigProvider = Provider.family<BooruConfig?, int>(
  (ref, configId) {
    final configs = ref.watch(booruConfigProvider);

    return configs.where((e) => e.id == configId).firstOrNull;
  },
  name: 'searchTabConfigProvider',
);
