AnLifecycle draws on lifecycle in androidx to implement lifecycle on Flutter.
Developers can sense the LifecycleState under the current context wherever you need it.

## Describe

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
  created,

  /// Started state for a LifecycleOwner.
  /// this state is reached in two cases:
  /// after [LifecycleEvent.start] call;  fist [State.didChangeDependencies]
  /// right before [LifecycleEvent.pause] call.  Overridden non-Page routes, such as dialog
  started,

  /// Resumed state for a LifecycleOwner. 
  /// this state is reached after  [LifecycleEvent.resume] is called. Route.isCurrent
  resumed,
}

```

## Usage

#### 1.1 Use LifecycleApp to wrap the default App to receive native related life cycles

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use LifecycleApp to wrap the default App
    return LifecycleApp(
      child: MaterialApp(),
    );
  }
}
```

#### 1.2 Use LifecycleNavigatorObserver.hookMode() to register routing event changes.
Note: If you use LifecycleNavigatorObserver, you must use LifecycleRoute to wrap the PageContent to distribute lifecycle events.

```dart
 class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LifecycleApp(
      child: MaterialApp(
        title: 'LifecycleApp Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        //Use LifecycleNavigatorObserver.hookMode() to register routing event changes
        //If you use LifecycleNavigatorObserver, you must use LifecycleRoute to wrap the PageContent to distribute lifecycle events.
        navigatorObservers: [
          LifecycleNavigatorObserver.hookMode(),
        ],
        routes: routes,
      ),
    );
  }
}
```

#### 1.3 Take advantage of the full lifecycle states and lifecycle events

```dart
mixin LifecycleEventPrinter<W extends StatefulWidget>
on LifecycleObserverRegistryMixin<W> {
  String get otherTag => '';

  @override
  void initState() {
    super.initState();
    final printer = LifecycleObserver.eventAny((event) {
      print('LifecycleEventPrinter $runtimeType $otherTag $event');
    });
    addLifecycleObserver(printer);
  }
}


mixin LifecycleStatePrinter<W extends StatefulWidget>
on LifecycleObserverRegistryMixin<W> {
  String get otherTag => '';

  @override
  void initState() {
    super.initState();
    final printer = LifecycleObserver.stateChange((state) {
      print('LifecycleStatePrinter $runtimeType $otherTag $state');
    });
    addLifecycleObserver(printer);
  }
}

class FistPage extends StatefulWidget {
  const FistPage({super.key});

  @override
  State<FistPage> createState() => _FistPageState();
}

class _FistPageState extends State<FistPage>
    with LifecycleObserverRegistryMixin, LifecycleEventPrinter {
}

```

See [example](https://github.com/aymtools/lifecycle/blob/main/example/) for detailed test
case.

## Issues

If you encounter issues, here are some tips for debug, if nothing helps report
to [issue tracker on GitHub](https://github.com/aymtools/lifecycle/issues):