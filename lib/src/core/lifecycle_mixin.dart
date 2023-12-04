import 'package:flutter/widgets.dart';

import 'lifecycle.dart';

class _ObserverS {
  final LifecycleState startWith;
  final bool fullCycle;

  Lifecycle? lifecycle;

  _ObserverS(
      [this.startWith = LifecycleState.destroyed, this.fullCycle = false]);
}

abstract class LifecycleObserverRegister {
  Lifecycle? get lifecycle;

  LifecycleState get currentLifecycleState;

  void registerLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? startWith, bool fullCycle = false});

  //移除Observer [fullCycle] 不为空时覆盖注册时的配置
  void removeLifecycleObserver(LifecycleObserver observer, {bool? fullCycle});

  LO? findLifecycleObserver<LO extends LifecycleObserver>();
}

class _LifecycleObserverRegisterDelegate implements LifecycleObserverRegister {
  Lifecycle? _lifecycle;
  final Map<LifecycleObserver, _ObserverS> _observers = {};

  LifecycleState _currState = LifecycleState.initialized;

  @override
  Lifecycle? get lifecycle => _lifecycle;

  @override
  LifecycleState get currentLifecycleState =>
      _lifecycle?.currentState ?? _currState;

  set lifecycleOwner(LifecycleOwner? owner) {
    if (owner?.lifecycle != _lifecycle) {
      LifecycleState? currState;
      if (_lifecycle != null) {
        currState = _lifecycle!.currentState;
        for (var obs in _observers.entries) {
          _lifecycle!.removeObserver(obs.key);
          obs.value.lifecycle = null;
        }
      }
      _lifecycle = owner?.lifecycle;
      if (_lifecycle != null) {
        for (var obs in _observers.entries) {
          _lifecycle!.addObserver(obs.key, currState ?? obs.value.startWith);
          obs.value.lifecycle = _lifecycle;
        }
      }
    }
  }

  @override
  void registerLifecycleObserver(LifecycleObserver observer,
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
  }

  void dispose() {
    _currState = LifecycleState.destroyed;
    for (var e in _observers.entries) {
      e.value.lifecycle?.removeObserver(
          e.key, e.value.fullCycle == true ? LifecycleState.destroyed : null);
    }
  }

  @override
  LO? findLifecycleObserver<LO extends LifecycleObserver>() {
    final os = _observers.keys.whereType<LO>();
    LO? o = os.isEmpty ? null : os.first;
    if (o != null) return o;
    var l = lifecycle;
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

mixin LifecycleObserverRegisterMixin<W extends StatefulWidget> on State<W>
    implements LifecycleObserverRegister {
  final _LifecycleObserverRegisterDelegate _delegate =
      _LifecycleObserverRegisterDelegate();

  @override
  LifecycleState get currentLifecycleState => _delegate.currentLifecycleState;

  @override
  Lifecycle? get lifecycle => _delegate.lifecycle;

  @override
  void registerLifecycleObserver(LifecycleObserver observer,
          {LifecycleState? startWith, bool fullCycle = true}) =>
      _delegate.registerLifecycleObserver(observer,
          startWith: startWith, fullCycle: fullCycle);

  @override
  void removeLifecycleObserver(LifecycleObserver observer, {bool? fullCycle}) =>
      _delegate.removeLifecycleObserver(observer, fullCycle: fullCycle);

  @override
  LO? findLifecycleObserver<LO extends LifecycleObserver>() =>
      _delegate.findLifecycleObserver<LO>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    LifecycleOwner? lifecycleOwner =
        context.findAncestorStateOfType<LifecycleOwnerStateMixin>();
    _delegate.lifecycleOwner = lifecycleOwner;
  }

  @override
  void dispose() {
    _delegate.dispose();
    super.dispose();
  }
}
mixin LifecycleOwnerStateMixin<T extends StatefulWidget> on State<T>
    implements LifecycleOwner, LifecycleObserverRegisterMixin<T> {
  late final LifecycleRegistry _lifecycle = LifecycleRegistry(this);

  @override
  late final _LifecycleObserverRegisterDelegate _delegate =
      _LifecycleObserverRegisterDelegate()..lifecycleOwner = this;

  @override
  Lifecycle get lifecycle => _lifecycle;

  @protected
  LifecycleRegistry get lifecycleRegistry => _lifecycle;

  bool _isInactivate = false;

  bool _isFirstStart = true;

  bool get customDispatchEvent => false;

  @override
  LifecycleState get currentLifecycleState => _delegate.currentLifecycleState;

  @override
  void registerLifecycleObserver(LifecycleObserver observer,
          {LifecycleState? startWith, bool fullCycle = true}) =>
      _delegate.registerLifecycleObserver(observer,
          startWith: startWith, fullCycle: fullCycle);

  @override
  void removeLifecycleObserver(LifecycleObserver observer, {bool? fullCycle}) =>
      _delegate.removeLifecycleObserver(observer, fullCycle: fullCycle);

  @override
  LO? findLifecycleObserver<LO extends LifecycleObserver>() =>
      _delegate.findLifecycleObserver<LO>();

  @override
  void initState() {
    super.initState();
    lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.create);
  }

  @override
  void dispose() {
    lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
    _delegate.dispose();
    super.dispose();
    lifecycleRegistry.clearObserver();
  }

  @override
  void deactivate() {
    _isInactivate = false;
    if (customDispatchEvent) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
    }
    super.deactivate();
    lifecycleRegistry.bindParentLifecycle(null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Lifecycle? parentLifecycle =
        context.findAncestorStateOfType<LifecycleOwnerStateMixin>()?.lifecycle;
    lifecycleRegistry.bindParentLifecycle(parentLifecycle);
    _isInactivate = true;
    if (!customDispatchEvent) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      WidgetsBinding.instance.addPostFrameCallback(_defDispatchResume);
    } else if (_isFirstStart) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
    }
    _isFirstStart = false;
  }

  void _defDispatchResume(_) {
    if (_isInactivate &&
        !customDispatchEvent &&
        currentLifecycleState > LifecycleState.destroyed) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
    }
  }
}
