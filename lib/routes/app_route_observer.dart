import 'package:flutter/material.dart';

import 'package:pick_u/services/notification_service.dart';

class MyRouteObserver extends RouteObserver<PageRoute<dynamic>> {

  void _sendScreenView(PageRoute<dynamic> route) {
    final screenName = route.settings.name ?? route.runtimeType.toString();
    print('SAHArSAHAr 🧭 Current screen: $screenName');

    // ADDED: Update notification service with current route
    try {
      NotificationService.to.updateCurrentRoute(screenName);
    } catch (e) {
      print('❌ Failed to update route in NotificationService: $e');
    }
  }

  @override
  void didPush(Route<dynamic>? route, Route<dynamic>? previousRoute) {
    super.didPush(route!, previousRoute);
    if (route is PageRoute) {
      _sendScreenView(route);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      _sendScreenView(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic>? route, Route<dynamic>? previousRoute) {
    super.didPop(route!, previousRoute);
    if (previousRoute is PageRoute && route is PageRoute) {
      _sendScreenView(previousRoute);
    }
  }
}