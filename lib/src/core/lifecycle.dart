import 'dart:collection';
import 'dart:math';

import 'package:flutter/widgets.dart';

part 'lifecycle_callback.dart';
part 'lifecycle_dispatcher.dart';
part 'lifecycle_event.dart';
part 'lifecycle_owner.dart';
part 'lifecycle_provider.dart';
part 'lifecycle_proxy_observers.dart';
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

abstract class ILifecycle {
  LifecycleState get currentLifecycleState;

  void addLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? startWith, bool fullCycle = true});

  //移除Observer [fullCycle] 不为空时覆盖注册时的配置
  void removeLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? willEnd, bool? fullCycle});
}

abstract class Lifecycle implements ILifecycle {
  Lifecycle? get parent;

  LifecycleOwner get owner;

  static Lifecycle? maybeOf(BuildContext context, {bool listen = true}) {
    if (context is _LifecycleOwnerElement) {
      return context._lifecycle;
    }
    _EffectiveLifecycle? lp;
    if (listen) {
      lp = context.dependOnInheritedWidgetOfExactType<_EffectiveLifecycle>();
    } else {
      lp = context.findAncestorWidgetOfExactType<_EffectiveLifecycle>();
    }
    return lp?.lifecycle;
  }

  static Lifecycle of(BuildContext context, {bool listen = true}) {
    final lifecycle = maybeOf(context, listen: listen);
    assert(lifecycle != null);
    return lifecycle!;
  }
}

abstract class ILifecycleRegistry implements ILifecycle {
  Lifecycle get lifecycle;
}

abstract class LifecycleOwner implements ILifecycleRegistry {
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
      lifecycle.removeLifecycleObserver(observer,
          willEnd: willEnd, fullCycle: fullCycle);

  @override
  LifecycleState get currentLifecycleState => lifecycle.currentLifecycleState;
}

abstract class LifecycleRegistryState implements ILifecycleRegistry {
  /// [toLifecycle] 当状态一致时将observer转移到 [Lifecycle] 处理,不再由 [LifecycleRegistryState] 处理
  /// 默认为true 保持旧版本兼容性
  @override
  void addLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? startWith,
      bool fullCycle = true,
      bool toLifecycle = true});
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
