// Project imports:
import '../../../router.dart';
import '../pages/search_tabs_page.dart';

final searchTabsRoutes = GoRoute(
  path: 'search_tabs',
  name: '/search_tabs',
  pageBuilder: genericMobilePageBuilder(
    builder: (context, state) => const SearchTabsPage(),
  ),
);
