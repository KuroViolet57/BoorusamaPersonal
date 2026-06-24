// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

// Project imports:
import '../../../search/search/routes.dart';
import '../../../search/search/widgets.dart';
import '../providers/tab_manager.dart';
import '../types/booru_tab.dart';
import 'lazy_indexed_stack.dart';
import 'new_tab_dialog.dart';
import 'tab_manager_sheet.dart';
import 'tabs_strip.dart';

class TabsHomePage extends ConsumerStatefulWidget {
  const TabsHomePage({super.key});

  @override
  ConsumerState<TabsHomePage> createState() => _TabsHomePageState();
}

class _TabsHomePageState extends ConsumerState<TabsHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(tabManagerProvider);
      if (state.tabs.isEmpty) {
        ref.read(tabManagerProvider.notifier).openNewTab(title: 'Home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tabManagerProvider);

    if (state.tabs.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentIndex = state.currentIndex.clamp(0, state.tabs.length - 1);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: TabsStrip(
                tabs: state.tabs,
                currentTabId: state.currentTabId,
                onSwitch: (id) =>
                    ref.read(tabManagerProvider.notifier).switchTo(id),
                onClose: (id) =>
                    ref.read(tabManagerProvider.notifier).close(id),
                onNewTab: _openNewTabDialog,
                onOpenManager: _openManagerSheet,
              ),
            ),
            const Divider(height: 1, thickness: 0.5),
            Expanded(
              child: LazyIndexedStack(
                key: const ValueKey('tabs_lazy_stack'),
                index: currentIndex,
                itemCount: state.tabs.length,
                aliveIndices: {
                  for (var i = 0; i < state.tabs.length; i++)
                    if (state.aliveTabIds.contains(state.tabs[i].id)) i,
                },
                aliveBuilder: (context, i) => _TabBody(
                  tab: state.tabs[i],
                ),
                placeholderBuilder: (context, i) => _TabPlaceholder(
                  tab: state.tabs[i],
                  onTap: () => ref
                      .read(tabManagerProvider.notifier)
                      .switchTo(state.tabs[i].id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNewTabDialog() async {
    final created = await showNewTabDialog(context);
    if (created == null) return;
    if (!mounted) return;
    ref.read(tabManagerProvider.notifier).openNewTab(
      tags: created.tags,
      title: created.title,
    );
  }

  Future<void> _openManagerSheet() async {
    await showTabManagerSheet(context, ref);
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({required this.tab});

  final BooruTab tab;

  @override
  Widget build(BuildContext context) {
    final tagSet = tab.toTagSet();
    return InheritedInitialSearchQuery(
      key: ValueKey('tab_body_${tab.id}'),
      params: SearchParams(tags: tagSet),
      child: const SearchPage(),
    );
  }
}

class _TabPlaceholder extends StatelessWidget {
  const _TabPlaceholder({
    required this.tab,
    required this.onTap,
  });

  final BooruTab tab;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Symbols.refresh),
        label: Text('Load ${tab.displayTitle}'),
      ),
    );
  }
}
