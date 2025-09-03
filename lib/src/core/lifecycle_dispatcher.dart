part of 'lifecycle.dart';

LifecycleState _minState(LifecycleState state, LifecycleState state1) =>
    LifecycleState.values[min(state.index, state1.index)];

/// 管理 observers
abstract class LifecycleRegistry implements Lifecycle {
  void bindParentLifecycle(Lifecycle? parent);

  void handleLifecycleEvent(LifecycleEvent event);

  @Deprecated('will only use in test')
  void clearObserver();

  Set<LifecycleObserver> get observers;
}

abstract class _LifecycleObserverDispatcher {
  final LifecycleObserver _observer;
  LifecycleState _state;
  bool _fullCycle;

  _LifecycleObserverDispatcher._(this._observer, this._state, this._fullCycle);

  factory _LifecycleObserverDispatcher(
      LifecycleState state, LifecycleObserver observer, bool fullCycle) {
    if (observer is LifecycleStateChangeObserver) {
      return _LifecycleObserverDispatcher.state(state, observer, fullCycle);
    } else if (observer is LifecycleEventObserver) {
      return _LifecycleObserverDispatcher.event(state, observer, fullCycle);
    }
    throw 'observer is not LifecycleStateChangeObserver or LifecycleEventObserver';
  }

  factory _LifecycleObserverDispatcher.state(LifecycleState state,
          LifecycleStateChangeObserver observer, bool fullCycle) =>
      _LifecycleObserverStateDispatcher(observer, state, fullCycle);

  factory _LifecycleObserverDispatcher.event(LifecycleState state,
          LifecycleEventObserver observer, bool fullCycle) =>
      _LifecycleObserverEventDispatcher(observer, state, fullCycle);

  void dispatchEvent(LifecycleOwner owner, LifecycleEvent event);
}

class _LifecycleRegistryImpl extends LifecycleRegistry {
  final LifecycleOwner provider;

  Lifecycle? _parentLifecycle;

  @override
  Lifecycle? get parent => _parentLifecycle;

  //由父容器提供的最大值
  LifecycleState _maxState = LifecycleState.resumed;

  //当前容器想要获得的最大期望
  LifecycleState _expectState = LifecycleState.initialized;

  //上次移动状态后的记录
  LifecycleState _lastState = LifecycleState.initialized;

  @override
  LifecycleOwner get owner => provider;

  late final _parentStateChanger =
      LifecycleObserver.stateChange(_handleMaxLifecycleStateChange);

  final LinkedHashMap<LifecycleObserver, _LifecycleObserverDispatcher>
      _observers = LinkedHashMap.identity();

  _LifecycleRegistryImpl(this.provider);

