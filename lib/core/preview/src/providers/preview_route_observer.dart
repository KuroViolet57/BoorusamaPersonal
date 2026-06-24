// Flutter imports:
import 'package:flutter/widgets.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Project imports:
import 'preview_controller.dart';

/// Tracks route push/pop depth so [PreviewController] can scope each preview
/// to the route that opened it. Mounted on the root [GoRouter].
class PreviewRouteObserver extends NavigatorObserver {
  PreviewRouteObserver.fromRef(this._ref);

  final Ref _ref;

  PreviewController get _controller =>
      _ref.read(previewControllerProvider.notifier);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _controller.onPush();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _controller.onPop();
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _controller.onPop();
    super.didRemove(route, previousRoute);
  }
}
