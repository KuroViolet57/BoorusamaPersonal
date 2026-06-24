// Dart imports:
import 'dart:async';
import 'dart:convert';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

// Project imports:
import '../../../search/selected_tags/types.dart';
import '../types/booru_tab.dart';
import '../types/tab_manager_state.dart';

const int kKeepAliveTabLimit = 5;
const String _kTabsBoxName = 'booru_tabs_v1';
const String _kStateKey = 'state';

final tabManagerProvider =
    NotifierProvider<TabManagerNotifier, TabManagerState>(
      TabManagerNotifier.new,
      name: 'tabManagerProvider',
    );

class TabManagerNotifier extends Notifier<TabManagerState> {
  int _idCounter = 0;
  final List<String> _recency = <String>[];

  Box<String>? _box;
  Future<void>? _readyFuture;
  bool _loaded = false;
  Timer? _persistDebounce;

  @override
  TabManagerState build() {
    _readyFuture = _initialize();
    ref.listenSelf((_, _) {
      if (!_loaded) return;
      _schedulePersist();
    });
    ref.onDispose(() {
      _persistDebounce?.cancel();
    });
    return TabManagerState.initial();
  }

  /// Resolves when the on-disk state has been merged in. Call this before
  /// deciding whether to seed a default tab, otherwise the seed will race the
  /// load and overwrite persisted tabs.
  Future<void> ensureLoaded() => _readyFuture ?? Future.value();

  Future<void> _initialize() async {
    try {
      _box = await Hive.openBox<String>(_kTabsBoxName);
      final raw = _box!.get(_kStateKey);
      if (raw != null) {
        final json = jsonDecode(raw);
        if (json is Map<String, dynamic>) {
          final tabsJson = json['tabs'];
          final restored = <BooruTab>[];
          if (tabsJson is List) {
            for (final t in tabsJson) {
              if (t is Map<String, dynamic>) {
                try {
                  restored.add(BooruTab.fromJson(t));
                } catch (_) {/* skip corrupt entry */}
              }
            }
          }
          final currentTabId = json['currentTabId'] as String?;
          final hasCurrent =
              currentTabId != null && restored.any((t) => t.id == currentTabId);
          final nextCurrent = hasCurrent
              ? currentTabId
              : (restored.isNotEmpty ? restored.first.id : null);
          _recency
            ..clear()
            ..addAll([if (nextCurrent != null) nextCurrent]);
          state = TabManagerState(
            tabs: restored,
            currentTabId: nextCurrent,
            // Only mark the active tab as alive on cold start; the rest stay
            // dehydrated as placeholders so we don't fetch posts for every
            // restored tab at once.
            aliveTabIds: nextCurrent != null ? {nextCurrent} : const {},
          );
        }
      }
    } catch (_) {
      // Box failed to open or content was unreadable — fall through to an
      // empty in-memory state.
    } finally {
      _loaded = true;
    }
  }

  void _schedulePersist() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 250), _persist);
  }

  Future<void> _persist() async {
    final box = _box;
    if (box == null) return;
    final snapshot = jsonEncode({
      'tabs': state.tabs.map((t) => t.toJson()).toList(),
      if (state.currentTabId != null) 'currentTabId': state.currentTabId,
    });
    try {
      await box.put(_kStateKey, snapshot);
    } catch (_) {/* ignore disk errors */}
  }

  String _newId() {
    _idCounter += 1;
    return 't${DateTime.now().millisecondsSinceEpoch}_$_idCounter';
  }

  String openNewTab({
    SearchTagSet? tagSet,
    List<String>? tags,
    String? title,
    bool switchTo = true,
  }) {
    final id = _newId();
    final tab = BooruTab(
      id: id,
      tags: List.unmodifiable(tags ?? tagSet?.list ?? const <String>[]),
      title: title,
    );

    final nextTabs = [...state.tabs, tab];
    final nextAlive = switchTo ? _promote(id) : state.aliveTabIds;

    state = state.copyWith(
      tabs: nextTabs,
      currentTabId: switchTo ? id : state.currentTabId,
      aliveTabIds: nextAlive,
    );

    return id;
  }

  void switchTo(String id) {
    if (state.currentTabId == id) return;
    if (state.tabs.every((t) => t.id != id)) return;

    state = state.copyWith(
      currentTabId: id,
      aliveTabIds: _promote(id),
    );
  }

  void close(String id) {
    final idx = state.tabs.indexWhere((t) => t.id == id);
    if (idx < 0) return;

    final remaining = [...state.tabs]..removeAt(idx);

    final wasCurrent = state.currentTabId == id;
    final nextCurrentId = switch ((wasCurrent, remaining)) {
      (false, _) => state.currentTabId,
      (true, []) => null,
      (true, _) => remaining[idx.clamp(0, remaining.length - 1)].id,
    };

    final nextAlive = {...state.aliveTabIds}..remove(id);
    _recency.remove(id);

    final promotedAlive =
        nextCurrentId != null ? _promote(nextCurrentId) : nextAlive;

    state = state.copyWith(
      tabs: remaining,
      currentTabId: nextCurrentId,
      clearCurrent: nextCurrentId == null,
      aliveTabIds: promotedAlive,
    );
  }

  void closeAll() {
    _recency.clear();
    state = TabManagerState.initial();
  }

  void rename(String id, String? title) {
    final idx = state.tabs.indexWhere((t) => t.id == id);
    if (idx < 0) return;

    final updated = [...state.tabs];
    updated[idx] = updated[idx].copyWith(title: title);

    state = state.copyWith(tabs: updated);
  }

  void replaceTags(String id, List<String> tags) {
    final idx = state.tabs.indexWhere((t) => t.id == id);
    if (idx < 0) return;

    final updated = [...state.tabs];
    updated[idx] = updated[idx].copyWith(tags: List.unmodifiable(tags));

    state = state.copyWith(tabs: updated);
  }

  void addTagToTab(String id, String tag) {
    final idx = state.tabs.indexWhere((t) => t.id == id);
    if (idx < 0) return;

    final existing = state.tabs[idx];
    if (existing.tags.contains(tag)) return;

    replaceTags(id, [...existing.tags, tag]);
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.tabs.length) return;
    var effectiveNew = newIndex;
    if (effectiveNew > oldIndex) effectiveNew -= 1;
    if (effectiveNew < 0) effectiveNew = 0;
    if (effectiveNew >= state.tabs.length) effectiveNew = state.tabs.length - 1;

    final updated = [...state.tabs];
    final moved = updated.removeAt(oldIndex);
    updated.insert(effectiveNew, moved);

    state = state.copyWith(tabs: updated);
  }

  Set<String> _promote(String id) {
    _recency
      ..remove(id)
      ..add(id);
    while (_recency.length > kKeepAliveTabLimit) {
      _recency.removeAt(0);
    }
    return _recency.toSet();
  }
}
