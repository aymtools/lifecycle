import 'dart:async';

import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/widgets.dart';

typedef LifecycleObserverRegister = LifecycleObserverRegistry;
typedef LifecycleObserverRegisterMixin<W extends StatefulWidget>
    = LifecycleObserverRegistryMixin<W>;

extension LifecycleObserverRegisterSupport on LifecycleObserverRegistry {
  void registerLifecycleObserver(LifecycleObserver observer,
          {LifecycleState? startWith, bool fullCycle = true}) =>
      addLifecycleObserver(observer,
          startWith: startWith, fullCycle: fullCycle);

  void registerLifecycleObserverToOwner<LO extends LifecycleOwner>(
          LifecycleObserver observer,
          [bool cycleCompanionOwner = false]) =>
      addLifecycleObserverToOwner(observer, cycleCompanionOwner);
}

class LifecycleEventObserverStream with LifecycleEventObserver {
  late final StreamController<LifecycleEvent> _controller =
      StreamController<LifecycleEvent>.broadcast(sync: true);

  late final Stream<LifecycleEvent> _eventStream = _controller.stream;

  Stream<LifecycleEvent> get eventStream => _eventStream;

  @override
  void onAnyEvent(LifecycleOwner owner, LifecycleEvent event) {
    switch (event) {
      case LifecycleEvent.create:
      case LifecycleEvent.start:
      case LifecycleEvent.resume:
      case LifecycleEvent.pause:
      case LifecycleEvent.stop:
        _controller.add(event);
        break;
      case LifecycleEvent.destroy:
        _controller.add(event);
        _controller.close();
        break;
    }
  }
}

class LifecycleStateObserverStream implements LifecycleStateChangeObserver {
  final StreamController<LifecycleState> _controller =
      StreamController<LifecycleState>.broadcast(sync: true);

  late final Stream<LifecycleState> _stateStream = _controller.stream;

  Stream<LifecycleState> get stateStream => _stateStream;

  @override
  void onStateChange(LifecycleOwner owner, LifecycleState state) {
    switch (state) {
      case LifecycleState.destroyed:
        _controller.add(state);
        _controller.close();
        break;
      case LifecycleState.initialized:
      case LifecycleState.resumed:
      case LifecycleState.started:
      case LifecycleState.created:
        _controller.add(state);
        break;
    }
  }
}

class _LifecycleObserverAddToOwner<LO extends LifecycleOwner>
    implements LifecycleStateChangeObserver {
  final LifecycleObserver _observer;
  final bool _cycleCompanionOwner;
  Lifecycle? _target;

  _LifecycleObserverAddToOwner(this._observer,
      [this._cycleCompanionOwner = false]);

  @override
  void onStateChange(LifecycleOwner owner, LifecycleState state) {
    if (state == LifecycleState.destroyed) {
      if (_target != null && !_cycleCompanionOwner) {
        _target?.removeObserver(_observer);
        return;
      }
    }
    if (_target != null) {
      Lifecycle? t = owner.lifecycle;
      do {
        if (_target == t) {
          return; //在路径上
        }
        t = t?.parent;
      } while (t != null);
    }
    LifecycleOwner? find = owner._findOwner<LO>();
    var start = _target?.currentState ?? LifecycleState.destroyed;
    _target?.removeObserver(_observer);
    if (find == null) {
      // 找不到目标
    } else if (find.lifecycle.currentState > LifecycleState.destroyed) {
      // 找到目标且未销毁时进行注册
      _target = find.lifecycle;
      find.lifecycle.addObserver(_observer, start);
    }
  }
}

extension _LifecycleOwnerFinder on LifecycleOwner {
  LifecycleOwner? _findOwner<LO extends LifecycleOwner>() {
    LifecycleOwner? find = this;
    while (find != null && find is! LO) {
      var parent = find.lifecycle.parent;
      while (parent != null && parent is! LifecycleRegistry) {
        parent = parent.parent;
      }
      if (parent != null) {
        find = (parent as LifecycleRegistry).provider;
      } else {
        find = null;
        break;
      }
    }
    return find;
  }
}

extension LifecycleObserverRegistryMixinExt on LifecycleObserverRegistry {
  Future<LifecycleEvent> nextLifecycleEvent(LifecycleEvent event) {
    var observer = LifecycleEventObserverStream();
    addLifecycleObserver(observer, startWith: currentLifecycleState);
    final result = observer.eventStream
        .firstWhereSync((e) => e == event, ignoreNoElement: true);
    result.whenComplete(
        () => removeLifecycleObserver(observer, fullCycle: false));
    return result;
  }

  Future<LifecycleEvent> nextLifecycleResumeEvent() =>
      nextLifecycleEvent(LifecycleEvent.resume);

  Future<LifecycleState> nextLifecycleState(LifecycleState state) {
    var observer = LifecycleStateObserverStream();
    addLifecycleObserver(observer, startWith: currentLifecycleState);
    final result = observer.stateStream
        .firstWhereSync((e) => e == state, ignoreNoElement: true);
    result.whenComplete(
        () => removeLifecycleObserver(observer, fullCycle: false));
    return result;
  }

  Future<LifecycleState> nextLifecycleResumedState() =>
      nextLifecycleState(LifecycleState.resumed);

  void addLifecycleObserverToOwner<LO extends LifecycleOwner>(
      LifecycleObserver observer,
      [bool cycleCompanionOwner = false]) {
    var o = _LifecycleObserverAddToOwner<LO>(observer, cycleCompanionOwner);
    addLifecycleObserver(o);
  }
}

extension<T> on Stream<T> {
  Future<T> firstWhereSync(bool Function(T element) test,
      {bool ignoreNoElement = true, T Function()? orElse}) {
    Completer<T> completer = Completer.sync();

    StreamSubscription<T> subscription =
        listen(null, onError: completer.completeError, onDone: () {
      if (orElse != null) {
        _runUserCode(orElse, completer.complete, completer.completeError);
        return;
      }
      if (!ignoreNoElement) {
        completer.completeError(StateError("No element"));
      }
    }, cancelOnError: true);

    subscription.onData((T value) {
      _runUserCode(() => test(value), (bool isMatch) {
        if (isMatch) {
          completer.complete(value);
          subscription.cancel();
        }
      }, (err, st) {
        completer.completeError(err, st);
        subscription.cancel();
      });
    });
    return completer.future;
  }
}

_runUserCode<T>(T Function() userCode, Function(T value) onSuccess,
    Function(Object error, StackTrace stackTrace) onError) {
  try {
    onSuccess(userCode());
  } catch (e, s) {
    AsyncError? replacement = Zone.current.errorCallback(e, s);
    if (replacement == null) {
      onError(e, s);
    } else {
      var error = replacement.error;
      var stackTrace = replacement.stackTrace;
      onError(error, stackTrace);
    }
  }
}
