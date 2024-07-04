part of 'lifecycle_navigator_observer.dart';

mixin LifecycleRouteOwnerState<T extends LifecycleRouteOwner>
    on LifecycleOwnerStateMixin<T> implements _RouteChanger {
  LifecycleNavigatorObserver? _observer;

  Route? get _modalRoute {
    if (widget.route != null) return widget.route;
    try {
      return ModalRoute.of(context);
    } catch (_) {
      return null;
    }
  }

  @override
  bool get customDispatchEvent => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    var observer = LifecycleNavigatorObserver.maybeOf(context);
    if (observer != _observer) {
      observer?._unsubscribe(this);
      _observer = observer;
      observer?._subscribe(this);
    }
    _scheduleHandleResumeNextFrame();
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
      final modalRoute = this._modalRoute;
      final isCurrent = modalRoute!.isCurrent;
      final isActive = modalRoute.isActive;
      if (isCurrent) {
        // lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
        _scheduleHandleResumeNextFrame();
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

  bool _doubleCheck = false;

  _scheduleHandleResumeNextFrame() {
    if (_observer == null) return;
    _doubleCheck = false;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (_doubleCheck) return;
      _doubleCheck = true;
      final modalRoute = this._modalRoute;
      final observer = _observer;
      if (observer == null || modalRoute == null) return;
      if (lifecycleRegistry.currentState <= LifecycleState.initialized) return;
      final isCurrent = modalRoute.isCurrent;
      final isActive = modalRoute.isActive;
      if (isCurrent) {
        lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      } else if (isActive) {
        // if (observer.getTopRoute() == modalRoute) {
        //   lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
        // } else
        if (observer.checkVisible(modalRoute)) {
          lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
        } else {
          lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
        }
      } else {
        lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
      }
    });
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
