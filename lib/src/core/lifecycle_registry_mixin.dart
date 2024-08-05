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

// @override
// LO? findLifecycleObserver<LO extends LifecycleObserver>() =>
//     _delegate.findLifecycleObserver<LO>();

  @protected
  LifecycleRegistryStateDelegate get lifecycleDelegate => _delegate;
}
//
// mixin LifecycleObserverRegistryMixin<W extends StatefulWidget> on State<W>
//     implements LifecycleObserverRegistry {
//   late final _LifecycleObserverRegistryMixin _delegate =
//       LifecycleObserverRegistryDelegate(
//           target: this, contextProvider: () => context as Element);
//
//   @override
//   LifecycleState get currentLifecycleState => _delegate.currentLifecycleState;
//
//   @override
//   Lifecycle get lifecycle => _delegate.lifecycle;
//
//   @override
//   void addLifecycleObserver(LifecycleObserver observer,
//       {LifecycleState? startWith, bool fullCycle = true}) {
//     _delegate.addLifecycleObserver(observer,
//         startWith: startWith, fullCycle: fullCycle);
//   }
//
//   @override
//   void removeLifecycleObserver(LifecycleObserver observer, {bool? fullCycle}) =>
//       _delegate.removeLifecycleObserver(observer, fullCycle: fullCycle);
//
//   // @override
//   // LO? findLifecycleObserver<LO extends LifecycleObserver>() =>
//   //     _delegate.findLifecycleObserver<LO>();
//
//   Set<void Function(W widget, W oldWidget)>? _onDidUpdateWidget;
//
//   @Deprecated('Not suitable to be placed in the current library')
//   void addOnDidUpdateWidget(void Function(W widget, W oldWidget) listener) {
//     if (_onDidUpdateWidget == null) {}
//     _onDidUpdateWidget!.add(listener);
//   }
//
//   @override
//   void didUpdateWidget(covariant W oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (_onDidUpdateWidget != null && _onDidUpdateWidget!.isNotEmpty) {
//       final listeners = List.of(_onDidUpdateWidget!, growable: false);
//       for (var l in listeners) {
//         l(widget, oldWidget);
//       }
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _delegate.initState();
//   }
//
//   @override
//   void didChangeDependencies() {
//     _delegate.didChangeDependencies();
//     super.didChangeDependencies();
//   }
//
//   @override
//   void dispose() {
//     _delegate.dispose();
//     _onDidUpdateWidget?.clear();
//     super.dispose();
//     _onDidUpdateWidget = null;
//   }
// }