  @override
  void addLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? startWith, bool fullCycle = true}) {
    _addObserver(observer, startWith ?? LifecycleState.initialized, fullCycle);
  }

  @override
  void removeLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? willEnd, bool? fullCycle}) {
    _LifecycleObserverDispatcher? dispatcher = _observers.remove(observer);
    if (dispatcher != null) {
      if (willEnd == null) {
        fullCycle ??= dispatcher._fullCycle;
        if (fullCycle == true) {
          willEnd = LifecycleState.destroyed;
        } else {
          willEnd = LifecycleState.resumed;
        }
      }
      if (dispatcher is _LifecycleObserverProxyDispatcher) {
        dispatcher.willRemove.call(this, dispatcher._observer, willEnd);
      } else {
        if (willEnd.index < dispatcher._state.index) {
          _moveState(provider, dispatcher, willEnd, (_) => true);
        }
      }
    }
  }

  void _addObserver(
      LifecycleObserver observer, LifecycleState? defState, bool fullCycle) {
    defState =
        _minState(getCurrentState(), defState ?? LifecycleState.destroyed);

    _addObserverDispatcher(
        observer, _LifecycleObserverDispatcher(defState, observer, fullCycle));
  }

  void _addObserverDispatcher(
      LifecycleObserver observer, _LifecycleObserverDispatcher dispatcher) {
    LifecycleState current = getCurrentState();
    if (current == LifecycleState.destroyed) return;
    if (_observers.containsKey(observer)) {
      return;
    }
    _observers[observer] = dispatcher;
    _moveState(provider, dispatcher, current, _observers.containsValue);
  }

  @override
  void clearObserver() => _observers.clear();

  @override
  Set<LifecycleObserver> get observers => _observers.keys.toSet();

  @override
  LifecycleState get currentLifecycleState => getCurrentState();

  LifecycleState getCurrentState() => _minState(_expectState, _maxState);

  @override
  void bindParentLifecycle(Lifecycle? parent) {
    if (_parentLifecycle == parent) {
      return;
    }
    _parentLifecycle?.removeLifecycleObserver(_parentStateChanger,
        willEnd: currentLifecycleState);

    _parentLifecycle = parent;
    if (_parentLifecycle == null) {
      _handleMaxLifecycleStateChange(LifecycleState.resumed);
    } else {
      _parentLifecycle?.addLifecycleObserver(_parentStateChanger,
          startWith: currentLifecycleState, fullCycle: true);
    }
  }

  void _handleMaxLifecycleStateChange(LifecycleState maxState) {
    if (maxState != _maxState) {
      LifecycleState current = getCurrentState();
      _maxState = maxState;
      LifecycleState next = getCurrentState();
      if (current != next) {
        _moveToState(next);
      }
    }
  }

  @override
  void handleLifecycleEvent(LifecycleEvent event) {
    _expectState = _getStateAfter(event);
    LifecycleState next = getCurrentState();
    _moveToState(next);
  }

  void _moveToState(LifecycleState next) {
    if (_lastState == next) {
      return;
    }
    for (var observer in [..._observers.values]) {
      _moveState(provider, observer, next, _observers.containsValue);
    }
    _lastState = next;

    if (next == LifecycleState.destroyed) {
      _observers.clear();
    }
  }

  static LifecycleState _getStateAfter(LifecycleEvent event) {
    switch (event) {
      case LifecycleEvent.create:
      case LifecycleEvent.stop:
        return LifecycleState.created;
      case LifecycleEvent.start:
      case LifecycleEvent.pause:
        return LifecycleState.started;
      case LifecycleEvent.resume:
        return LifecycleState.resumed;
      case LifecycleEvent.destroy:
        return LifecycleState.destroyed;
    }
  }

  static LifecycleEvent _downEvent(LifecycleState state) {
    switch (state) {
      case LifecycleState.initialized:
      case LifecycleState.destroyed:
        throw "Unexpected state value $state";
      case LifecycleState.created:
        return LifecycleEvent.destroy;
      case LifecycleState.started:
        return LifecycleEvent.stop;
      case LifecycleState.resumed:
        return LifecycleEvent.pause;
    }
  }

  static LifecycleEvent _upEvent(LifecycleState state) {
    switch (state) {
      case LifecycleState.initialized:
      case LifecycleState.destroyed:
        return LifecycleEvent.create;
      case LifecycleState.created:
        return LifecycleEvent.start;
      case LifecycleState.started:
        return LifecycleEvent.resume;
      case LifecycleState.resumed:
        throw "Unexpected state value $state";
    }
  }

  static _LifecycleObserverDispatcher _moveState(
      LifecycleOwner owner,
      _LifecycleObserverDispatcher dispatcher,
      LifecycleState destination,
      bool Function(_LifecycleObserverDispatcher) check) {
    LifecycleState current = dispatcher._state;
    if (current == destination) return dispatcher;
    if (current.index > destination.index) {
      while (dispatcher._state.index > destination.index && check(dispatcher)) {
        LifecycleEvent event = _downEvent(dispatcher._state);
        dispatcher._state = _getStateAfter(event);
        _dispatchEvent(dispatcher, owner, event);
      }
    } else {
      while (dispatcher._state.index < destination.index && check(dispatcher)) {
        LifecycleEvent event = _upEvent(dispatcher._state);
        dispatcher._state = _getStateAfter(event);
        _dispatchEvent(dispatcher, owner, event);
      }
    }
    return dispatcher;
  }
}

void _dispatchEvent(_LifecycleObserverDispatcher dispatcher,
        LifecycleOwner owner, LifecycleEvent event) =>
    dispatcher.dispatchEvent(owner, event);

