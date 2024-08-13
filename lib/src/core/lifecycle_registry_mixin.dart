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
