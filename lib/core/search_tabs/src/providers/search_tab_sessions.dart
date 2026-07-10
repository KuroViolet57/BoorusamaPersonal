// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

// Project imports:
import '../../../blacklists/providers.dart';
import '../../../configs/config/types.dart';
import '../../../posts/listing/providers.dart';
import '../../../posts/listing/widgets.dart';
import '../../../posts/post/providers.dart';
import '../../../posts/post/types.dart';
import '../../../settings/providers.dart';
import '../types/search_tab.dart';
import 'search_tabs_provider.dart';

/// Holds the live post grid state for a tab so revisiting it doesn't reset
/// what was already loaded. Evicted LRU-style once too many are alive.
class SearchTabSession {
  SearchTabSession({
    required this.postController,
    required this.scrollController,
  });

  final PostGridController<Post> postController;
  final AutoScrollController scrollController;

  double lastOffset = 0;
  var attached = false;
}

class SearchTabSessionCache {
  SearchTabSessionCache(this.ref);

  final Ref ref;
  final _sessions = <int, SearchTabSession>{};

  SearchTabSession obtain(SearchTab tab, BooruConfig config) {
    final existing = _sessions.remove(tab.id);
    if (existing != null) {
      // Re-insert to mark as most recently used.
      _sessions[tab.id] = existing;
      return existing;
    }

    final configSearch = config.search;
    final configFilter = config.filter;

    final controller = PostGridController<Post>(
      fetcher: (page) =>
          ref.read(postRepoProvider(configSearch)).getPosts(tab.query, page),
      duplicateTracker: PostDuplicateTracker<Post>(),
      blacklistedTagsFetcher: () =>
          ref.read(blacklistTagsProvider(configFilter).future),
      pageMode: ref.read(
        imageListingSettingsProvider.select((value) => value.pageMode),
      ),
      mountedChecker: () => _sessions.containsKey(tab.id),
      onError: (_) {},
    );

    final session = SearchTabSession(
      postController: controller,
      scrollController: AutoScrollController(),
    );

    _sessions[tab.id] = session;
    _evict();

    return session;
  }

  void _evict() {
    final evictable = _sessions.entries
        .where((e) => !e.value.attached)
        .map((e) => e.key)
        .toList();

    var index = 0;
    while (_sessions.length > kMaxLiveSearchTabs && index < evictable.length) {
      remove(evictable[index]);
      index += 1;
    }
  }

  void remove(int tabId) {
    final session = _sessions.remove(tabId);
    if (session == null) return;

    session.postController.dispose();
    session.scrollController.dispose();
  }

  void clear() {
    _sessions.keys.toList().forEach(remove);
  }
}

final searchTabSessionCacheProvider = Provider<SearchTabSessionCache>(
  SearchTabSessionCache.new,
  name: 'searchTabSessionCacheProvider',
);
