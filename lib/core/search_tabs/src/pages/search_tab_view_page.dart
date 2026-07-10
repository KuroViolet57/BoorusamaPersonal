// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import '../../../config_widgets/website_logo.dart';
import '../../../configs/config/types.dart';
import '../../../configs/manage/providers.dart';
import '../../../posts/listing/widgets.dart';
import '../../../posts/post/types.dart';
import '../../../search/search/routes.dart';
import '../../../widgets/widgets.dart';
import '../providers/search_tab_sessions.dart';
import '../providers/search_tabs_provider.dart';
import '../types/search_tab.dart';

class SearchTabViewPage extends ConsumerStatefulWidget {
  const SearchTabViewPage({
    required this.tabId,
    super.key,
  });

  final int tabId;

  @override
  ConsumerState<SearchTabViewPage> createState() => _SearchTabViewPageState();
}

class _SearchTabViewPageState extends ConsumerState<SearchTabViewPage> {
  SearchTabSession? _session;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final tab = _currentTab();
      if (tab == null) return;

      ref.read(searchTabsProvider.notifier).activate(tab.id);
      _syncConfig(tab);
      _restoreScroll();
    });
  }

  SearchTab? _currentTab() {
    return ref
        .read(searchTabsProvider)
        .tabs
        .where((e) => e.id == widget.tabId)
        .firstOrNull;
  }

  void _syncConfig(SearchTab tab) {
    final config = ref.read(searchTabConfigProvider(tab.configId));

    if (config != null &&
        ref.read(currentBooruConfigProvider).id != config.id) {
      ref.read(currentBooruConfigProvider.notifier).update(config);
    }
  }

  void _restoreScroll() {
    final session = _session;
    if (session == null) return;

    if (session.lastOffset > 0 && session.scrollController.hasClients) {
      session.scrollController.jumpTo(
        session.lastOffset.clamp(
          0,
          session.scrollController.position.maxScrollExtent,
        ),
      );
    }
  }

  void _onScroll() {
    final session = _session;
    if (session == null) return;

    if (session.scrollController.hasClients) {
      session.lastOffset = session.scrollController.offset;
    }
  }

  @override
  void dispose() {
    final session = _session;
    if (session != null) {
      session.attached = false;
      session.scrollController.removeListener(_onScroll);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref
        .watch(searchTabsProvider)
        .tabs
        .where((e) => e.id == widget.tabId)
        .firstOrNull;

    if (tab == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('This tab has been closed.'),
        ),
      );
    }

    final config = ref.watch(searchTabConfigProvider(tab.configId));

    if (config == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(tab.displayName),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Symbols.error, size: 48),
              const SizedBox(height: 12),
              const Text('The booru profile for this tab no longer exists.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  ref.read(searchTabsProvider.notifier).remove(tab.id);
                  Navigator.of(context).pop();
                },
                child: const Text('Close tab'),
              ),
            ],
          ),
        ),
      );
    }

    final session = _obtainSession(tab, config);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ConfigAwareWebsiteLogo.fromConfig(
              config.auth,
              width: 22,
              height: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tab.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Symbols.search),
            tooltip: 'Open in search page',
            onPressed: () => goToSearchPage(ref, tag: tab.query),
          ),
          IconButton(
            icon: const Icon(Symbols.close),
            tooltip: 'Close tab',
            onPressed: () {
              ref.read(searchTabsProvider.notifier).remove(tab.id);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: CustomContextMenuOverlay(
        child: _SessionPostGrid(
          key: ValueKey((tab.id, tab.query, tab.configId)),
          session: session,
          config: config,
        ),
      ),
    );
  }

  SearchTabSession _obtainSession(SearchTab tab, BooruConfig config) {
    final cache = ref.watch(searchTabSessionCacheProvider);
    final session = cache.obtain(tab, config);

    if (!identical(session, _session)) {
      _session?.scrollController.removeListener(_onScroll);
      session.attached = true;
      session.scrollController.addListener(_onScroll);
      _session = session;
    }

    return session;
  }
}

class _SessionPostGrid extends ConsumerWidget {
  const _SessionPostGrid({
    required this.session,
    required this.config,
    super.key,
  });

  final SearchTabSession session;
  final BooruConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAuth = config.auth;

    return PostGrid<Post>(
      controller: session.postController,
      scrollController: session.scrollController,
      refreshAtStart: session.postController.items.isEmpty,
      itemBuilder: (context, index, autoScrollController, useHero) =>
          GeneralPostContextMenu(
            index: index,
            controller: session.postController,
            child: DefaultImageGridItem(
              index: index,
              autoScrollController: autoScrollController,
              controller: session.postController,
              useHero: false,
              config: configAuth,
              imageConfig: configAuth,
            ),
          ),
    );
  }
}
