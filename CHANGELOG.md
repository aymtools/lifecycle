## 3.6.0

* Observers in LifecycleRegistryState are executed in their registration order when dispose is
  called.

## 3.5.1

* Code standardization

## 3.5.0

* Adjust all fully visible PageViewItems to be resumed.

## 3.4.1

* Code standardization

## 3.4.0

* LifecycleNavigatorObserver.hookMode adds pageKeepAlive parameter

## 3.3.0

* visibleRoutes use weak references for routes
* MockLifecycleRegistry rename to LifecycleRegistryMock
* MockLifecycleOwner rename to LifecycleOwnerMock

## 3.2.0

- Add MockLifecycleRegistry and MockLifecycleOwner to assist with testing.
- Add keepAlive parameter to LifecyclePageViewItem, LifecyclePageView, and LifecycleTabBarView.

## 3.1.5

- Fix the determination of the route's resumed state.

## 3.1.4

- In LifecycleRegistryStateDelegate, switch the state first and then execute the Observer during
  destroy.

## 3.1.3

- Fix a state transition check for the `resumed` state.

## 3.1.2

- Convert forEach to for loops for better control and performance.

## 3.1.1

- LifecycleNavigatorObserver.hookMode() adjusts the obfuscation retention for compatibility mode.

## 3.1.0

- Fix _HookOverlayEntry(`LifecycleNavigatorObserver.hookMode()`) passing opaque

## 3.0.3

- Optimize the README content and update the example to version 3.0.

## 3.0.2

- Fix the exception where the observer of LifecycleRegistryState calls remove during destroy.

## 3.0.1

- In the implementation of ILifecycleRegistry, allow calling addLifecycleObserver in the
  constructor.

## 3.0.0

- Refactored the `registry` content to ensure that the timing of invocations during `registry`
  registration is correct.

## 2.0.4

- Fixed the `destroy` error in `registerLifecycleObserverToOwner`.

## 2.0.3

- Removed `findLifecycleObserver` from `LifecycleObserverRegistry` and replaced it with extension
  compatibility mode.
- Fixed a bug in `LifecycleRouteOwner` where route records were incorrect
  in `LifecycleNavigatorObserver.didReplace`.
- Delayed the handling of the `resume` event for Rouge to align with the behavior of
  other `LifecycleOwnerWidget`s (triggered after `widget.build`).
- Added `removeCallback` to `LifecycleCallbacks`.

## 2.0.2

- Fixed the issue where the first `start` event was triggered after `build` (in versions 2.0.0,
  2.0.1); after the fix, the `start` event must occur before `build`.

## 2.0.1

- `addOnDidUpdateWidget` causes performance issues and will be removed in the next version.
- Provided `LifecycleObserverRegistryDelegate` to allow customization
  of `LifecycleObserverRegistryMixin`.
- Added `LifecycleObserverRegistryElementMixin` to mix the registry into custom elements.

## 2.0.0

- The lifecycle provider now uses `InheritedWidget` to ensure timely notifications of changes.
- Added handling for `LifecycleCallback` associations.
- Optimized and adjusted the project structure (which may introduce some compatibility issues).

## 1.0.5

- Fixed a bug where the `dispose` state was inconsistent with `!mounted`, causing page state
  anomalies.

## 1.0.4

- Corrected the judgment issue when there is scaling in `pageviewItem`.
- Fixed the transparency judgment in `routepage`.

## 1.0.3

- Corrected `EventStream` and `StateStream` to be synchronously invoked streams.
- Fixed the exception where `Register` could not be removed immediately after being added.

## 1.0.2

- Ensured that the first `owner` start event is always triggered before `build`.

## 1.0.1

- Optimized the judgment of `onStop` and `onPause` in `RoutePage`.

## 1.0.0

- Initial version released.
