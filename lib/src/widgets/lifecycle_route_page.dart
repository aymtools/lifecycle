part of 'lifecycle_navigator_observer.dart';

class LifecycleRoutePage extends LifecycleOwnerWidget {
  final Route? route;

  const LifecycleRoutePage({this.route, super.key, required super.child});

  @override
  LifecycleRoutePageState<LifecycleRoutePage> createState() =>
      _LifecycleRoutePageState();
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
    return buildReturn;
  }
}

mixin LifecycleRoutePageState<T extends LifecycleRoutePage>
    on LifecycleOwnerStateMixin<T> implements _RouteChanger {
  LifecycleNavigatorObserver? _observer;

  @override
  bool get customDispatchEvent => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    var observer = LifecycleNavigatorObserver.maybeOf(context);
    if (observer != _observer) {
      observer?._unsubscribe(this);
      _observer = observer;
      observer?._subscribe(this);
    }

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (_observer?.navigator != null) {
        onChange(_observer!.checkVisible);
      }
    });
  }

  @override
  void dispose() {
    _observer?._unsubscribe(this);
    super.dispose();
    _observer = null;
  }

  @override
  void onChange(bool Function(Route route) checkVisible) {
    if (!mounted) {
      _observer?._unsubscribe(this);
      return;
    }
    if (_observer == null) return;
    if (lifecycleRegistry.currentState > LifecycleState.initialized) {
      final modalRoute = widget.route ?? ModalRoute.of(context);
      final isCurrent = modalRoute!.isCurrent;
      final isActive = modalRoute.isActive;
      if (isCurrent) {
        lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      } else if (isActive) {
        if (checkVisible(modalRoute)) {
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

