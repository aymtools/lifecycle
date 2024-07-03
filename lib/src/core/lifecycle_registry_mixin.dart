part of 'lifecycle_registry.dart';

const _lifecycleOwnerBuildReturn = SizedBox.shrink();

mixin LifecycleObserverRegistryMixin<W extends StatefulWidget> on State<W>
    implements LifecycleObserverRegistry {
  late final _LifecycleObserverRegistryMixin _delegate =
      LifecycleObserverRegistryDelegate(
          target: this,
          parentElementProvider: () {
            late Element parent;
            context.visitAncestorElements((element) {
              parent = element;
              return false;
            });
            return parent;
          });

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

  // @override
  // LO? findLifecycleObserver<LO extends LifecycleObserver>() =>
  //     _delegate.findLifecycleObserver<LO>();

  Set<void Function(W widget, W oldWidget)>? _onDidUpdateWidget;

  @Deprecated('Not suitable to be placed in the current library')
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
    _delegate.initState();
  }

  @override
  void didChangeDependencies() {
    _delegate.didChangeDependencies();
    super.didChangeDependencies();
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
  @override
  late final _LifecycleObserverRegistryDelegate _delegate =
      _LifecycleObserverRegistryDelegate(target: this);

  late final LifecycleRegistry _lifecycleRegistry;

  set _lifecycle(LifecycleRegistry registry) {
    _lifecycleRegistry = registry;
    _delegate.lifecycle = registry;
  }

  @protected
  LifecycleRegistry get lifecycleRegistry => _lifecycleRegistry;

  @override
  Lifecycle get lifecycle => _lifecycleRegistry;

  @override
  LifecycleState get currentLifecycleState => lifecycle.currentState;

  bool _isInactivate = false;

  bool get customDispatchEvent => false;

  @override
  dynamic get scope => widget.scope;

  bool _firstDidChangeDependencies = true;

  @override
  void addLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? startWith, bool fullCycle = true}) {
    _delegate.addLifecycleObserver(observer,
        startWith: startWith, fullCycle: fullCycle);
  }

  @override
  void removeLifecycleObserver(LifecycleObserver observer, {bool? fullCycle}) =>
      _delegate.removeLifecycleObserver(observer, fullCycle: fullCycle);

  // @override
  // LO? findLifecycleObserver<LO extends LifecycleObserver>() =>
  //     _delegate.findLifecycleObserver<LO>();

  @override
  Set<void Function(LOW widget, LOW oldWidget)>? _onDidUpdateWidget;

  @Deprecated('Not suitable to be placed in the current library')
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
    if (!customDispatchEvent) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
    }
    super.deactivate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isInactivate = true;
    if (_firstDidChangeDependencies) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      _firstDidChangeDependencies = false;
    }
    if (!customDispatchEvent) {
      if (lifecycleRegistry.currentState < LifecycleState.started) {
        lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      }
      WidgetsBinding.instance.addPostFrameCallback(_defDispatchResume);
    }
  }

  @override
  void activate() {
    super.activate();
    _isInactivate = true;
    if (!customDispatchEvent &&
        lifecycleRegistry.currentState < LifecycleState.resumed) {
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
    _delegate.dispose();
    _onDidUpdateWidget?.clear();
    super.dispose();
    _onDidUpdateWidget = null;
  }

  @override
  Widget build(BuildContext context) => buildReturn;

  Widget get buildReturn => _lifecycleOwnerBuildReturn;
}
