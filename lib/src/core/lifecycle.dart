import 'dart:collection';
import 'dart:math';

///生命周期的事件
enum LifecycleEvent { create, start, resume, pause, stop, destroy }

///生命周期的状态
enum LifecycleState { destroyed, initialized, created, started, resumed }

extension LifecycleStateOp on LifecycleState {
  operator >(LifecycleState state) => index > state.index;

  operator >=(LifecycleState state) => index >= state.index;

  operator <(LifecycleState state) => index < state.index;

  operator <=(LifecycleState state) => index <= state.index;

  LifecycleState nextState() => LifecycleState.values[index + 1];

  LifecycleState lastState() => LifecycleState.values[index - 1];
}

LifecycleState _minState(LifecycleState state, LifecycleState state1) =>
    LifecycleState.values[min(state.index, state1.index)];

abstract class LifecycleObserver {
  factory LifecycleObserver.onStateChange(
          void Function(LifecycleOwner owner, LifecycleState state)
              onStateChange) =>
      _ProxyLifecycleStateChangeObserver(onStateChanger: onStateChange);

  factory LifecycleObserver.stateChange(
          void Function(LifecycleState state) stateChange) =>
      _ProxyLifecycleStateChangeObserver(stateChanger: stateChange);

  factory LifecycleObserver.onEventAny(
          void Function(LifecycleOwner owner, LifecycleEvent event)
              onAnyEvent) =>
      _ProxyLifecycleEventObserver(onEventAny: onAnyEvent);

  factory LifecycleObserver.eventAny(
          void Function(LifecycleEvent event) anyEvent) =>
      _ProxyLifecycleEventObserver(eventAny: anyEvent);

  factory LifecycleObserver.onEventCreate(
          void Function(LifecycleOwner owner) onEvent) =>
      _ProxyLifecycleEventObserver(onEventCreate: onEvent);

  factory LifecycleObserver.eventCreate(void Function() event) =>
      _ProxyLifecycleEventObserver(eventCreate: event);

  factory LifecycleObserver.onEventStart(
          void Function(LifecycleOwner owner) onEvent) =>
      _ProxyLifecycleEventObserver(onEventStart: onEvent);

  factory LifecycleObserver.eventStart(void Function() event) =>
      _ProxyLifecycleEventObserver(eventStart: event);

  factory LifecycleObserver.onEventResume(
          void Function(LifecycleOwner owner) onEvent) =>
      _ProxyLifecycleEventObserver(onEventResume: onEvent);

  factory LifecycleObserver.eventResume(void Function() event) =>
      _ProxyLifecycleEventObserver(eventResume: event);

  factory LifecycleObserver.onEventPause(
          void Function(LifecycleOwner owner) onEvent) =>
      _ProxyLifecycleEventObserver(onEventPause: onEvent);

  factory LifecycleObserver.eventPause(void Function() event) =>
      _ProxyLifecycleEventObserver(eventPause: event);

  factory LifecycleObserver.onEventStop(
          void Function(LifecycleOwner owner) onEvent) =>
      _ProxyLifecycleEventObserver(onEventStop: onEvent);

  factory LifecycleObserver.eventStop(void Function() event) =>
      _ProxyLifecycleEventObserver(eventStop: event);

  factory LifecycleObserver.onEventDestroy(
          void Function(LifecycleOwner owner) onEvent) =>
      _ProxyLifecycleEventObserver(onEventDestroy: onEvent);

  factory LifecycleObserver.eventDestroy(void Function() event) =>
      _ProxyLifecycleEventObserver(eventDestroy: event);
}

abstract class LifecycleOwner {
  Lifecycle get lifecycle;
}

abstract class Lifecycle {
  void addObserver(LifecycleObserver observer, [LifecycleState? startWith]);

  void removeObserver(LifecycleObserver observer, [LifecycleState? endWith]);

  LifecycleState get currentState;

  Lifecycle? get parent;
}

class LifecycleRegistry extends Lifecycle {
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

  late _LifecycleParentStateChangeObserver _maxStateChangeObserver;

  final LinkedHashMap<LifecycleObserver, _ObserverDispatcher> _observers =
      LinkedHashMap<LifecycleObserver, _ObserverDispatcher>();

