// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:equatable/equatable.dart';

class SearchTab extends Equatable {
  const SearchTab({
    required this.id,
    required this.query,
    required this.configId,
    this.label,
  });

  factory SearchTab.fromJson(Map<String, dynamic> json) {
    return SearchTab(
      id: switch (json['id']) {
        final int id => id,
        _ => DateTime.now().millisecondsSinceEpoch,
      },
      query: switch (json['query']) {
        final String query => query,
        _ => '',
      },
      configId: switch (json['configId']) {
        final int configId => configId,
        _ => -1,
      },
      label: json['label'] as String?,
    );
  }

  final int id;
  final String query;
  final int configId;
  final String? label;

  String get displayName => switch (label) {
    final l? when l.isNotEmpty => l,
    _ => query.isEmpty ? '<empty>' : query,
  };

  SearchTab copyWith({
    String? query,
    int? configId,
    String? Function()? label,
  }) {
    return SearchTab(
      id: id,
      query: query ?? this.query,
      configId: configId ?? this.configId,
      label: label != null ? label() : this.label,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'query': query,
    'configId': configId,
    'label': label,
  };

  @override
  List<Object?> get props => [id, query, configId, label];
}

class SearchTabsState extends Equatable {
  const SearchTabsState({
    required this.tabs,
    required this.activeId,
  });

  const SearchTabsState.empty() : tabs = const [], activeId = null;

  factory SearchTabsState.fromJsonString(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return const SearchTabsState.empty();
    }

    try {
      final json = jsonDecode(jsonString);

      return switch (json) {
        final Map<String, dynamic> map => SearchTabsState(
          tabs: switch (map['tabs']) {
            final List<dynamic> list =>
              list
                  .whereType<Map<String, dynamic>>()
                  .map(SearchTab.fromJson)
                  .toList(),
            _ => const [],
          },
          activeId: map['activeId'] as int?,
        ),
        _ => const SearchTabsState.empty(),
      };
    } catch (_) {
      return const SearchTabsState.empty();
    }
  }

  final List<SearchTab> tabs;
  final int? activeId;

  SearchTab? get activeTab => switch (activeId) {
    final id? => tabs.where((e) => e.id == id).firstOrNull,
    null => null,
  };

  int get activeIndex {
    final index = tabs.indexWhere((e) => e.id == activeId);
    return index < 0 ? 0 : index;
  }

  SearchTabsState copyWith({
    List<SearchTab>? tabs,
    int? Function()? activeId,
  }) {
    return SearchTabsState(
      tabs: tabs ?? this.tabs,
      activeId: activeId != null ? activeId() : this.activeId,
    );
  }

  String toJsonString() => jsonEncode({
    'tabs': tabs.map((e) => e.toJson()).toList(),
    'activeId': activeId,
  });

  @override
  List<Object?> get props => [tabs, activeId];
}
