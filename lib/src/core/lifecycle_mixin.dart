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
      [LifecycleState? startWith, bool fullCycle = false]);

  void removeLifecycleObserver(LifecycleObserver observer,
      [bool fullCycle = false]);

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
      [LifecycleState? startWith,
      bool? unregisterTarget,
      bool fullCycle = false]) {
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
  void removeLifecycleObserver(LifecycleObserver observer,
      [bool fullCycle = false]) {
    if (!_observers.containsKey(observer)) return;
    _ObserverS? os = _observers.remove(observer);
    if (os != null) {
      os.lifecycle?.removeObserver(
          observer,
          fullCycle == true || (os.fullCycle)
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
    LO? o = _observers.keys.whereType<LO>().firstOrNull;
    if (o != null) return o;
    var l = lifecycle;
    while (l != null && l is LifecycleRegistry) {
      var owner = l.provider;
      if (owner is LifecycleOwnerState) {
        LO? o = owner._delegate._observers.keys.whereType<LO>().firstOrNull;
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
  void registerLifecycleObserver(LifecycleObserver observer,
          [LifecycleState? startWith, bool fullCycle = false]) =>
      _delegate.registerLifecycleObserver(observer, startWith, fullCycle);

  @override
  void removeLifecycleObserver(LifecycleObserver observer,
          [bool fullCycle = false]) =>
      _delegate.removeLifecycleObserver(observer, fullCycle);

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
        context.findAncestorStateOfType<LifecycleOwnerState>();
    _delegate.lifecycleOwner = lifecycleOwner;
  }

  @override
  void dispose() {
    _delegate.dispose();
    super.dispose();
  }
}

mixin LifecycleOwnerState<T extends StatefulWidget> on State<T>
    implements LifecycleOwner, LifecycleObserverRegister {
  late final LifecycleRegistry _lifecycle = LifecycleRegistry(this);

  late final _LifecycleObserverRegisterDelegate _delegate =
      _LifecycleObserverRegisterDelegate()..lifecycleOwner = this;

  @override
  Lifecycle get lifecycle => _lifecycle;

  @protected
  LifecycleRegistry get lifecycleRegistry => _lifecycle;

  bool _isInactivate = false;

  bool get customDispatchEvent => false;

  @override
  LifecycleState get currentLifecycleState => _delegate.currentLifecycleState;

  @override
  void registerLifecycleObserver(LifecycleObserver observer,
          [LifecycleState? startWith, bool fullCycle = false]) =>
      _delegate.registerLifecycleObserver(observer, startWith, fullCycle);

  @override
  void removeLifecycleObserver(LifecycleObserver observer,
          [bool fullCycle = false]) =>
      _delegate.removeLifecycleObserver(observer, fullCycle);

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
        context.findAncestorStateOfType<LifecycleOwnerState>()?.lifecycle;
    lifecycleRegistry.bindParentLifecycle(parentLifecycle);
    lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
    _isInactivate = true;
    if (!customDispatchEvent) {
      WidgetsBinding.instance.addPostFrameCallback(_defDispatchResume);
    }
  }

  void _defDispatchResume(_) {
    if (_isInactivate && !customDispatchEvent) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
    }
  }
}
