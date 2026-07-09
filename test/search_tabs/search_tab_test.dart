// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:boorusama/core/search_tabs/types.dart';

void main() {
  group('SearchTabsState serialization', () {
    test('round-trips tabs and active id through json', () {
      const state = SearchTabsState(
        tabs: [
          SearchTab(id: 1, query: 'cat_girl', configId: 10),
          SearchTab(id: 2, query: 'landscape', configId: 11, label: 'Scenery'),
        ],
        activeId: 2,
      );

      final restored = SearchTabsState.fromJsonString(state.toJsonString());

      expect(restored, state);
    });

    final invalidCases = [
      (input: null, name: 'null'),
      (input: '', name: 'empty string'),
      (input: 'not json', name: 'garbage'),
      (input: '[]', name: 'wrong root type'),
      (input: '{"tabs": "oops"}', name: 'wrong tabs type'),
    ];

    for (final c in invalidCases) {
      test('returns empty state for ${c.name} input', () {
        final state = SearchTabsState.fromJsonString(c.input);

        expect(state.tabs, isEmpty);
        expect(state.activeId, isNull);
      });
    }
  });

  group('SearchTab display name', () {
    final cases = [
      (
        tab: const SearchTab(id: 1, query: 'cat', configId: 1),
        expected: 'cat',
      ),
      (
        tab: const SearchTab(id: 1, query: 'cat', configId: 1, label: 'Cats'),
        expected: 'Cats',
      ),
      (
        tab: const SearchTab(id: 1, query: '', configId: 1),
        expected: '<empty>',
      ),
    ];

    for (final c in cases) {
      test('shows ${c.expected} for the tab', () {
        expect(c.tab.displayName, c.expected);
      });
    }
  });
}
