part of 'lifecycle.dart';

const _lifecycleOwnerBuildReturn = SizedBox.shrink();

mixin LifecycleObserverRegistryMixin<W extends StatefulWidget> on State<W>
    implements LifecycleObserverRegistry {
  late final _LifecycleObserverRegistryDelegate _delegate = () {
    final delegate = _LifecycleObserverRegistryDelegate(target: this);
    assert(mounted);
    context.visitAncestorElements((element) {
      final p =
          element.dependOnInheritedWidgetOfExactType<_EffectiveLifecycle>();
      delegate.lifecycle = p?.lifecycle;
      return false;
    });
    return delegate;
  }();

  @override
  LifecycleState get currentLifecycleState => _delegate.currentLifecycleState;

  @override
  Lifecycle get lifecycle => _delegate.lifecycle;

  @override
  void addLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? startWith, bool fullCycle = true}) {
    _delegate.addLifecycleObserver(observer,
        startWith: startWith, fullCycle: fullCycle);
  }

  @override
  void removeLifecycleObserver(LifecycleObserver observer, {bool? fullCycle}) =>
      _delegate.removeLifecycleObserver(observer, fullCycle: fullCycle);

  @override
  LO? findLifecycleObserver<LO extends LifecycleObserver>() =>
      _delegate.findLifecycleObserver<LO>();

  Set<void Function(W widget, W oldWidget)>? _onDidUpdateWidget;

  void addOnDidUpdateWidget(void Function(W widget, W oldWidget) listener) {
    if (_onDidUpdateWidget == null) {}
    _onDidUpdateWidget!.add(listener);
  }

  @override
  void didUpdateWidget(covariant W oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_onDidUpdateWidget != null && _onDidUpdateWidget!.isNotEmpty) {
      final listeners = List.of(_onDidUpdateWidget!, growable: false);
      for (var l in listeners) {
        l(widget, oldWidget);
      }
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = context.dependOnInheritedWidgetOfExactType<_EffectiveLifecycle>();
    _delegate.lifecycle = p?.lifecycle;
  }

  @override
  void dispose() {
    _delegate.dispose();
    _onDidUpdateWidget?.clear();
    super.dispose();
    _onDidUpdateWidget = null;
  }
}

mixin LifecycleOwnerStateMixin<LOW extends LifecycleOwnerWidget> on State<LOW>
    implements LifecycleOwner, LifecycleObserverRegistryMixin<LOW> {
  late final LifecycleRegistry _lifecycle;

  @override
  late final _LifecycleObserverRegistryDelegate _delegate =
      _LifecycleObserverRegistryDelegate(target: this)..lifecycle = _lifecycle;

  @override
  Lifecycle get lifecycle => _lifecycle;

  @protected
  LifecycleRegistry get lifecycleRegistry => _lifecycle;

  bool _isInactivate = false;

  bool get customDispatchEvent => false;

  @override
  LifecycleState get currentLifecycleState => _delegate.currentLifecycleState;

  @override
  void addLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? startWith, bool fullCycle = true}) {
    _delegate.addLifecycleObserver(observer,
        startWith: startWith, fullCycle: fullCycle);
  }

  @override
  void removeLifecycleObserver(LifecycleObserver observer, {bool? fullCycle}) =>
      _delegate.removeLifecycleObserver(observer, fullCycle: fullCycle);

  @override
  LO? findLifecycleObserver<LO extends LifecycleObserver>() =>
      _delegate.findLifecycleObserver<LO>();

  @override
  Set<void Function(LOW widget, LOW oldWidget)>? _onDidUpdateWidget;

  @override
  void addOnDidUpdateWidget(void Function(LOW widget, LOW oldWidget) listener) {
    if (_onDidUpdateWidget == null) {}
    _onDidUpdateWidget!.add(listener);
  }

  @override
  void didUpdateWidget(covariant LOW oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_onDidUpdateWidget != null && _onDidUpdateWidget!.isNotEmpty) {
      final listeners = List.of(_onDidUpdateWidget!, growable: false);
      for (var l in listeners) {
        l(widget, oldWidget);
      }
    }
  }

  @override
  void deactivate() {
    _isInactivate = false;
    if (customDispatchEvent) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
    }
    super.deactivate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isInactivate = true;
    if (!customDispatchEvent) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      WidgetsBinding.instance.addPostFrameCallback(_defDispatchResume);
    }
  }

  void _defDispatchResume(_) {
    if (_isInactivate &&
        !customDispatchEvent &&
        currentLifecycleState > LifecycleState.destroyed) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
    }
  }

  @override
  void dispose() {
    _onDidUpdateWidget?.clear();
    super.dispose();
    _onDidUpdateWidget = null;
  }

  @override
  Widget build(BuildContext context) => buildReturn;

  Widget get buildReturn => _lifecycleOwnerBuildReturn;
}
