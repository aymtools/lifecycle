import 'dart:async';

import 'lifecycle.dart';
import 'lifecycle_mixin.dart';

abstract mixin class LifecycleEventDefaultObserver
    implements LifecycleEventObserver {
  @override
  void onAnyEvent(LifecycleOwner owner, LifecycleEvent event) {}

  @override
  void onCreate(LifecycleOwner owner) {}

  @override
  void onPause(LifecycleOwner owner) {}

  @override
  void onResume(LifecycleOwner owner) {}

  @override
  void onStart(LifecycleOwner owner) {}

  @override
  void onStop(LifecycleOwner owner) {}

  @override
  void onDestroy(LifecycleOwner owner) {}
}

class LifecycleEventObserverStream with LifecycleEventDefaultObserver {
  late final StreamController<LifecycleEvent> _controller =
      StreamController<LifecycleEvent>();
  late final Stream<LifecycleEvent> _eventStream =
      _controller.stream.asBroadcastStream();

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
      StreamController<LifecycleState>();

  late final Stream<LifecycleState> _stateStream =
      _controller.stream.asBroadcastStream();

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

class _LifecycleRegisterToObserver<LO extends LifecycleOwner>
    implements LifecycleStateChangeObserver {
  final LifecycleObserver _observer;
  final bool _cycleCompanionOwner;
  Lifecycle? _target;

  _LifecycleRegisterToObserver(this._observer,
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
      } while (t == null);
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

extension LifecycleObserverAutoRegisterMixinExt on LifecycleObserverRegister {
  Future<LifecycleEvent> nextLifecycleEvent(LifecycleEvent event) {
    var observer = LifecycleEventObserverStream();
    registerLifecycleObserver(observer, currentLifecycleState);
    return observer.eventStream
        .firstWhere((e) => e == event)
        .whenComplete(() => removeLifecycleObserver(observer, false));
  }

  Future<LifecycleEvent> nextLifecycleResumeEvent() =>
      nextLifecycleEvent(LifecycleEvent.resume);

  Future<LifecycleState> nextLifecycleState(LifecycleState state) {
    var observer = LifecycleStateObserverStream();
    registerLifecycleObserver(observer, currentLifecycleState);
    return observer.stateStream
        .firstWhere((e) => e == state)
        .whenComplete(() => removeLifecycleObserver(observer, false));
  }

  Future<LifecycleState> nextLifecycleResumedState() =>
      nextLifecycleState(LifecycleState.resumed);

  void registerLifecycleObserverToOwner<LO extends LifecycleOwner>(
      LifecycleObserver observer,
      [bool cycleCompanionOwner = false]) {
    var o = _LifecycleRegisterToObserver<LO>(observer, cycleCompanionOwner);
    registerLifecycleObserver(o);
  }
}
