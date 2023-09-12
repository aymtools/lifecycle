import 'package:flutter/widgets.dart';
import 'package:weak_collections/weak_collections.dart';

import 'lifecycle.dart';
import 'lifecycle_mixin.dart';

abstract class _RouteChanger {
  void onChange();
}

mixin LifecycleRoutePageState<T extends StatefulWidget>
    on LifecycleOwnerState<T> implements _RouteChanger {
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
    var observer = Navigator.of(context)
        .widget
        .observers
        .whereType<LifecycleNavigatorObserver>()
        .firstOrNull;
    assert(observer != null, 'Cannot find LifecycleNavigatorObserver');
    if (observer != null) {
      _observer = observer;
      observer.subscribe(this);
    }
  }

  @override
  void onChange() {
    final modalRoute = ModalRoute.of(context);
    if (lifecycleRegistry.currentState > LifecycleState.initialized) {
      lifecycleRegistry.handleLifecycleEvent(modalRoute!.isCurrent
          ? LifecycleEvent.resume
          : modalRoute.isActive
              ? LifecycleEvent.pause
              : LifecycleEvent.stop);
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

  final WeakSet<_RouteChanger> _listeners = WeakSet<_RouteChanger>();

  void subscribe(_RouteChanger changer) {
    _listeners.add(changer);
  }

  // void unsubscribe(_RouteChanger changer) {
  //   // _listeners
  // }

  void _notifyChange() {
    for (var element in _listeners) {
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

    _notifyChange();
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);

    _notifyChange();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);

    _notifyChange();
  }
}

class LifecycleRoutePage extends StatefulWidget {
  final Widget child;

  const LifecycleRoutePage({Key? key, required this.child}) : super(key: key);

  @override
  _LifecycleRoutePageState createState() => _LifecycleRoutePageState();
}

class _LifecycleRoutePageState extends State<LifecycleRoutePage>
    with
        AutomaticKeepAliveClientMixin,
        LifecycleOwnerState,
        LifecycleRoutePageState {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
