part of 'lifecycle.dart';

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
