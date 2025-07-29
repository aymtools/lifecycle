import 'package:anlifecycle/anlifecycle.dart';

class TestLifecycleEventObserver with LifecycleEventObserver {
  LifecycleEvent? lastEvent;

  final List<LifecycleEvent> eventHistory = [];

  int onEventCallCount = 0;

  @override
  void onCreate(LifecycleOwner owner) {
    super.onCreate(owner);
    lastEvent = LifecycleEvent.create;
    eventHistory.add(LifecycleEvent.create);
    onEventCallCount++;
  }

  @override
  void onStart(LifecycleOwner owner) {
    super.onStart(owner);
    lastEvent = LifecycleEvent.start;
    eventHistory.add(LifecycleEvent.start);
    onEventCallCount++;
  }

  @override
  void onResume(LifecycleOwner owner) {
    super.onResume(owner);
    lastEvent = LifecycleEvent.resume;
    eventHistory.add(LifecycleEvent.resume);
    onEventCallCount++;
  }

  @override
  void onPause(LifecycleOwner owner) {
    super.onPause(owner);
    lastEvent = LifecycleEvent.pause;
    eventHistory.add(LifecycleEvent.pause);
    onEventCallCount++;
  }

  @override
  void onStop(LifecycleOwner owner) {
    super.onStop(owner);
    lastEvent = LifecycleEvent.stop;
    eventHistory.add(LifecycleEvent.stop);
    onEventCallCount++;
  }

  @override
  void onDestroy(LifecycleOwner owner) {
    super.onDestroy(owner);
    lastEvent = LifecycleEvent.destroy;
    eventHistory.add(LifecycleEvent.destroy);
    onEventCallCount++;
  }

  void reset() {
    lastEvent = null;
    eventHistory.clear();
    onEventCallCount = 0;
  }
}

class TestLifecycleStateChangeObserver with LifecycleStateChangeObserver {
  LifecycleState? lastState;
  final List<LifecycleState> stateHistory = [];
  int onStateChangeCallCount = 0;

  @override
  void onStateChange(LifecycleOwner owner, LifecycleState state) {
    lastState = state;
    stateHistory.add(state);
    onStateChangeCallCount++;
  }

  void reset() {
    lastState = null;
    stateHistory.clear();
    onStateChangeCallCount = 0;
  }
}

class TestLifecycleCollectEventObserver with LifecycleEventObserver {
  final List<LifecycleEvent> eventHistory = [];

  @override
  void onAnyEvent(LifecycleOwner owner, LifecycleEvent event) {
    super.onAnyEvent(owner, event);
    eventHistory.add(event);
  }

  void reset() {
    eventHistory.clear();
  }
}

class TestLifecycleCollectStateObserver with LifecycleStateChangeObserver {
  final List<LifecycleState> stateHistory = [];

  @override
  void onStateChange(LifecycleOwner owner, LifecycleState state) {
    stateHistory.add(state);
  }

  void reset() {
    stateHistory.clear();
  }
}
