part of 'lifecycle.dart';

// class LifecycleScope {}
//
//
// mixin LifecycleObserverRegistryElementMixin on ComponentElement
//     implements ILifecycleRegistry {
//   late final LifecycleObserverRegistryDelegate
//       _lifecycleObserverRegistryDelegate = LifecycleObserverRegistryDelegate(
//           target: this, contextProvider: () => this);
//
//   @override
//   void addLifecycleObserver(LifecycleObserver observer,
//           {LifecycleState? startWith, bool fullCycle = true}) =>
//       _lifecycleObserverRegistryDelegate.addLifecycleObserver(observer,
//           startWith: startWith, fullCycle: fullCycle);
//
//   @override
//   LifecycleState get currentLifecycleState =>
//       _lifecycleObserverRegistryDelegate.currentLifecycleState;
//
//   // @override
//   // LO? findLifecycleObserver<LO extends LifecycleObserver>() =>
//   //     _lifecycleObserverRegistryDelegate.findLifecycleObserver();
//
//   @override
//   Lifecycle get lifecycle => _lifecycleObserverRegistryDelegate.lifecycle;
//
//   @override
//   void removeLifecycleObserver(LifecycleObserver observer, {LifecycleState? willEnd,bool? fullCycle}) =>
//       _lifecycleObserverRegistryDelegate.removeLifecycleObserver(observer,
//           fullCycle: fullCycle);
//
//   bool _isFirstBuild = true;
//
//   @override
//   void mount(Element? parent, Object? newSlot) {
//     _lifecycleObserverRegistryDelegate.initState();
//     super.mount(parent, newSlot);
//   }
//
//   @override
//   void rebuild({bool force = false}) {
//     if (_isFirstBuild) {
//       _isFirstBuild = false;
//       assert(() {
//         final e = this;
//         if (e is StatefulElement &&
//             (e as StatefulElement).state is ILifecycleRegistry) {
//           return false;
//         }
//         return true;
//       }(),
//           'LifecycleObserverRegistryElementMixin cannot be used with ILifecycleRegistry');
//       _lifecycleObserverRegistryDelegate.didChangeDependencies();
//     }
//     super.rebuild(force: force);
//   }
//
//   @override
//   void unmount() {
//     super.unmount();
//     _lifecycleObserverRegistryDelegate.dispose();
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     _lifecycleObserverRegistryDelegate.didChangeDependencies();
//   }
// }
