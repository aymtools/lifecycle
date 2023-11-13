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

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart

const like = 'sample';
```

See [example](https://github.com/aymtools/lifecycle/blob/master/example/) for detailed test
case.

## Issues

If you encounter issues, here are some tips for debug, if nothing helps report
to [issue tracker on GitHub](https://github.com/aymtools/lifecycle/issues):