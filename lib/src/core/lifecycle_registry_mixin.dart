part of 'lifecycle.dart';

@Deprecated('use LifecycleRegistryStateDelegate')
typedef LifecycleObserverRegistryDelegate = LifecycleRegistryStateDelegate;

@Deprecated('use LifecycleRegistryDelegateMixin')
typedef LifecycleObserverRegistryDelegateMixin = LifecycleRegistryDelegateMixin;

/// 混入之后,需要调用 [lifecycleDelegate.initState] [lifecycleDelegate.didChangeDependencies] [lifecycleDelegate.deactivate] [lifecycleDelegate.activate] [lifecycleDelegate.dispose]
mixin LifecycleRegistryDelegateMixin implements LifecycleRegistryState {
  BuildContext get context;

  late final LifecycleRegistryStateDelegate _delegate =
      LifecycleRegistryStateDelegate(
          target: this, contextProvider: () => context as Element);

  @override
  void addLifecycleObserver(LifecycleObserver observer,
          {LifecycleState? startWith,
          bool fullCycle = true,
          bool destroyWithRegistry = true}) =>
      _delegate.addLifecycleObserver(observer,
          startWith: startWith,
          fullCycle: fullCycle,
          destroyWithRegistry: destroyWithRegistry);

  @override
  LifecycleState get currentLifecycleState => _delegate.currentLifecycleState;

  @override
  Lifecycle get lifecycle => _delegate.lifecycle;

  @override
  void removeLifecycleObserver(LifecycleObserver observer,
          {LifecycleState? willEnd, bool? fullCycle}) =>
      _delegate.removeLifecycleObserver(observer,
          willEnd: willEnd, fullCycle: fullCycle);

  @protected
  LifecycleRegistryStateDelegate get lifecycleDelegate => _delegate;
}

/// 混入state来临时管理和注册observer
mixin LifecycleRegistryStateMixin<W extends StatefulWidget> on State<W>
    implements LifecycleRegistryState {
  late LifecycleRegistryStateDelegate _delegate =
      LifecycleRegistryStateDelegate(
          target: this, contextProvider: () => context);

  @override
  void addLifecycleObserver(LifecycleObserver observer,
          {LifecycleState? startWith,
          bool fullCycle = true,
          bool destroyWithRegistry = true}) =>
      _delegate.addLifecycleObserver(observer,
          startWith: startWith,
          fullCycle: fullCycle,
          destroyWithRegistry: destroyWithRegistry);

  @override
  LifecycleState get currentLifecycleState => _delegate.currentLifecycleState;

  @override
  Lifecycle get lifecycle => _delegate.lifecycle;

  @override
  void removeLifecycleObserver(LifecycleObserver observer,
          {LifecycleState? willEnd, bool? fullCycle}) =>
      _delegate.removeLifecycleObserver(observer,
          willEnd: willEnd, fullCycle: fullCycle);

  @override
  void initState() {
    super.initState();
    _delegate.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _delegate.didChangeDependencies();
  }

  @override
  void deactivate() {
    _delegate.deactivate();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _delegate.activate();
  }

  @override
  void dispose() {
    _delegate.dispose();
    super.dispose();
  }
}

/// 混入Element来临时管理和注册observer
mixin LifecycleRegistryElementMixin on ComponentElement
    implements LifecycleRegistryState {
  late final LifecycleRegistryStateDelegate _delegate =
      LifecycleRegistryStateDelegate(target: this, contextProvider: () => this);

  @override
  void addLifecycleObserver(LifecycleObserver observer,
          {LifecycleState? startWith,
          bool fullCycle = true,
          bool destroyWithRegistry = true}) =>
      _delegate.addLifecycleObserver(observer,
          startWith: startWith,
          fullCycle: fullCycle,
          destroyWithRegistry: destroyWithRegistry);

  @override
  LifecycleState get currentLifecycleState => _delegate.currentLifecycleState;

  @override
  Lifecycle get lifecycle => _delegate.lifecycle;

  @override
  void removeLifecycleObserver(LifecycleObserver observer,
          {LifecycleState? willEnd, bool? fullCycle}) =>
      _delegate.removeLifecycleObserver(observer,
          willEnd: willEnd, fullCycle: fullCycle);

  bool _isFirstBuild = true;

  @override
  void mount(Element? parent, Object? newSlot) {
    final e = this;
    if (e is StatefulElement &&
        (e as StatefulElement).state is ILifecycleRegistry) {
      final state = (e as StatefulElement).state;
      if (state is LifecycleRegistryStateMixin) {
        state._delegate = _delegate;
      } else {
        assert(false,
            'LifecycleRegistryElementMixin state cannot be used with ILifecycleRegistry');
      }
    }

    if (parent != null) {
      _delegate.parentProvider = () => parent;
    }
    _delegate.initState();
    super.mount(parent, newSlot);
    _delegate.parentProvider = null;
  }

  @override
  void rebuild({bool force = false}) {
    if (_isFirstBuild) {
      _isFirstBuild = false;
      _delegate.didChangeDependencies();
    }
    super.rebuild(force: force);
  }

  @override
  void unmount() {
    super.unmount();
    _delegate.dispose();
  }

  @override
  void didChangeDependencies() {
    _delegate.didChangeDependencies();
    super.didChangeDependencies();
  }

  @override
  void deactivate() {
    _delegate.deactivate();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _delegate.deactivate();
  }
}
