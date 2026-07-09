// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import '../../../configs/config/types.dart';
import '../../../posts/listing/widgets.dart';
import '../../../posts/post/providers.dart';
import '../providers/search_tabs_provider.dart';
import '../types/search_tab.dart';

class SearchTabView extends ConsumerWidget {
  const SearchTabView({
    required this.tab,
    super.key,
  });

  final SearchTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(searchTabConfigProvider(tab.configId));

    if (config == null) {
      return _MissingConfigView(tab: tab);
    }

    final configSearch = config.search;
    final configAuth = config.auth;

    return PostScope(
      fetcher: (page) =>
          ref.read(postRepoProvider(configSearch)).getPosts(tab.query, page),
      builder: (context, controller) => PostGrid(
        controller: controller,
        itemBuilder: (context, index, autoScrollController, useHero) =>
            GeneralPostContextMenu(
              index: index,
              controller: controller,
              child: DefaultImageGridItem(
                index: index,
                autoScrollController: autoScrollController,
                controller: controller,
                useHero: useHero,
                config: configAuth,
                imageConfig: configAuth,
              ),
            ),
      ),
    );
  }
}

class _MissingConfigView extends ConsumerWidget {
  const _MissingConfigView({
    required this.tab,
  });

  final SearchTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Symbols.error,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'The booru profile for this tab no longer exists.',
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              ref.read(searchTabsProvider.notifier).remove(tab.id);
            },
            child: const Text('Close tab'),
          ),
        ],
      ),
    );
  }
}