// typedef _DispatchEvent = void Function(
//     _ObserverDispatcher, LifecycleOwner, LifecycleEvent);
//
// final _DispatchEvent _dispatchEvent = () {
//   _DispatchEvent result =
//       (dispatcher, owner, event) => dispatcher.dispatchEvent(owner, event);
//   assert(() {
//     result = (dispatcher, owner, event) {
//       try {
//         dispatcher.dispatchEvent(owner, event);
//       } catch (error, stack) {
//         FlutterError.reportError(FlutterErrorDetails(
//           exception: e,
//           stack: stack,
//           library: 'anlifecycle',
//           context: ErrorDescription('dispatchEvent error'),
//         ));
//       }
//     };
//     return true;
//   }());
//   return result;
// }();

class _LifecycleObserverProxyDispatcher extends _LifecycleObserverDispatcher {
  void Function(
    Lifecycle lifecycle,
    LifecycleObserver observer,
    LifecycleState willEnd,
  ) willRemove;

  final _LifecycleObserverDispatcher _dispatcher;

  bool _willToLifecycle = true;
  final bool _destroyWithRegistry;

  _LifecycleObserverProxyDispatcher(super.observer, super.state,
      super.fullCycle, this.willRemove, this._destroyWithRegistry)
      : _dispatcher = _LifecycleObserverDispatcher(state, observer, fullCycle),
        super._();

  @override
  void dispatchEvent(LifecycleOwner owner, LifecycleEvent event) {
    if (!_willToLifecycle) {
      _dispatcher._state = _state;
      _dispatcher.dispatchEvent(owner, event);
    }
  }
}

class _LifecycleObserverStateDispatcher extends _LifecycleObserverDispatcher {
  final _LifecycleObserverEventDispatcher? _eventObserver;

  LifecycleStateChangeObserver get _stateChangeObserver =>
      _observer as LifecycleStateChangeObserver;

  _LifecycleObserverStateDispatcher(
      LifecycleStateChangeObserver super.observer, super.state, super.fullCycle)
      : _eventObserver = observer is LifecycleEventObserver
            ? _LifecycleObserverEventDispatcher(
                observer as LifecycleEventObserver, state, fullCycle)
            : null,
        super._();

  @override
  set _state(LifecycleState state) {
    super._state = state;
    _eventObserver?._state = state;
  }

  @override
  void dispatchEvent(LifecycleOwner owner, LifecycleEvent event) {
    _stateChangeObserver.onStateChange(
        owner, _LifecycleRegistryImpl._getStateAfter(event));
    _eventObserver?.dispatchEvent(owner, event);
  }
}

class _LifecycleObserverEventDispatcher extends _LifecycleObserverDispatcher {
  LifecycleEventObserver get _eventObserver =>
      _observer as LifecycleEventObserver;

  _LifecycleObserverEventDispatcher(
      LifecycleEventObserver super.observer, super.state, super.fullCycle)
      : super._();

  void _dispatchEvent(LifecycleOwner owner, LifecycleEvent event) {
    switch (event) {
      case LifecycleEvent.create:
        _eventObserver.onCreate(owner);
        break;
      case LifecycleEvent.start:
        _eventObserver.onStart(owner);
        break;
      case LifecycleEvent.resume:
        _eventObserver.onResume(owner);
        break;
      case LifecycleEvent.pause:
        _eventObserver.onPause(owner);
        break;
      case LifecycleEvent.stop:
        _eventObserver.onStop(owner);
        break;
      case LifecycleEvent.destroy:
        _eventObserver.onDestroy(owner);
        break;
    }
    _eventObserver.onAnyEvent(owner, event);
  }

  @override
  void dispatchEvent(LifecycleOwner owner, LifecycleEvent event) {
    _dispatchEvent(owner, event);
  }
}

@visibleForTesting
class LifecycleRegistryMock extends _LifecycleRegistryImpl {
  LifecycleRegistryMock(super.provider);
}

@Deprecated('use LifecycleRegistryMock')
@visibleForTesting
typedef MockLifecycleRegistry = LifecycleRegistryMock;