  LifecycleRegistry(this.provider) {
    _maxStateChangeObserver = _LifecycleParentStateChangeObserver(
        this, (owner, state) => _handleMaxLifecycleStateChange(state));
  }

  @override
  void addObserver(LifecycleObserver observer, [LifecycleState? startWith]) {
    _addObserver(observer, startWith ?? LifecycleState.destroyed);
  }

  @override
  void removeObserver(LifecycleObserver observer, [LifecycleState? endWith]) {
    _ObserverDispatcher? dispatcher = _observers.remove(observer);
    if (dispatcher != null && endWith != null) {
      if (endWith.index < dispatcher._state.index) {
        _moveState(dispatcher, endWith);
      }
    }
  }

  void _addObserver(LifecycleObserver observer, LifecycleState? defState) {
    LifecycleState current = getCurrentState();
    if (current == LifecycleState.destroyed) return;
    if (_observers.containsKey(observer)) {
      return;
    }
    defState ??= LifecycleState.destroyed;

    defState = _minState(current, defState);
    _ObserverDispatcher dispatcher = _ObserverDispatcher(defState, observer);
    _moveState(dispatcher, getCurrentState());
    _observers[observer] = dispatcher;
  }

  void clearObserver() => _observers.clear();

  @override
  LifecycleState get currentState => getCurrentState();

  LifecycleState getCurrentState() => _minState(_expectState, _maxState);

  void bindParentLifecycle(Lifecycle? parent) {
    if (_parentLifecycle == parent) {
      return;
    }
    _maxStateChangeObserver.bindParentLifecycle = parent;
    _parentLifecycle = parent;

    if (_parentLifecycle == null) {
      _handleMaxLifecycleStateChange(LifecycleState.resumed);
    }
  }

  void _handleMaxLifecycleStateChange(LifecycleState maxState) {
    LifecycleState current = getCurrentState();
    if (maxState != current) {
      _maxState = maxState;
      LifecycleState next = getCurrentState();
      if (current != next) {
        _moveToState(next);
      }
    }
  }

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
      _moveState(observer, next);
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

  _ObserverDispatcher _moveState(
      _ObserverDispatcher dispatcher, LifecycleState destination) {
    LifecycleState current = dispatcher._state;
    if (current == destination) return dispatcher;
    if (current.index > destination.index) {
      while (dispatcher._state.index > destination.index) {
        LifecycleEvent event = _downEvent(dispatcher._state);
        dispatcher.dispatchEvent(provider, event);
        dispatcher._state = _getStateAfter(event);
      }
    } else {
      while (dispatcher._state.index < destination.index) {
        LifecycleEvent event = _upEvent(dispatcher._state);
        dispatcher._state = _getStateAfter(event);
        dispatcher.dispatchEvent(provider, event);
      }
    }
    return dispatcher;
  }
}

mixin LifecycleEventObserver implements LifecycleObserver {
  void onCreate(LifecycleOwner owner);

  void onStart(LifecycleOwner owner);

  void onResume(LifecycleOwner owner);

  void onPause(LifecycleOwner owner);

  void onStop(LifecycleOwner owner);

  void onDestroy(LifecycleOwner owner);

  void onAnyEvent(LifecycleOwner owner, LifecycleEvent event);
}

mixin LifecycleStateChangeObserver implements LifecycleObserver {
  void onStateChange(LifecycleOwner owner, LifecycleState state);
}

typedef _LifecycleStateChangeCallback = void Function(
    LifecycleOwner owner, LifecycleState state);

class _LifecycleParentStateChangeObserver with LifecycleStateChangeObserver {
  final Lifecycle childLifecycle;
  final _LifecycleStateChangeCallback callback;

  Lifecycle? _parentLifecycle;

  _LifecycleParentStateChangeObserver(this.childLifecycle, this.callback);

