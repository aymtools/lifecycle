import 'package:anlifecycle/anlifecycle.dart';
import 'package:anlifecycle/src/tools/list_ext.dart';
import 'package:flutter/widgets.dart';

part 'lifecycle_route.dart';

abstract class _RouteChanger {
  void onChange(bool Function(Route route) checkVisible);
}

Expando<Set<_RouteChanger>> _navigatorRouteChanger =
    Expando('navigatorRouteChanger');

Expando<List<Route>> _historyRoute = Expando('_historyRoute');

extension _ExpandoGetOrPutExt<T extends Object> on Expando<T> {
  T getOrPut(Object? key, T Function() defaultValue) {
    if (key == null) return defaultValue();
    T? result = this[key];
    if (result == null) {
      result = defaultValue();
      this[key] = result;
    }
    return result;
  }
}

class LifecycleNavigatorObserver extends NavigatorObserver {
  final List<Route> _visibleRoutes = [];

  LifecycleNavigatorObserver();

  /// 启用hook之后将会导致maintainState 无法动态改变(目前暂未遇到此需求) 可以配合[LifecycleRouteMixin]来跳过hook自定义分发，也可以直接使用默认构造函数完全自定义你的route状态
  factory LifecycleNavigatorObserver.hookMode() => LifecycleHookObserver();

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
    _visibleRoutes.clear();
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
      _visibleRoutes.addAll(vRoute);

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
    var observers = Navigator.of(context)
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
    if (_visibleRoutes.isNotEmpty && route.navigator == navigator) {
      return _visibleRoutes.contains(route);
    }

    final nav = navigator ?? route.navigator;
    if (nav == null) return false;
    final history = _historyRoute[nav];
    if (history == null || history.isEmpty) return false;

    final rHistory = history.reversed;
    for (var element in rHistory) {
      if (element == route) return true;
      if (element is PageRoute && element.opaque == true) {
        break;
      }
    }
    return false;
  }
}

/// 启用hook之后将会导致maintainState 无法动态改变(目前暂未遇到此需求)
class LifecycleHookObserver extends LifecycleNavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    if (route is ModalRoute) {
      _hook(route);
    }
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (newRoute is ModalRoute) {
      _hook(newRoute);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _hook(ModalRoute route) {
    if (route is LifecycleRouteMixin && (route as LifecycleRouteMixin).doNotHookMe) {
      return;
    }

    final entries = route.overlayEntries;
    final find = entries.firstWhereTypeOrNull<_HookOverlayEntry>();
    if (find == null && entries.isNotEmpty) {
      int index = entries.length > 1 ? 1 : 0;
      final needHook = entries[index];
      entries[index] = _HookOverlayEntry(
          builder: needHook.builder,
          maintainState: needHook.maintainState,
          route: route);
    }
  }
}

mixin LifecycleRouteMixin<T> on OverlayRoute<T> {
  /// 启用hook之后将会导致maintainState 无法动态改变(目前暂未遇到此需求) 如需要在执行的过程中动态变化 使用此混入关闭hook进行定制
  /// 如需穿透当前的route 则不需要任何处理
  /// 如需要自定义lifecycle 推荐按使用 在buildPage中返回 LifecycleRoute包裹的widget
  bool doNotHookMe = false;
}

Widget Function(BuildContext) _hookBuilder(
    Widget Function(BuildContext) source, ModalRoute route) {
  return (context) => LifecycleRouteOwner(
        route: route,
        child: Builder(
          builder: source,
        ),
      );
}

class _HookOverlayEntry extends OverlayEntry {
  _HookOverlayEntry({
    required this.route,
    required Widget Function(BuildContext) builder,
    super.opaque,
    super.maintainState,
  }) : super(builder: _hookBuilder(builder, route));
  final ModalRoute route;

  @override
  bool get maintainState => route.maintainState;
}
