import 'dart:async';

import 'lifecycle.dart';

import 'lifecycle_observer.dart';

extension LifecycleObserverAutoRegisterMixinExt
    on LifecycleObserverAutoRegisterMixin {
  Future<LifecycleEvent> nextLifecycleEvent(LifecycleEvent event) {
    var observer = LifecycleEventObserverStream();
    registerLifecycleObserver(observer, currentLifecycleState);
    return observer.eventStream
        .firstWhere((e) => e == event)
        .whenComplete(() => removeLifecycleObserver(observer, false));
  }

  Future<LifecycleEvent> nextLifecycleOnActivateEvent() =>
      nextLifecycleEvent(LifecycleEvent.activate);

  Future<LifecycleState> nextLifecycleState(LifecycleState event) {
    var observer = LifecycleStateObserverStream();
    registerLifecycleObserver(observer, currentLifecycleState);
    return observer.eventStream
        .firstWhere((e) => e == event)
        .whenComplete(() => removeLifecycleObserver(observer, false));
  }

  Future<LifecycleState> nextLifecycleResumedState() =>
      nextLifecycleState(LifecycleState.resumed);
}

class LifecycleEventObserverStream implements LifecycleEventObserver {
  late Stream<LifecycleEvent> _eventStream;
  late StreamController<LifecycleEvent> _controller;

  Stream<LifecycleEvent> get eventStream => _eventStream;

  LifecycleEventObserverStream() {
    _controller = StreamController<LifecycleEvent>();
    _eventStream = _controller.stream.asBroadcastStream();
  }

  @override
  void onAnyEvent(LifecycleOwner owner, LifecycleEvent event) {
    switch (event) {
      case LifecycleEvent.init:
      case LifecycleEvent.ready:
      case LifecycleEvent.activate:
      case LifecycleEvent.deactivate:
      case LifecycleEvent.pause:
        _controller.add(event);
        break;
      case LifecycleEvent.dispose:
        _controller.add(event);
        _controller.close();
        break;
    }
  }

  @override
  void onActivate(LifecycleOwner owner) {}

  @override
  void onDeactiviate(LifecycleOwner owner) {}

  @override
  void onDispose(LifecycleOwner owner) {}

  @override
  void onInit(LifecycleOwner owner) {}

  @override
  void onPause(LifecycleOwner owner) {}

  @override
  void onReady(LifecycleOwner owner) {}
}

class LifecycleStateObserverStream implements LifecycleStateChangeObserver {
  late Stream<LifecycleState> _eventStream;
  late StreamController<LifecycleState> _controller;

  Stream<LifecycleState> get eventStream => _eventStream;

  LifecycleEventObserverStream() {
    _controller = StreamController<LifecycleState>();
    _eventStream = _controller.stream.asBroadcastStream();
  }

  @override
  void onStateChange(LifecycleOwner owner, LifecycleState state) {
    switch (state) {
      case LifecycleState.detached:
        _controller.add(state);
        _controller.close();
        break;
      case LifecycleState.initialized:
      case LifecycleState.resumed:
      case LifecycleState.paused:
      case LifecycleState.inactive:
        _controller.add(state);
        break;
    }
  }
}