  set bindParentLifecycle(Lifecycle? parent) {
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

  _ObserverDispatcher._(LifecycleState state) : _state = state;

  factory _ObserverDispatcher(
      LifecycleState state, LifecycleObserver observer) {
    if (observer is LifecycleStateChangeObserver) {
      return _ObserverDispatcher.state(state, observer);
    } else if (observer is LifecycleEventObserver) {
      return _ObserverDispatcher.event(state, observer);
    }
    throw 'observer is not LifecycleStateChangeObserver or LifecycleEventObserver';
  }

  factory _ObserverDispatcher.state(
          LifecycleState state, LifecycleStateChangeObserver observer) =>
      _StateObserverDispatcher(state, observer);

  factory _ObserverDispatcher.event(
          LifecycleState state, LifecycleEventObserver observer) =>
      _EventObserverDispatcher(state, observer);

  void dispatchEvent(LifecycleOwner owner, LifecycleEvent event);
}

class _StateObserverDispatcher extends _ObserverDispatcher {
  final LifecycleStateChangeObserver _observer;
  final _EventObserverDispatcher? _eventObserver;

  _StateObserverDispatcher(
      LifecycleState state, LifecycleStateChangeObserver observer)
      : _observer = observer,
        _eventObserver = observer is LifecycleEventObserver
            ? _EventObserverDispatcher(
                state, observer as LifecycleEventObserver)
            : null,
        super._(state);

  @override
  set _state(LifecycleState state) {
    super._state = state;
    _eventObserver?._state = state;
  }

  @override
  void dispatchEvent(LifecycleOwner owner, LifecycleEvent event) {
    _observer.onStateChange(owner, LifecycleRegistry._getStateAfter(event));
    _eventObserver?.dispatchEvent(owner, event);
  }
}

class _EventObserverDispatcher extends _ObserverDispatcher {
  final LifecycleEventObserver _observer;

  _EventObserverDispatcher(
      LifecycleState state, LifecycleEventObserver observer)
      : _observer = observer,
        super._(state);

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

class _ProxyLifecycleStateChangeObserver
    implements LifecycleStateChangeObserver {
  final void Function(LifecycleOwner owner, LifecycleState state)?
      onStateChanger;
  final void Function(LifecycleState state)? stateChanger;

  _ProxyLifecycleStateChangeObserver({this.onStateChanger, this.stateChanger});

  @override
  void onStateChange(LifecycleOwner owner, LifecycleState state) {
    onStateChanger?.call(owner, state);
    stateChanger?.call(state);
  }
}

class _ProxyLifecycleEventObserver implements LifecycleEventObserver {
  final void Function(LifecycleOwner owner, LifecycleEvent event)? onEventAny;
  final void Function(LifecycleEvent event)? eventAny;

  final void Function(LifecycleOwner owner)? onEventCreate;
  final void Function()? eventCreate;

  final void Function(LifecycleOwner owner)? onEventStart;
  final void Function()? eventStart;

  final void Function(LifecycleOwner owner)? onEventPause;
  final void Function()? eventPause;

  final void Function(LifecycleOwner owner)? onEventResume;
  final void Function()? eventResume;

  final void Function(LifecycleOwner owner)? onEventStop;
  final void Function()? eventStop;

  final void Function(LifecycleOwner owner)? onEventDestroy;
  final void Function()? eventDestroy;

  _ProxyLifecycleEventObserver(
      {this.onEventAny,
      this.eventAny,
      this.onEventCreate,
      this.eventCreate,
      this.onEventStart,
      this.eventStart,
      this.onEventPause,
      this.eventPause,
      this.onEventResume,
      this.eventResume,
      this.onEventStop,
      this.eventStop,
      this.onEventDestroy,
      this.eventDestroy});

  @override
  void onAnyEvent(LifecycleOwner owner, LifecycleEvent event) {
    onEventAny?.call(owner, event);
    eventAny?.call(event);
  }

  @override
  void onCreate(LifecycleOwner owner) {
    onEventCreate?.call(owner);
    eventCreate?.call();
  }

  @override
  void onDestroy(LifecycleOwner owner) {
    onEventDestroy?.call(owner);
    eventDestroy?.call();
  }

  @override
  void onPause(LifecycleOwner owner) {
    onEventPause?.call(owner);
    eventPause?.call();
  }

  @override
  void onResume(LifecycleOwner owner) {
    onEventResume?.call(owner);
    eventResume?.call();
  }

  @override
  void onStart(LifecycleOwner owner) {
    onEventStart?.call(owner);
    eventStart?.call();
  }

  @override
  void onStop(LifecycleOwner owner) {
    onEventStop?.call(owner);
    eventStop?.call();
  }
}
