AnLifecycle draws on lifecycle in androidx to implement lifecycle on Flutter.
Developers can sense the LifecycleState under the current context wherever you need it.

## Describe

The types of events and states refer to the definitions in AndroidX's lifecycle.

```dart

enum LifecycleEvent {
  /// Constant for create event of the LifecycleOwner.
  create,

  /// Constant for start event of the LifecycleOwner.
  start,

  /// Constant for resume event of the LifecycleOwner.
  resume,

  /// Constant for pause event of the LifecycleOwner.
  pause,

  /// Constant for stop event of the LifecycleOwner.
  stop,

  /// Constant for destroy event of the LifecycleOwner.
  destroy,
}

/// Lifecycle states.
enum LifecycleState {
  /// Destroyed state for a LifecycleOwner. After this event, this Lifecycle will not dispatch any more events.
  /// this state is reached right before [LifecycleEvent.destroy] call.   [State.dispose]
  destroyed,

  ///Initialized state for a LifecycleOwner.
  /// this is the state when it is constructed but has not received [LifecycleEvent.create] yet.
  initialized,

  /// Created state for a LifecycleOwner.
  /// this state is reached in two cases:
  /// after [LifecycleEvent.create] call;  [State.initState]
  /// right before [LifecycleEvent.stop] call. [State.deactivate]
  /// This means that the current UI is completely invisible.
  created,

  /// Started state for a LifecycleOwner.
  /// this state is reached in two cases:
  /// after [LifecycleEvent.start] call;  fist [State.didChangeDependencies]
  /// right before [LifecycleEvent.pause] call.  Overridden non-Page routes, such as dialog
  /// This means that the current UI is partially visible but cannot respond to events.
  started,

  /// Resumed state for a LifecycleOwner. 
  /// this state is reached after  [LifecycleEvent.resume] is called. Route.isCurrent
  /// This means that the current UI is visible and interactive.
  resumed,
}

```

## Usage

#### 1.1 Wrap your app with LifecycleApp, and register LifecycleNavigatorObserver.hookMode() to your Navigator or the navigatorObservers of MaterialApp.

Note: If you use LifecycleNavigatorObserver, you must use LifecycleRoute to wrap the PageContent to
distribute lifecycle events.

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use LifecycleApp to wrap the default App
    return LifecycleApp(
      child: MaterialApp(
        navigatorObservers: [
          //Use LifecycleNavigatorObserver.hookMode() to register routing event changes
          //If you use LifecycleNavigatorObserver, you must use LifecycleRoute to wrap the PageContent to distribute lifecycle events.
          LifecycleNavigatorObserver.hookMode(),
        ],

        ///...
      ),
    );
  }
}
```

#### 1.2 If you also need to observe the lifecycle of items within a PageView or TabBarView, you can replace them with LifecyclePageView or LifecycleTabBarView.

```dart
class PageViewDemo extends StatelessWidget {
  const PageViewDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return LifecyclePageView(
      children: [
        for (int i = 0; i < 9; i++) ItemView(index: i),
      ],

      /// more
    );
  }
}

class PageViewBuilderDemo extends StatelessWidget {
  const PageViewDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return LifecyclePageView.builder(
      itemCount: 10,
      itemBuilder: (context, index) => ItemView(index: i),

      /// more
    );
  }
}

class TabBarViewDemo extends StatelessWidget {
  const TabBarViewDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return LifecycleTabBarView(
      children: [
        for (int i = 0; i < 9; i++) ItemView(index: i),
      ],

      /// more
    );
  }
}
```

If you don't want to modify the contents of PageView or TabView, you can also wrap your item with
LifecyclePageViewItem.

```dart
class PageViewDemo extends StatelessWidget {
  const PageViewDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return PageView(
      children: [
        // use LifecyclePageViewItem
        for (int i = 0; i < 9; i++) LifecyclePageViewItem(index: i, child: ItemView(index: i)),
      ],

      /// more
    );
  }
}
```

#### 1.3 Take advantage of the full lifecycle states and lifecycle events

```dart
class FistPage extends StatefulWidget {
  const FistPage({super.key});

  @override
  State<FistPage> createState() => _FistPageState();
}

/// Mix-n LifecycleRegistryStateMixin are available, but it's highly recommended to use the [an_lifecycle_cancellable] package's launchWhenXXX, repeatOnXXX, and collectOnXXX methods.
class _FistPageState extends State<FistPage>
    with LifecycleRegistryStateMixin {

  @override
  void initState() {
    super.initState();

    /// Register and print the current lifecycle state changes.
    addLifecycleObserver(LifecycleObserver.stateChange((state) {
      print('LifecycleStatePrinter $runtimeType $state');
    }));

    /// Register and print the current lifecycle event.
    addLifecycleObserver(LifecycleObserver.eventAny((event) {
      print('LifecycleEventPrinter $runtimeType $event');
    }));
  }
}

```

See [example](https://github.com/aymtools/lifecycle/blob/main/example/) for detailed test
case.

## Recommend

It is recommended to
use [an_lifecycle_cancellable](https://pub.dev/packages/an_lifecycle_cancellable) for more
convenient usage.

## Issues

If you encounter issues, here are some tips for debug, if nothing helps report
to [issue tracker on GitHub](https://github.com/aymtools/lifecycle/issues):