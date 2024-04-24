part of 'lifecycle_navigator_observer.dart';

mixin LifecycleRouteOwnerState<T extends LifecycleRouteOwner>
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

class LifecycleRouteOwner extends LifecycleOwnerWidget {
  final Route? route;

  const LifecycleRouteOwner({this.route, super.key, required super.child});

  @override
  LifecycleRouteOwnerState<LifecycleRouteOwner> createState() =>
      _LifecycleRouteState();
}

class _LifecycleRouteState extends State<LifecycleRouteOwner>
    with
        AutomaticKeepAliveClientMixin,
        LifecycleOwnerStateMixin,
        LifecycleRouteOwnerState {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return buildReturn;
  }
}

abstract class LifecycleRouteOwnerBaseState<LOW extends LifecycleRouteOwner>
    extends State<LOW>
    with LifecycleOwnerStateMixin, LifecycleRouteOwnerState {}

typedef LifecycleRoutePage = LifecycleRouteOwner;

typedef LifecycleRoutePageState<T extends LifecycleRouteOwner>
    = LifecycleRouteOwnerState<T>;
