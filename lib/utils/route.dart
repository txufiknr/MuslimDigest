import 'dart:developer' show log;

import 'package:flutter/material.dart';

String? currentRoute;

class MyRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  void _setTitle(String what, PageRoute<dynamic> routeFrom, PageRoute<dynamic> routeTo) {
    final oldScreenName = routeFrom.settings.name;
    final newScreenName = routeTo.settings.name;
    log("route changed: $what ($oldScreenName -> $newScreenName)");
    currentRoute = newScreenName;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute && previousRoute is PageRoute) _setTitle("push", previousRoute, route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute && oldRoute is PageRoute) _setTitle("replace", oldRoute, newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is PageRoute && previousRoute is PageRoute) _setTitle("pop", route, previousRoute);
  }
}