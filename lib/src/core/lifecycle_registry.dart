import 'package:flutter/widgets.dart';

import 'lifecycle.dart';

part 'lifecycle_callback.dart';

part 'lifecycle_provider.dart';

part 'lifecycle_registry_mixin.dart';

class _ObserverS {
  final LifecycleState startWith;
  final bool fullCycle;

  Lifecycle? lifecycle;

  _ObserverS(
      [this.startWith = LifecycleState.destroyed, this.fullCycle = false]);
}

abstract class LifecycleObserverRegistry {
  Lifecycle get lifecycle;

  LifecycleState get currentLifecycleState;

  void addLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? startWith, bool fullCycle = true});

  //移除Observer [fullCycle] 不为空时覆盖注册时的配置
  void removeLifecycleObserver(LifecycleObserver observer, {bool? fullCycle});

  LO? findLifecycleObserver<LO extends LifecycleObserver>();
}

class _LifecycleObserverRegistryDelegate implements LifecycleObserverRegistry {
  final LifecycleObserverRegistry _target;

  Lifecycle? _lifecycle;
  final Map<LifecycleObserver, _ObserverS> _observers = {};

  LifecycleState _currState = LifecycleState.initialized;

  _LifecycleObserverRegistryDelegate(
      {required LifecycleObserverRegistry target})
      : _target = target;

  @override
  Lifecycle get lifecycle => _lifecycle!;

  @override
  LifecycleState get currentLifecycleState =>
      _lifecycle?.currentState ?? _currState;

  set lifecycle(Lifecycle? lifecycle) {
    if (lifecycle != _lifecycle) {
      LifecycleState? currState;
      if (_lifecycle != null) {
        currState = _lifecycle!.currentState;
        final entries = [..._observers.entries];
        for (var obs in entries) {
          _lifecycle!.removeObserver(obs.key);
          obs.value.lifecycle = null;
        }
      }
      _lifecycle = lifecycle;
      if (_lifecycle != null) {
        final entries = [..._observers.entries];
        for (var obs in entries) {
          obs.value.lifecycle = _lifecycle;
          _lifecycle!.addObserver(obs.key, currState ?? obs.value.startWith);
        }
      }
    }
  }

  @override
  void addLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? startWith, bool fullCycle = true}) {
    if (_observers.containsKey(observer)) return;
    var os = _ObserverS(startWith ?? LifecycleState.destroyed, fullCycle);
    _observers[observer] = os;
    var lifecycle = _lifecycle;

    if (lifecycle != null) {
      os.lifecycle = lifecycle;
      lifecycle.addObserver(observer, os.startWith);
    }
  }

  @override
  void removeLifecycleObserver(LifecycleObserver observer, {bool? fullCycle}) {
    if (!_observers.containsKey(observer)) return;
    _ObserverS? os = _observers.remove(observer);
    if (os != null) {
      os.lifecycle?.removeObserver(
          observer,
          fullCycle == true || (fullCycle == null && os.fullCycle)
              ? LifecycleState.destroyed
              : null);
    }
    os?.lifecycle = null;
  }

  void initState() {}

  void didChangeDependencies() {}

  void dispose() {
    _currState = LifecycleState.destroyed;

    final entries = [..._observers.entries];
    for (var e in entries) {
      e.value.lifecycle?.removeObserver(
          e.key, e.value.fullCycle == true ? LifecycleState.destroyed : null);
    }
    _observers.clear();
    _lifecycle = null;
  }

  @override
  LO? findLifecycleObserver<LO extends LifecycleObserver>() {
    final os = _observers.keys.whereType<LO>();
    LO? o = os.isEmpty ? null : os.first;
    if (o != null) return o;
    Lifecycle? l = lifecycle;
    while (l != null && l is LifecycleRegistry) {
      var owner = l.provider;
      if (owner is LifecycleOwnerStateMixin) {
        final os = owner._delegate._observers.keys.whereType<LO>();
        LO? o = os.isEmpty ? null : os.first;
        if (o != null) return o;
      }
      l = l.parent;
    }
    return null;
  }
}

class LifecycleObserverRegistryStateMixinDelegate
    extends _LifecycleObserverRegistryDelegate {
  State get _state => _target as State;

  BuildContext get _context => _state.context;

  LifecycleObserverRegistryStateMixinDelegate({required super.target})
      : assert(target is State);

  @override
  Lifecycle get lifecycle {
    if (_lifecycle == null) initState();
    return _lifecycle!;
  }

  @override
  void initState() {
    assert(_state.mounted);
    _context.visitAncestorElements((element) {
      final p =
          element.dependOnInheritedWidgetOfExactType<_EffectiveLifecycle>();
      final lifecycle = p?.lifecycle;
      _lifecycle = lifecycle;
      if (lifecycle != null) {
        LifecycleCallbacks.instance._onAttach(lifecycle, _target);
      }
      return false;
    });
  }

  @override
  void didChangeDependencies() {
    _context.visitAncestorElements((element) {
      final p =
          element.dependOnInheritedWidgetOfExactType<_EffectiveLifecycle>();
      final lifecycle = p?.lifecycle;
      final last = _lifecycle;
      if (lifecycle != last) {
        if (last != null) {
          LifecycleCallbacks.instance._onDetach(last, _target);
        }
        _lifecycle = lifecycle;
        if (lifecycle != null) {
          LifecycleCallbacks.instance._onAttach(lifecycle, _target);
        }
      }
      return false;
    });
  }

  @override
  void dispose() {
    if (_lifecycle != null) {
      LifecycleCallbacks.instance._onDetach(_lifecycle!, _target);
    }
    super.dispose();
  }
}
