import 'package:anlifecycle/anlifecycle.dart';
import 'package:test/test.dart';

import 'tools.dart';

void main() {
  late LifecycleRegistry appRegistry;
  late LifecycleRegistry lifecycleRegistry;

  late Lifecycle lifecycle;

  setUp(() {
    LifecycleOwnerMock app = LifecycleOwnerMock('app_scope');
    appRegistry = app.lifecycleRegistry;
    appRegistry.handleLifecycleEvent(LifecycleEvent.start);
    appRegistry.handleLifecycleEvent(LifecycleEvent.resume);

    LifecycleOwnerMock owner = LifecycleOwnerMock('test_scope');
    owner.lifecycleRegistry.bindParentLifecycle(app.lifecycle);

    lifecycleRegistry = owner.lifecycleRegistry;
    lifecycle = owner.lifecycle;
  });

  group('lifecycle handle LifecycleEvent', () {
    test('handle LifecycleEvent state change', () {
      expect(lifecycleRegistry.currentState, LifecycleState.initialized);
      expect(lifecycle.currentState, LifecycleState.initialized);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.create);
      expect(lifecycleRegistry.currentState, LifecycleState.created);
      expect(lifecycle.currentState, LifecycleState.created);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      expect(lifecycleRegistry.currentState, LifecycleState.started);
      expect(lifecycle.currentState, LifecycleState.started);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(lifecycleRegistry.currentState, LifecycleState.resumed);
      expect(lifecycle.currentState, LifecycleState.resumed);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
      expect(lifecycleRegistry.currentState, LifecycleState.started);
      expect(lifecycle.currentState, LifecycleState.started);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
      expect(lifecycleRegistry.currentState, LifecycleState.created);
      expect(lifecycle.currentState, LifecycleState.created);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(lifecycleRegistry.currentState, LifecycleState.destroyed);
      expect(lifecycle.currentState, LifecycleState.destroyed);
    });

    test('parent handle LifecycleEvent state change', () {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(lifecycle.currentState, LifecycleState.resumed);

      appRegistry.handleLifecycleEvent(LifecycleEvent.pause);
      expect(lifecycle.currentState, LifecycleState.started);

      appRegistry.handleLifecycleEvent(LifecycleEvent.stop);
      expect(lifecycle.currentState, LifecycleState.created);

      appRegistry.handleLifecycleEvent(LifecycleEvent.start);
      expect(lifecycle.currentState, LifecycleState.started);

      appRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(lifecycle.currentState, LifecycleState.resumed);

      appRegistry.handleLifecycleEvent(LifecycleEvent.stop);
      expect(lifecycle.currentState, LifecycleState.created);

      appRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(lifecycle.currentState, LifecycleState.resumed);
    });
  });

  group('lifecycle observer', () {
    test('Event observer', () {
      final observer = TestLifecycleEventObserver();
      final collectedEventObserver = TestLifecycleCollectEventObserver();
      expect(observer.lastEvent, isNull);
      expect(observer.eventHistory, isEmpty);
      expect(observer.onEventCallCount, 0);

      lifecycle.addLifecycleObserver(observer);
      lifecycle.addLifecycleObserver(collectedEventObserver);
      expect(observer.lastEvent, isNull);
      expect(observer.eventHistory, isEmpty);
      expect(observer.onEventCallCount, 0);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.create);
      expect(observer.lastEvent, LifecycleEvent.create);
      expect(observer.eventHistory, [LifecycleEvent.create]);
      expect(observer.onEventCallCount, 1);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      expect(observer.lastEvent, LifecycleEvent.start);
      expect(
          observer.eventHistory, [LifecycleEvent.create, LifecycleEvent.start]);
      expect(observer.onEventCallCount, 2);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(observer.lastEvent, LifecycleEvent.resume);
      expect(observer.eventHistory,
          [LifecycleEvent.create, LifecycleEvent.start, LifecycleEvent.resume]);
      expect(observer.onEventCallCount, 3);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
      expect(observer.lastEvent, LifecycleEvent.pause);
      expect(observer.eventHistory, [
        LifecycleEvent.create,
        LifecycleEvent.start,
        LifecycleEvent.resume,
        LifecycleEvent.pause
      ]);
      expect(observer.onEventCallCount, 4);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
      expect(observer.lastEvent, LifecycleEvent.stop);
      expect(observer.eventHistory, [
        LifecycleEvent.create,
        LifecycleEvent.start,
        LifecycleEvent.resume,
        LifecycleEvent.pause,
        LifecycleEvent.stop
      ]);
      expect(observer.onEventCallCount, 5);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(observer.lastEvent, LifecycleEvent.resume);
      expect(observer.eventHistory, [
        LifecycleEvent.create,
        LifecycleEvent.start,
        LifecycleEvent.resume,
        LifecycleEvent.pause,
        LifecycleEvent.stop,
        LifecycleEvent.start,
        LifecycleEvent.resume
      ]);
      expect(observer.onEventCallCount, 7);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      expect(observer.lastEvent, LifecycleEvent.pause);
      expect(observer.eventHistory, [
        LifecycleEvent.create,
        LifecycleEvent.start,
        LifecycleEvent.resume,
        LifecycleEvent.pause,
        LifecycleEvent.stop,
        LifecycleEvent.start,
        LifecycleEvent.resume,
        LifecycleEvent.pause
      ]);
      expect(observer.onEventCallCount, 8);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(observer.lastEvent, LifecycleEvent.destroy);
      expect(observer.eventHistory, [
        LifecycleEvent.create,
        LifecycleEvent.start,
        LifecycleEvent.resume,
        LifecycleEvent.pause,
        LifecycleEvent.stop,
        LifecycleEvent.start,
        LifecycleEvent.resume,
        LifecycleEvent.pause,
        LifecycleEvent.stop,
        LifecycleEvent.destroy
      ]);
      expect(observer.onEventCallCount, 10);

      expect(collectedEventObserver.eventHistory, observer.eventHistory);
    });

    test('State observer', () {
      final observer = TestLifecycleStateChangeObserver();
      final collectedStateObserver = TestLifecycleCollectStateObserver();
      expect(observer.lastState, isNull);
      expect(observer.stateHistory, isEmpty);
      expect(observer.onStateChangeCallCount, 0);

      lifecycle.addLifecycleObserver(observer);
      lifecycle.addLifecycleObserver(collectedStateObserver);
      expect(observer.lastState, isNull);
      expect(observer.stateHistory, isEmpty);
      expect(observer.onStateChangeCallCount, 0);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.create);
      expect(observer.lastState, LifecycleState.created);
      expect(observer.stateHistory, [LifecycleState.created]);
      expect(observer.onStateChangeCallCount, 1);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      expect(observer.lastState, LifecycleState.started);
      expect(observer.stateHistory,
          [LifecycleState.created, LifecycleState.started]);
      expect(observer.onStateChangeCallCount, 2);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(observer.lastState, LifecycleState.resumed);
      expect(observer.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);
      expect(observer.onStateChangeCallCount, 3);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
      expect(observer.lastState, LifecycleState.started);
      expect(observer.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started
      ]);
      expect(observer.onStateChangeCallCount, 4);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
      expect(observer.lastState, LifecycleState.created);
      expect(observer.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started,
        LifecycleState.created
      ]);
      expect(observer.onStateChangeCallCount, 5);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(observer.lastState, LifecycleState.resumed);
      expect(observer.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started,
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed,
      ]);
      expect(observer.onStateChangeCallCount, 7);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      expect(observer.lastState, LifecycleState.started);
      expect(observer.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started,
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started,
      ]);
      expect(observer.onStateChangeCallCount, 8);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(observer.lastState, LifecycleState.destroyed);
      expect(observer.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started,
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started,
        LifecycleState.created,
        LifecycleState.destroyed
      ]);
      expect(observer.onStateChangeCallCount, 10);

      expect(collectedStateObserver.stateHistory, observer.stateHistory);
    });

    test('state observer', () {
      final states = <LifecycleState>[];
      expect(states, isEmpty);

      lifecycle.addLifecycleObserver(
          LifecycleObserver.stateChange((state) => states.add(state)));
      expect(states, isEmpty);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.create);
      expect(states, [LifecycleState.created]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      expect(states, [LifecycleState.created, LifecycleState.started]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(states, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
      expect(states, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started
      ]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
      expect(states, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started,
        LifecycleState.created
      ]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(states, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started,
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      expect(states, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started,
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started
      ]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);

      expect(states, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started,
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started,
        LifecycleState.created,
        LifecycleState.destroyed,
      ]);
    });

    test('Add after change state observer', () {
      final states = <LifecycleState>[];
      expect(states, isEmpty);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.create);
      expect(states, isEmpty);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      expect(states, isEmpty);

      lifecycle.addLifecycleObserver(LifecycleObserver.stateChange(states.add));
      expect(states, [LifecycleState.created, LifecycleState.started]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(states, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
      expect(states, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started
      ]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(states, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started,
        LifecycleState.created,
        LifecycleState.destroyed
      ]);
    });

    test('state observer not full', () {
      final states = <LifecycleState>[];
      expect(states, isEmpty);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.create);
      expect(states, isEmpty);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      expect(states, isEmpty);

      final stateObserver = LifecycleObserver.stateChange(states.add);

      lifecycle.addLifecycleObserver(stateObserver,
          startWith: lifecycle.currentLifecycleState);
      expect(states, isEmpty);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(states, [LifecycleState.resumed]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
      expect(states, [LifecycleState.resumed, LifecycleState.started]);

      lifecycle.removeLifecycleObserver(stateObserver);
      expect(states, [
        LifecycleState.resumed,
        LifecycleState.started,
        LifecycleState.created,
        LifecycleState.destroyed
      ]);

      expect(lifecycle.currentLifecycleState, LifecycleState.started);

      states.clear();
      expect(states, isEmpty);

      lifecycle.addLifecycleObserver(stateObserver,
          startWith: LifecycleState.created, fullCycle: false);
      expect(states, [LifecycleState.started]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(states, [LifecycleState.started, LifecycleState.resumed]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
      expect(states, [
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started
      ]);

      lifecycle.removeLifecycleObserver(stateObserver);
      expect(states, [
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started
      ]);

      expect(lifecycle.currentLifecycleState, LifecycleState.started);

      states.clear();
      expect(states, isEmpty);

      lifecycle.addLifecycleObserver(stateObserver, fullCycle: true);
      expect(states, [LifecycleState.created, LifecycleState.started]);
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(states, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
      expect(states, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started
      ]);

      lifecycle.removeLifecycleObserver(stateObserver, fullCycle: false);
      expect(states, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started
      ]);

      expect(lifecycle.currentLifecycleState, LifecycleState.started);

      states.clear();
      expect(states, isEmpty);

      lifecycle.addLifecycleObserver(stateObserver,
          startWith: LifecycleState.created, fullCycle: true);
      expect(states, [LifecycleState.started]);
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(states, [LifecycleState.started, LifecycleState.resumed]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
      expect(states, [
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started
      ]);

      lifecycle.removeLifecycleObserver(stateObserver,
          willEnd: LifecycleState.created);
      expect(states, [
        LifecycleState.started,
        LifecycleState.resumed,
        LifecycleState.started,
        LifecycleState.created
      ]);

      expect(lifecycle.currentLifecycleState, LifecycleState.started);

      states.clear();
      expect(states, isEmpty);

      lifecycle.addLifecycleObserver(stateObserver,
          startWith: LifecycleState.resumed, fullCycle: true);
      expect(states, isEmpty);
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(states, [LifecycleState.resumed]);
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
      expect(states, [LifecycleState.resumed, LifecycleState.started]);

      lifecycle.removeLifecycleObserver(stateObserver,
          willEnd: LifecycleState.resumed);
      expect(states, [LifecycleState.resumed, LifecycleState.started]);

      expect(lifecycle.currentLifecycleState, LifecycleState.started);

      states.clear();
      expect(states, isEmpty);
    });

    test('event observer', () {
      final events = <LifecycleEvent>[];
      expect(events, isEmpty);

      lifecycle.addLifecycleObserver(
          LifecycleObserver.eventAny((event) => events.add(event)));
      expect(events, isEmpty);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.create);
      expect(events, [LifecycleEvent.create]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      expect(events, [LifecycleEvent.create, LifecycleEvent.start]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(events,
          [LifecycleEvent.create, LifecycleEvent.start, LifecycleEvent.resume]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
      expect(events, [
        LifecycleEvent.create,
        LifecycleEvent.start,
        LifecycleEvent.resume,
        LifecycleEvent.pause
      ]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
      expect(events, [
        LifecycleEvent.create,
        LifecycleEvent.start,
        LifecycleEvent.resume,
        LifecycleEvent.pause,
        LifecycleEvent.stop
      ]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(events, [
        LifecycleEvent.create,
        LifecycleEvent.start,
        LifecycleEvent.resume,
        LifecycleEvent.pause,
        LifecycleEvent.stop,
        LifecycleEvent.start,
        LifecycleEvent.resume
      ]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      expect(events, [
        LifecycleEvent.create,
        LifecycleEvent.start,
        LifecycleEvent.resume,
        LifecycleEvent.pause,
        LifecycleEvent.stop,
        LifecycleEvent.start,
        LifecycleEvent.resume,
        LifecycleEvent.pause
      ]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.create);
      expect(events, [
        LifecycleEvent.create,
        LifecycleEvent.start,
        LifecycleEvent.resume,
        LifecycleEvent.pause,
        LifecycleEvent.stop,
        LifecycleEvent.start,
        LifecycleEvent.resume,
        LifecycleEvent.pause,
        LifecycleEvent.stop
      ]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(events, [
        LifecycleEvent.create,
        LifecycleEvent.start,
        LifecycleEvent.resume,
        LifecycleEvent.pause,
        LifecycleEvent.stop,
        LifecycleEvent.start,
        LifecycleEvent.resume,
        LifecycleEvent.pause,
        LifecycleEvent.stop,
        LifecycleEvent.destroy
      ]);
    });

    test('Add after change event observer', () {
      final events = <LifecycleEvent>[];
      expect(events, isEmpty);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.create);
      expect(events, isEmpty);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      expect(events, isEmpty);

      lifecycle.addLifecycleObserver(LifecycleObserver.eventAny(events.add));
      expect(events, [LifecycleEvent.create, LifecycleEvent.start]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(events,
          [LifecycleEvent.create, LifecycleEvent.start, LifecycleEvent.resume]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
      expect(events, [
        LifecycleEvent.create,
        LifecycleEvent.start,
        LifecycleEvent.resume,
        LifecycleEvent.pause
      ]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(events, [
        LifecycleEvent.create,
        LifecycleEvent.start,
        LifecycleEvent.resume,
        LifecycleEvent.pause,
        LifecycleEvent.stop,
        LifecycleEvent.destroy
      ]);
    });

    test('event observer not full', () {
      final events = <LifecycleEvent>[];
      expect(events, isEmpty);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.create);
      expect(events, isEmpty);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      expect(events, isEmpty);

      final eventObserver = LifecycleObserver.eventAny(events.add);

      lifecycle.addLifecycleObserver(eventObserver,
          startWith: lifecycle.currentLifecycleState);
      expect(events, isEmpty);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(events, [LifecycleEvent.resume]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
      expect(events, [LifecycleEvent.resume, LifecycleEvent.pause]);

      lifecycle.removeLifecycleObserver(eventObserver);
      expect(events, [
        LifecycleEvent.resume,
        LifecycleEvent.pause,
        LifecycleEvent.stop,
        LifecycleEvent.destroy
      ]);

      expect(lifecycle.currentLifecycleState, LifecycleState.started);

      events.clear();
      expect(events, isEmpty);

      lifecycle.addLifecycleObserver(eventObserver,
          startWith: LifecycleState.created, fullCycle: false);
      expect(events, [LifecycleEvent.start]);
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(events, [LifecycleEvent.start, LifecycleEvent.resume]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
      expect(events,
          [LifecycleEvent.start, LifecycleEvent.resume, LifecycleEvent.pause]);

      lifecycle.removeLifecycleObserver(eventObserver);
      expect(events,
          [LifecycleEvent.start, LifecycleEvent.resume, LifecycleEvent.pause]);

      expect(lifecycle.currentLifecycleState, LifecycleState.started);

      events.clear();
      expect(events, isEmpty);

      lifecycle.addLifecycleObserver(eventObserver, fullCycle: true);
      expect(events, [LifecycleEvent.create, LifecycleEvent.start]);

      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(events,
          [LifecycleEvent.create, LifecycleEvent.start, LifecycleEvent.resume]);
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
      expect(events, [
        LifecycleEvent.create,
        LifecycleEvent.start,
        LifecycleEvent.resume,
        LifecycleEvent.pause
      ]);

      lifecycle.removeLifecycleObserver(eventObserver);
      expect(events, [
        LifecycleEvent.create,
        LifecycleEvent.start,
        LifecycleEvent.resume,
        LifecycleEvent.pause,
        LifecycleEvent.stop,
        LifecycleEvent.destroy
      ]);

      expect(lifecycle.currentLifecycleState, LifecycleState.started);

      events.clear();
      expect(events, isEmpty);

      lifecycle.addLifecycleObserver(eventObserver,
          startWith: LifecycleState.created, fullCycle: true);
      expect(events, [LifecycleEvent.start]);
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(events, [LifecycleEvent.start, LifecycleEvent.resume]);
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
      expect(events,
          [LifecycleEvent.start, LifecycleEvent.resume, LifecycleEvent.pause]);
      lifecycle.removeLifecycleObserver(eventObserver,
          willEnd: LifecycleState.created);
      expect(events, [
        LifecycleEvent.start,
        LifecycleEvent.resume,
        LifecycleEvent.pause,
        LifecycleEvent.stop,
      ]);

      expect(lifecycle.currentLifecycleState, LifecycleState.started);
      events.clear();
      expect(events, isEmpty);

      lifecycle.addLifecycleObserver(eventObserver,
          startWith: LifecycleState.resumed, fullCycle: true);
      expect(events, isEmpty);
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(events, [LifecycleEvent.resume]);
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
      expect(events, [LifecycleEvent.resume, LifecycleEvent.pause]);
      lifecycle.removeLifecycleObserver(eventObserver,
          willEnd: LifecycleState.resumed);
      expect(events, [LifecycleEvent.resume, LifecycleEvent.pause]);

      expect(lifecycle.currentLifecycleState, LifecycleState.started);
      events.clear();
      expect(events, isEmpty);
    });
  });
}
