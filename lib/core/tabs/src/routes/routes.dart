// Flutter imports:
import 'package:flutter/cupertino.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import '../../../router.dart';
import '../providers/tab_manager.dart';
import '../widgets/tabs_home_page.dart';

GoRoute tabsRoutes(Ref ref) => GoRoute(
  path: 'tabs',
  name: '/tabs',
  pageBuilder: (context, state) => CupertinoPage(
    key: state.pageKey,
    name: state.name,
    child: const TabsHomePage(),
  ),
);

void goToTabsPage(WidgetRef ref) {
  ref.router.push('/tabs');
}

void openInNewTab(
  WidgetRef ref, {
  List<String> tags = const [],
  String? title,
  bool switchToTabsPage = true,
}) {
  ref.read(tabManagerProvider.notifier).openNewTab(
    tags: tags,
    title: title,
  );
  if (switchToTabsPage) {
    final router = ref.read(routerProvider);
    final location = router.routerDelegate.currentConfiguration.uri.toString();
    if (!location.startsWith('/tabs')) {
      router.push('/tabs');
    }
  }
}

void addToCurrentTab(
  WidgetRef ref, {
  required String tag,
  bool switchToTabsPage = true,
}) {
  final manager = ref.read(tabManagerProvider.notifier);
  final state = ref.read(tabManagerProvider);
  final currentId = state.currentTabId;
  if (currentId == null) {
    manager.openNewTab(tags: [tag]);
  } else {
    manager.addTagToTab(currentId, tag);
  }
  if (switchToTabsPage) {
    final router = ref.read(routerProvider);
    final location = router.routerDelegate.currentConfiguration.uri.toString();
    if (!location.startsWith('/tabs')) {
      router.push('/tabs');
    }
  }
}
