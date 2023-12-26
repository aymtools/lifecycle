import 'package:flutter/widgets.dart';
// import 'package:weak_collections/weak_collections.dart';

import 'lifecycle.dart';
import 'lifecycle_mixin.dart';

part 'lifecycle_page_route.dart';

class LifecycleNavigatorObserver extends NavigatorObserver {
  void _subscribe(_RouteChanger changer) {
    final nav = navigator;
    if (nav != null) {
      var listeners =
      _navigatorRouteChanger.getOrPut(nav, () => <_RouteChanger>{});
      listeners.add(changer);
    }
  }

  void _unsubscribe(_RouteChanger changer) {
    final nav = navigator;
    if (nav != null) {
      _navigatorRouteChanger[nav]?.remove(changer);
    }
  }

  void _notifyChange() {
    final nav = navigator;
    if (nav != null) {
      final history = _historyRoute[nav];
      final vRoute = <Route>[];
      if (history != null && history.isNotEmpty) {
        final rHistory = history.reversed;
        for (var element in rHistory) {
          vRoute.add(element);
          if (element is PageRoute && element.opaque == true) {
            break;
          }
        }
      }

      final listeners = _navigatorRouteChanger[nav];
      if (listeners != null && listeners.isNotEmpty) {
        final ls = List<_RouteChanger>.from(listeners);
        for (var element in ls) {
          element.onChange(vRoute.contains);
        }
      }
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (navigator != null) _historyRoute[navigator!]?.remove(route);

    _notifyChange();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _historyRoute.getOrPut(navigator, () => <Route>[]).add(route);
    _notifyChange();
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);

    if (navigator != null) _historyRoute[navigator!]?.remove(route);

    _notifyChange();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);

    if (oldRoute != null && navigator != null) {
      _historyRoute[navigator!]?.remove(oldRoute);
    }
    if (newRoute != null) {
      _historyRoute.getOrPut(navigator, () => <Route>[]).add(newRoute);
    }
    _notifyChange();
  }

  static LifecycleNavigatorObserver? maybeOf(BuildContext context) {
    var observers = Navigator
        .of(context)
        .widget
        .observers
        .whereType<LifecycleNavigatorObserver>();
    final observer = observers.isEmpty ? null : observers.first;
    return observer;
  }

  static LifecycleNavigatorObserver of(BuildContext context) {
    final observer = maybeOf(context);
    assert(observer != null, 'Cannot find LifecycleNavigatorObserver');
    return observer!;
  }

  static List<Route> getHistoryRoute(BuildContext context) {
    assert(maybeOf(context) != null, 'Cannot find LifecycleNavigatorObserver');
    final navigator = Navigator.of(context);
    final history = _historyRoute.getOrPut(navigator, () => <Route>[]);
    return <Route>[...history];
  }

  bool checkVisible(Route route) {
    final nav = navigator ?? route.navigator;
    if (nav == null) return false;
    final history = _historyRoute[nav];
    if (history == null || history.isEmpty) return false;

    final rHistory = history.reversed;
    for (var element in rHistory) {
      if (element == route) return true;
      if (element is PageRoute) {
        break;
      }
    }
    return false;
  }
}

class LifecycleRoutePage extends StatefulWidget {
  final Widget child;

  const LifecycleRoutePage({Key? key, required this.child}) : super(key: key);

  @override
  State<LifecycleRoutePage> createState() => _LifecycleRoutePageState();
}

class _LifecycleRoutePageState extends State<LifecycleRoutePage>
    with
        AutomaticKeepAliveClientMixin,
        LifecycleOwnerStateMixin,
        LifecycleRoutePageState {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
