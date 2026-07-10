// Package imports:
import 'package:foundation/foundation.dart';

// Project imports:
import '../../../router.dart';
import '../pages/search_tab_view_page.dart';
import '../pages/search_tabs_page.dart';

final searchTabsRoutes = GoRoute(
  path: 'search_tabs',
  name: '/search_tabs',
  pageBuilder: genericMobilePageBuilder(
    builder: (context, state) => const SearchTabsPage(),
  ),
  routes: [
    GoRoute(
      path: 'view',
      name: '/search_tabs/view',
      pageBuilder: genericMobilePageBuilder(
        builder: (context, state) {
          final tabId = state.uri.queryParameters['id']?.toInt();

          return tabId != null
              ? SearchTabViewPage(tabId: tabId)
              : const InvalidPage(message: 'Invalid tab id');
        },
      ),
    ),
  ],
);
