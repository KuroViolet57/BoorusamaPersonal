// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import '../../../router.dart';

void goToSearchTabsPage(WidgetRef ref) {
  ref.router.push('/search_tabs');
}

void goToSearchTabViewPage(WidgetRef ref, int tabId) {
  ref.router.push(
    Uri(
      path: '/search_tabs/view',
      queryParameters: {'id': '$tabId'},
    ).toString(),
  );
}
