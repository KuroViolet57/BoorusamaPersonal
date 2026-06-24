// Package imports:
import 'package:equatable/equatable.dart';

// Project imports:
import 'booru_tab.dart';

class TabManagerState extends Equatable {
  const TabManagerState({
    required this.tabs,
    required this.currentTabId,
    required this.aliveTabIds,
  });

  factory TabManagerState.initial() => const TabManagerState(
    tabs: [],
    currentTabId: null,
    aliveTabIds: {},
  );

  final List<BooruTab> tabs;
  final String? currentTabId;
  final Set<String> aliveTabIds;

  int get currentIndex {
    if (currentTabId == null) return -1;
    return tabs.indexWhere((t) => t.id == currentTabId);
  }

  BooruTab? get currentTab => switch (currentIndex) {
    -1 => null,
    final i => tabs[i],
  };

  TabManagerState copyWith({
    List<BooruTab>? tabs,
    String? currentTabId,
    bool clearCurrent = false,
    Set<String>? aliveTabIds,
  }) => TabManagerState(
    tabs: tabs ?? this.tabs,
    currentTabId: clearCurrent ? null : (currentTabId ?? this.currentTabId),
    aliveTabIds: aliveTabIds ?? this.aliveTabIds,
  );

  @override
  List<Object?> get props => [tabs, currentTabId, aliveTabIds];
}
