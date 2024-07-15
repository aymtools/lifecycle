part of 'lifecycle.dart';

abstract class LifecycleRegistry implements Lifecycle {
  void bindParentLifecycle(Lifecycle? parent);

  void handleLifecycleEvent(LifecycleEvent event);

  void clearObserver();

  Set<LifecycleObserver> get observers;
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

  late final _LifecycleParentStateChangeObserver _maxStateChangeObserver =
      _LifecycleParentStateChangeObserver(
          this, (owner, state) => _handleMaxLifecycleStateChange(state));

  final LinkedHashMap<LifecycleObserver, _ObserverDispatcher> _observers =
      LinkedHashMap<LifecycleObserver, _ObserverDispatcher>();

  _LifecycleRegistryImpl(this.provider);

  @override
  void addLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? startWith, bool fullCycle = true}) {
    _addObserver(observer, startWith ?? LifecycleState.initialized, fullCycle);
  }

  @override
  void removeLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? willEnd, bool? fullCycle}) {
    _ObserverDispatcher? dispatcher = _observers.remove(observer);
    if (dispatcher != null) {
      if (willEnd == null) {
        fullCycle ??= dispatcher._fullCycle;
        if (fullCycle == true) {
          willEnd = LifecycleState.destroyed;
        } else {
          willEnd = LifecycleState.resumed;
        }
      }
      if (dispatcher is _NoObserverDispatcher) {
        dispatcher.willRemove.call(this, dispatcher.observer, willEnd);
      } else {
        if (willEnd.index < dispatcher._state.index) {
          _moveState(provider, dispatcher, willEnd);
        }
      }
    }
  }

  void _addObserver(
      LifecycleObserver observer, LifecycleState? defState, bool fullCycle) {
    defState =
        _minState(getCurrentState(), defState ?? LifecycleState.destroyed);

    _addObserverDispatcher(
        observer, _ObserverDispatcher(defState, observer, fullCycle));
  }

  void _addObserverDispatcher(
      LifecycleObserver observer, _ObserverDispatcher dispatcher) {
    LifecycleState current = getCurrentState();
    if (current == LifecycleState.destroyed) return;
    if (_observers.containsKey(observer)) {
      return;
    }
    _moveState(provider, dispatcher, current);
    _observers[observer] = dispatcher;
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
    _maxStateChangeObserver.parentLifecycle = parent;
    _parentLifecycle = parent;

    if (_parentLifecycle == null) {
      _handleMaxLifecycleStateChange(LifecycleState.resumed);
    }
  }

  void _handleMaxLifecycleStateChange(LifecycleState maxState) {
    if (maxState != maxState) {
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
    _observers.values.toList().forEach((observer) {
      _moveState(provider, observer, next);
    });
    _lastState = next;
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

  static _ObserverDispatcher _moveState(LifecycleOwner owner,
      _ObserverDispatcher dispatcher, LifecycleState destination) {
    LifecycleState current = dispatcher._state;
    if (current == destination) return dispatcher;
    if (current.index > destination.index) {
      while (dispatcher._state.index > destination.index) {
        LifecycleEvent event = _downEvent(dispatcher._state);
        dispatcher._state = _getStateAfter(event);
        dispatcher.dispatchEvent(owner, event);
      }
    } else {
      while (dispatcher._state.index < destination.index) {
        LifecycleEvent event = _upEvent(dispatcher._state);
        dispatcher._state = _getStateAfter(event);
        dispatcher.dispatchEvent(owner, event);
      }
    }
    return dispatcher;
  }
}

typedef _LifecycleStateChangeCallback = void Function(
    LifecycleOwner owner, LifecycleState state);

class _LifecycleParentStateChangeObserver
    implements LifecycleStateChangeObserver {
  final Lifecycle childLifecycle;
  final _LifecycleStateChangeCallback callback;

  Lifecycle? _parentLifecycle;

  _LifecycleParentStateChangeObserver(this.childLifecycle, this.callback);

  set parentLifecycle(Lifecycle? parent) {
    if (_parentLifecycle == parent) {
      return;
    }
    if (_parentLifecycle != null) {
      childLifecycle.removeObserver(this);
      _parentLifecycle!.removeObserver(this);
    }

    _parentLifecycle = parent;

    if (_parentLifecycle != null) {
      childLifecycle.addObserver(this);
      _parentLifecycle!.addObserver(this);
    }
  }

  @override
  void onStateChange(LifecycleOwner owner, LifecycleState state) {
    if (owner.lifecycle == _parentLifecycle) {
      callback.call(owner, state);
    }
    if (state == LifecycleState.destroyed) {
      childLifecycle.removeObserver(this);
      _parentLifecycle?.removeObserver(this);
    }
  }
}

abstract class _ObserverDispatcher {
  LifecycleState _state;
  bool _fullCycle;

  _ObserverDispatcher._(LifecycleState state, bool fullCycle)
      : _state = state,
        _fullCycle = fullCycle;

  factory _ObserverDispatcher(
      LifecycleState state, LifecycleObserver observer, bool fullCycle) {
    if (observer is LifecycleStateChangeObserver) {
      return _ObserverDispatcher.state(state, observer, fullCycle);
    } else if (observer is LifecycleEventObserver) {
      return _ObserverDispatcher.event(state, observer, fullCycle);
    }
    throw 'observer is not LifecycleStateChangeObserver or LifecycleEventObserver';
  }

  factory _ObserverDispatcher.state(LifecycleState state,
          LifecycleStateChangeObserver observer, bool fullCycle) =>
      _StateObserverDispatcher(state, observer, fullCycle);

  factory _ObserverDispatcher.event(LifecycleState state,
          LifecycleEventObserver observer, bool fullCycle) =>
      _EventObserverDispatcher(state, observer, fullCycle);

  factory _ObserverDispatcher.no(
          LifecycleState state,
          LifecycleObserver observer,
          bool fullCycle,
          void Function(Lifecycle lifecycle, LifecycleObserver observer,
                  LifecycleState willEnd)
              willRemove,
          bool toLifecycle) =>
      _NoObserverDispatcher(
          state, observer, fullCycle, willRemove, toLifecycle);

  void dispatchEvent(LifecycleOwner owner, LifecycleEvent event);
}

class _NoObserverDispatcher extends _ObserverDispatcher {
  final LifecycleObserver observer;
  final void Function(
    Lifecycle lifecycle,
    LifecycleObserver observer,
    LifecycleState willEnd,
  ) willRemove;

  final _ObserverDispatcher _dispatcher;
  final bool _toLifecycle;

  _NoObserverDispatcher(super.state, this.observer, super.fullCycle,
      this.willRemove, this._toLifecycle)
      : _dispatcher = _ObserverDispatcher(state, observer, fullCycle),
        super._();

  @override
  void dispatchEvent(LifecycleOwner owner, LifecycleEvent event) {}
}

class _StateObserverDispatcher extends _ObserverDispatcher {
  final LifecycleStateChangeObserver _observer;
  final _EventObserverDispatcher? _eventObserver;

  _StateObserverDispatcher(
      super.state, LifecycleStateChangeObserver observer, super.fullCycle)
      : _observer = observer,
        _eventObserver = observer is LifecycleEventObserver
            ? _EventObserverDispatcher(
                state, observer as LifecycleEventObserver, fullCycle)
            : null,
        super._();

  @override
  set _state(LifecycleState state) {
    super._state = state;
    _eventObserver?._state = state;
  }

  @override
  void dispatchEvent(LifecycleOwner owner, LifecycleEvent event) {
    _observer.onStateChange(
        owner, _LifecycleRegistryImpl._getStateAfter(event));
    _eventObserver?.dispatchEvent(owner, event);
  }
}

class _EventObserverDispatcher extends _ObserverDispatcher {
  final LifecycleEventObserver _observer;

  _EventObserverDispatcher(
      super.state, LifecycleEventObserver observer, super.fullCycle)
      : _observer = observer,
        super._();

  void _dispatchEvent(LifecycleOwner owner, LifecycleEvent event) {
    switch (event) {
      case LifecycleEvent.create:
        _observer.onCreate(owner);
        break;
      case LifecycleEvent.start:
        _observer.onStart(owner);
        break;
      case LifecycleEvent.resume:
        _observer.onResume(owner);
        break;
      case LifecycleEvent.pause:
        _observer.onPause(owner);
        break;
      case LifecycleEvent.stop:
        _observer.onStop(owner);
        break;
      case LifecycleEvent.destroy:
        _observer.onDestroy(owner);
        break;
    }
    _observer.onAnyEvent(owner, event);
  }

  @override
  void dispatchEvent(LifecycleOwner owner, LifecycleEvent event) {
    _dispatchEvent(owner, event);
  }
}
