part of 'lifecycle.dart';

LifecycleState _minState(LifecycleState state, LifecycleState state1) =>
    LifecycleState.values[min(state.index, state1.index)];

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

  late final _parentStateChanger =
      LifecycleObserver.stateChange(_handleMaxLifecycleStateChange);

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
        observer, _ObserverDispatcher(defState, observer, fullCycle));
  }

  void _addObserverDispatcher(
      LifecycleObserver observer, _ObserverDispatcher dispatcher) {
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
    _observers.values.toList().forEach((observer) {
      _moveState(provider, observer, next, _observers.containsValue);
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

  static _ObserverDispatcher _moveState(
      LifecycleOwner owner,
      _ObserverDispatcher dispatcher,
      LifecycleState destination,
      bool Function(_ObserverDispatcher) check) {
    LifecycleState current = dispatcher._state;
    if (current == destination) return dispatcher;
    if (current.index > destination.index) {
      while (dispatcher._state.index > destination.index && check(dispatcher)) {
        LifecycleEvent event = _downEvent(dispatcher._state);
        dispatcher._state = _getStateAfter(event);
        dispatcher.dispatchEvent(owner, event);
      }
    } else {
      while (dispatcher._state.index < destination.index && check(dispatcher)) {
        LifecycleEvent event = _upEvent(dispatcher._state);
        dispatcher._state = _getStateAfter(event);
        dispatcher.dispatchEvent(owner, event);
      }
    }
    return dispatcher;
  }
}

abstract class _ObserverDispatcher {
  final LifecycleObserver _observer;
  LifecycleState _state;
  bool _fullCycle;

  _ObserverDispatcher._(this._observer, this._state, this._fullCycle);

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
      _StateObserverDispatcher(observer, state, fullCycle);

  factory _ObserverDispatcher.event(LifecycleState state,
          LifecycleEventObserver observer, bool fullCycle) =>
      _EventObserverDispatcher(observer, state, fullCycle);

  factory _ObserverDispatcher.no(
          LifecycleState state,
          LifecycleObserver observer,
          bool fullCycle,
          void Function(Lifecycle lifecycle, LifecycleObserver observer,
                  LifecycleState willEnd)
              willRemove,
          bool toLifecycle) =>
      _NoObserverDispatcher(
          observer, state, fullCycle, willRemove, toLifecycle);

  void dispatchEvent(LifecycleOwner owner, LifecycleEvent event);
}

class _NoObserverDispatcher extends _ObserverDispatcher {
  void Function(
    Lifecycle lifecycle,
    LifecycleObserver observer,
    LifecycleState willEnd,
  ) willRemove;

  final _ObserverDispatcher _dispatcher;
  final bool _toLifecycle;

  _NoObserverDispatcher(super.observer, super.state, super.fullCycle,
      this.willRemove, this._toLifecycle)
      : _dispatcher = _ObserverDispatcher(state, observer, fullCycle),
        super._();

  @override
  void dispatchEvent(LifecycleOwner owner, LifecycleEvent event) {}
}

class _StateObserverDispatcher extends _ObserverDispatcher {
  final _EventObserverDispatcher? _eventObserver;

  LifecycleStateChangeObserver get _stateChangeObserver =>
      _observer as LifecycleStateChangeObserver;

  _StateObserverDispatcher(
      LifecycleStateChangeObserver super.observer, super.state, super.fullCycle)
      : _eventObserver = observer is LifecycleEventObserver
            ? _EventObserverDispatcher(
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

class _EventObserverDispatcher extends _ObserverDispatcher {
  LifecycleEventObserver get _eventObserver =>
      _observer as LifecycleEventObserver;

  _EventObserverDispatcher(
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
