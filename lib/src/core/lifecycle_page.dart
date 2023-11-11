import 'package:flutter/widgets.dart';
import 'package:weak_collections/weak_collections.dart';

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

  void _recheckResume(dynamic v) {
    if (mounted &&
        lifecycleRegistry.getCurrentState() > LifecycleState.destroyed) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var observers = Navigator.of(context)
        .widget
        .observers
        .whereType<LifecycleNavigatorObserver>();
    final observer = observers.isEmpty ? null : observers.first;
    assert(observer != null, 'Cannot find LifecycleNavigatorObserver');
    if (observer != null) {
      _observer = observer;
      observer._subscribe(this);
    }

    final modalRoute = ModalRoute.of(context);
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
        final history = _observer!._history;

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

class LifecycleNavigatorObserver extends NavigatorObserver {
  static final Map<String, LifecycleNavigatorObserver> _cache = {};
  static final LifecycleNavigatorObserver _primary =
      LifecycleNavigatorObserver._();

  LifecycleNavigatorObserver._();

  factory LifecycleNavigatorObserver.primary() {
    return _primary;
  }

  factory LifecycleNavigatorObserver(String tag) {
    return _cache.putIfAbsent(tag, () => LifecycleNavigatorObserver._());
  }

  final Set<_RouteChanger> _listeners = {};

  final List<Route> _history = [];

  void _subscribe(_RouteChanger changer) {
    _listeners.add(changer);
  }

  void _unsubscribe(_RouteChanger changer) {
    _listeners.remove(changer);
  }

  void _notifyChange() {
    final ls = List.from(_listeners);
    for (var element in ls) {
      element.onChange();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // if (previousRoute != null) {
    //   _listeners[previousRoute]?.toList().forEach((element) {
    //     element.onChange();
    //   });
    // }
    // _listeners[route]?.toList().forEach((element) {
    //   element.onChange();
    // });
    _history.remove(route);
    _notifyChange();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // if (previousRoute != null) {
    //   _listeners[previousRoute]?.toList().forEach((element) {
    //     element.onChange();
    //   });
    // }
    // _listeners[route]?.toList().forEach((element) {
    //   element.onChange();
    // });

    _history.add(route);
    _notifyChange();
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);

    _history.remove(route);
    _notifyChange();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);

    if (oldRoute != null) _history.remove(oldRoute);
    if (newRoute != null) _history.add(newRoute);
    _notifyChange();
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
