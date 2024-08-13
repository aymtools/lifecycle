import 'dart:collection';
import 'dart:math';

import 'package:flutter/widgets.dart';

part 'lifecycle_callback.dart';
part 'lifecycle_dispatcher.dart';
part 'lifecycle_owner.dart';
part 'lifecycle_proxy_observers.dart';
part 'lifecycle_registry_state_delegate.dart';
part 'lifecycle_registry_mixin.dart';

///生命周期的事件
enum LifecycleEvent {
  /// initState
  create,

  /// 首次didChangeDependencies 或者stop后重新回到可见状态
  start,

  /// 用户可见切可交互
  resume,

  /// 用户可见切不可交互
  pause,

  /// 用户不可见切不可交互
  stop,

  /// 销毁时间
  destroy,
}

///生命周期的状态
enum LifecycleState {
  ///已销毁
  destroyed,

  /// 尚未初始化
  initialized,

  /// 已初始化完成
  created,

  /// 用户可见但不可交互
  started,

  /// 用户可见切可交互
  resumed,
}

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

/// 对lifecycle的接口
abstract class ILifecycle {
  /// 当前状态
  LifecycleState get currentLifecycleState;

  /// 添加一个观测者
  void addLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? startWith, bool fullCycle = true});

  //移除Observer [fullCycle] 不为空时覆盖注册时的配置
  void removeLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? willEnd, bool? fullCycle});
}

/// lifecycle的实现
abstract class Lifecycle implements ILifecycle {
  /// 上一级提供者
  Lifecycle? get parent;

  /// 管理者
  LifecycleOwner get owner;

  /// 获取 lifecycle
  static Lifecycle? maybeOf(BuildContext context, {bool listen = true}) {
    if (context is _LifecycleOwnerElement) {
      return context._lifecycle;
    }
    _EffectiveLifecycle? lp;
    if (listen) {
      lp = context.dependOnInheritedWidgetOfExactType<_EffectiveLifecycle>();
    } else {
      if ((context as Element).widget.runtimeType == _EffectiveLifecycle) {
        return ((context).widget as _EffectiveLifecycle).lifecycle;
      } else {
        lp = context.findAncestorWidgetOfExactType<_EffectiveLifecycle>();
      }
    }
    return lp?.lifecycle;
  }

  /// 获取 lifecycle
  static Lifecycle of(BuildContext context, {bool listen = true}) {
    final lifecycle = maybeOf(context, listen: listen);
    assert(lifecycle != null);
    return lifecycle!;
  }
}

/// lifecycle的注册
abstract class ILifecycleRegistry implements ILifecycle {
  Lifecycle get lifecycle;
}

/// lifecycle的管理者
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

/// lifecycle的临时管理者
abstract class LifecycleRegistryState implements ILifecycleRegistry {
  /// [toLifecycle] 当状态一致时将observer转移到 [Lifecycle] 处理,不再由 [LifecycleRegistryState] 处理
  /// 默认为true 保持旧版本兼容性
  @override
  void addLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? startWith,
      bool fullCycle = true,
      bool destroyWithRegistry = true});
}

/// 观察者
abstract class LifecycleObserver {
  /// 当状态发生变化
  factory LifecycleObserver.onStateChange(
          void Function(LifecycleOwner owner, LifecycleState state)
              onStateChange) =>
      _ProxyLifecycleStateChangeObserver(onStateChanger: onStateChange);

  /// 当状态发生变化
  factory LifecycleObserver.stateChange(
          void Function(LifecycleState state) stateChange) =>
      _ProxyLifecycleStateChangeObserver(stateChanger: stateChange);

  /// 当有事件发生
  factory LifecycleObserver.onEventAny(
          void Function(LifecycleOwner owner, LifecycleEvent event)
              onAnyEvent) =>
      _ProxyLifecycleEventObserver(onEventAny: onAnyEvent);

  /// 当有事件发生
  factory LifecycleObserver.eventAny(
          void Function(LifecycleEvent event) anyEvent) =>
      _ProxyLifecycleEventObserver(eventAny: anyEvent);

  /// 当 create 的事件发生
  factory LifecycleObserver.onEventCreate(
          void Function(LifecycleOwner owner) onEvent) =>
      _ProxyLifecycleEventObserver(onEventCreate: onEvent);

  /// 当 create 的事件发生
  factory LifecycleObserver.eventCreate(void Function() event) =>
      _ProxyLifecycleEventObserver(eventCreate: event);

  /// 当 start 的事件发生
  factory LifecycleObserver.onEventStart(
          void Function(LifecycleOwner owner) onEvent) =>
      _ProxyLifecycleEventObserver(onEventStart: onEvent);

  /// 当 start 的事件发生
  factory LifecycleObserver.eventStart(void Function() event) =>
      _ProxyLifecycleEventObserver(eventStart: event);

  /// 当 resume 的事件发生
  factory LifecycleObserver.onEventResume(
          void Function(LifecycleOwner owner) onEvent) =>
      _ProxyLifecycleEventObserver(onEventResume: onEvent);

  /// 当 resume 的事件发生
  factory LifecycleObserver.eventResume(void Function() event) =>
      _ProxyLifecycleEventObserver(eventResume: event);

  /// 当 pause 的事件发生
  factory LifecycleObserver.onEventPause(
          void Function(LifecycleOwner owner) onEvent) =>
      _ProxyLifecycleEventObserver(onEventPause: onEvent);

  /// 当 pause 的事件发生
  factory LifecycleObserver.eventPause(void Function() event) =>
      _ProxyLifecycleEventObserver(eventPause: event);

  /// 当 stop 的事件发生
  factory LifecycleObserver.onEventStop(
          void Function(LifecycleOwner owner) onEvent) =>
      _ProxyLifecycleEventObserver(onEventStop: onEvent);

  /// 当 stop 的事件发生
  factory LifecycleObserver.eventStop(void Function() event) =>
      _ProxyLifecycleEventObserver(eventStop: event);

  /// 当 destroy 的事件发生
  factory LifecycleObserver.onEventDestroy(
          void Function(LifecycleOwner owner) onEvent) =>
      _ProxyLifecycleEventObserver(onEventDestroy: onEvent);

  /// 当 destroy 的事件发生
  factory LifecycleObserver.eventDestroy(void Function() event) =>
      _ProxyLifecycleEventObserver(eventDestroy: event);
}

/// 观察所有的事件
abstract class LifecycleEventObserver implements LifecycleObserver {
  void onCreate(LifecycleOwner owner) {}

  void onStart(LifecycleOwner owner) {}

  void onResume(LifecycleOwner owner) {}

  void onPause(LifecycleOwner owner) {}

  void onStop(LifecycleOwner owner) {}

  void onDestroy(LifecycleOwner owner) {}

  void onAnyEvent(LifecycleOwner owner, LifecycleEvent event) {}
}

/// 观察状态发生变化
abstract class LifecycleStateChangeObserver implements LifecycleObserver {
  void onStateChange(LifecycleOwner owner, LifecycleState state);
}
