import 'package:flutter/widgets.dart';
// import 'package:weak_collections/weak_collections.dart';

import 'lifecycle.dart';
import 'lifecycle_mixin.dart';

abstract class _RouteChanger {
  void onChange();
}

mixin LifecycleRoutePageState<T extends StatefulWidget>
    on LifecycleOwnerStateMixin<T> implements _RouteChanger {
  LifecycleNavigatorObserver? _observer;

  @override
  bool get customDispatchEvent => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    var observer = LifecycleNavigatorObserver.maybeOf(context);
    if (observer != _observer) {
      _observer = observer;
      observer?._subscribe(this);
    }

    // final modalRoute = ModalRoute.of(context);
    // if (modalRoute?.isFirst == true) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => onChange());
    // }
  }

  @override
  void onChange() {
    if (!mounted) {
      _observer?._unsubscribe(this);
      return;
    }
    final modalRoute = ModalRoute.of(context);
    if (lifecycleRegistry.currentState > LifecycleState.initialized) {
      final isCurrent = modalRoute!.isCurrent;
      final isActive = modalRoute.isActive;
      if (isCurrent) {
        lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      } else if (isActive) {
        final history = LifecycleNavigatorObserver.getHistoryRoute(context);

        final find =
            history.lastWhere((e) => e is PageRoute, orElse: () => modalRoute);
        if (find == modalRoute) {
          lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
        } else {
          lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
        }
      } else {
        lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
      }
    }
  }
}

Expando<Set<_RouteChanger>> _navigatorRouteChanger =
    Expando('navigatorRouteChanger');

Expando<List<Route>> _historyRoute = Expando('_historyRoute');

extension _ExpandoGetOrPutExt<T extends Object> on Expando<T> {
  T getOrPut(Object? key, T Function() defaultValue) {
    if (key == null) return defaultValue();
    T? r = this[key];
    if (r == null) {
      r = defaultValue();
      this[key] = r;
    }
    return r;
  }
}

class LifecycleNavigatorObserver extends NavigatorObserver {
//   static final Map<String, LifecycleNavigatorObserver> _cache = {};
//   static final LifecycleNavigatorObserver _primary =
//       LifecycleNavigatorObserver._();
//
//   LifecycleNavigatorObserver._();
//
//   factory LifecycleNavigatorObserver.primary() {
//     return _primary;
//   }
//
//   factory LifecycleNavigatorObserver(String tag) {
//     return _cache.putIfAbsent(tag, () => LifecycleNavigatorObserver._());
//   }

  void _subscribe(_RouteChanger changer) {
    final nav = navigator;
    if (nav != null) {
      var listeners = _navigatorRouteChanger[nav];
      if (listeners == null) {
        listeners = <_RouteChanger>{};
        _navigatorRouteChanger[nav] = listeners;
      }
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
      final listeners = _navigatorRouteChanger[nav];
      if (listeners != null && listeners.isNotEmpty) {
        final ls = List.from(listeners);
        for (var element in ls) {
          element.onChange();
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
