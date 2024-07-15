import 'dart:collection';
import 'dart:math';

import 'package:flutter/widgets.dart';

part 'lifecycle_callback.dart';
part 'lifecycle_dispatcher.dart';
part 'lifecycle_event.dart';
part 'lifecycle_owner.dart';
part 'lifecycle_provider.dart';
part 'lifecycle_proxy_registry.dart';
part 'lifecycle_registry.dart';
part 'lifecycle_registry_mixin.dart';

///生命周期的事件
enum LifecycleEvent { create, start, resume, pause, stop, destroy }

///生命周期的状态
enum LifecycleState { destroyed, initialized, created, started, resumed }

/// 对LifecycleState的扩展操作符
extension LifecycleStateOp on LifecycleState {
  operator >(LifecycleState state) => index > state.index;

  operator >=(LifecycleState state) => index >= state.index;

  operator <(LifecycleState state) => index < state.index;

  operator <=(LifecycleState state) => index <= state.index;

  LifecycleState nextState() => LifecycleState.values[index + 1];

  LifecycleState lastState() => LifecycleState.values[index - 1];

  LifecycleState minState(LifecycleState other) =>
      LifecycleState.values[min(index, other.index)];

  LifecycleState maxState(LifecycleState other) =>
      LifecycleState.values[max(index, other.index)];
}

LifecycleState _minState(LifecycleState state, LifecycleState state1) =>
    LifecycleState.values[min(state.index, state1.index)];

abstract class ILifecycleRegistry {
  LifecycleState get currentLifecycleState;

  void addLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? startWith, bool fullCycle = true});

  //移除Observer [fullCycle] 不为空时覆盖注册时的配置
  void removeLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? willEnd, bool? fullCycle});
}

abstract class _LifecycleRegistry implements ILifecycleRegistry {
  Lifecycle get lifecycle;
}

abstract class LifecycleOwner implements _LifecycleRegistry {
  dynamic get scope;

  @protected
  LifecycleRegistry get lifecycleRegistry;

  @override
  void addLifecycleObserver(LifecycleObserver observer,
          {LifecycleState? startWith, bool fullCycle = true}) =>
      lifecycle.addLifecycleObserver(observer,
          startWith: startWith, fullCycle: fullCycle);

  //移除Observer [fullCycle] 不为空时覆盖注册时的配置
  @override
  void removeLifecycleObserver(LifecycleObserver observer,
          {LifecycleState? willEnd, bool? fullCycle}) =>
      removeLifecycleObserver(observer, willEnd: willEnd);

  @override
  LifecycleState get currentLifecycleState => lifecycle.currentLifecycleState;
}

abstract class Lifecycle implements ILifecycleRegistry {
  Lifecycle? get parent;

  LifecycleOwner get owner;
}

extension LifecycleSupprot on Lifecycle {
  void addObserver(LifecycleObserver observer, [LifecycleState? startWith]) =>
      addLifecycleObserver(observer, startWith: startWith, fullCycle: false);

  void removeObserver(LifecycleObserver observer, [LifecycleState? endWith]) =>
      removeLifecycleObserver(observer, willEnd: endWith);

  LifecycleState get currentState => currentLifecycleState;
}

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

abstract class LifecycleEventObserver implements LifecycleObserver {
  void onCreate(LifecycleOwner owner) {}

  void onStart(LifecycleOwner owner) {}

  void onResume(LifecycleOwner owner) {}

  void onPause(LifecycleOwner owner) {}

  void onStop(LifecycleOwner owner) {}

  void onDestroy(LifecycleOwner owner) {}

  void onAnyEvent(LifecycleOwner owner, LifecycleEvent event) {}
}

abstract class LifecycleStateChangeObserver implements LifecycleObserver {
  void onStateChange(LifecycleOwner owner, LifecycleState state);
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
