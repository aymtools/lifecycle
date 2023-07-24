import 'package:flutter/widgets.dart';

import 'lifecycle.dart';

class _ObserverS {
  final LifecycleObserver observer;
  final LifecycleState startWith;
  final bool fullCycle;

  _ObserverS(this.observer,
      [this.startWith = LifecycleState.detached, this.fullCycle = true]);
}

mixin LifecycleObserverAutoRegisterMixin<T extends StatefulWidget> on State<T> {
  Lifecycle? _lifecycle;

  final Map<LifecycleObserver, _ObserverS> _observers = {};

  LifecycleState _currState = LifecycleState.detached;

  LifecycleState get currentLifecycleState =>
      _lifecycle?.getCurrentState() ?? _currState;

  void registerLifecycleObserver(LifecycleObserver observer,
      [LifecycleState? startWith, bool? fullCycle]) {
    if (_observers.containsKey(observer)) return;
    _ObserverS os = _ObserverS(
        observer, startWith ?? LifecycleState.detached, fullCycle ?? true);
    _observers[observer] = os;

    _lifecycle?.addObserver(observer, os.startWith);
  }

  void removeLifecycleObserver(LifecycleObserver observer, [bool? fullCycle]) {
    if (!_observers.containsKey(observer)) return;
    _ObserverS? os = _observers.remove(observer);
    if (os != null) {
      _lifecycle?.removeObserver(
          observer,
          fullCycle == true || (fullCycle == null && os.fullCycle == true)
              ? LifecycleState.detached
              : null);
    }
  }

  @override
  void initState() {
    super.initState();
    _currState = LifecycleState.initialized;
  }

  @protected
  void onLifecycleOwnerChange(
      Lifecycle? lastLifecycle, Lifecycle? newLifecycle) {}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    LifecycleOwner? lifecycleOwner =
        context.findAncestorStateOfType<LifecycleOwnerState>();
    Lifecycle? lifecycle = lifecycleOwner?.lifecycle;
    if (lifecycle != _lifecycle) {
      LifecycleState? currState;
      if (_lifecycle != null) {
        currState = _lifecycle!.getCurrentState();
        for (var obs in _observers.keys) {
          _lifecycle!.removeObserver(obs);
        }
      }
      Lifecycle? last = _lifecycle;
      _lifecycle = lifecycle;
      if (_lifecycle != null) {
        for (var obs in _observers.values) {
          _lifecycle!.addObserver(obs.observer, currState ?? obs.startWith);
        }
      }
      onLifecycleOwnerChange(last, lifecycle);
    }
  }

  @override
  void dispose() {
    _currState = LifecycleState.detached;
    if (_lifecycle != null) {
      for (var obs in _observers.values) {
        _lifecycle!.removeObserver(obs.observer,
            obs.fullCycle == true ? LifecycleState.detached : null);
      }
    }
    super.dispose();
  }
}

mixin LifecycleEventObserverMixin<T extends StatefulWidget>
    on LifecycleObserverAutoRegisterMixin<T> implements LifecycleEventObserver {
  @override
  void initState() {
    super.initState();
    registerLifecycleObserver(this);
  }

  @override
  void onInit(LifecycleOwner owner) {}

  @override
  void onReady(LifecycleOwner owner) {}

  @override
  void onActivate(LifecycleOwner owner) {}

  @override
  void onDeactiviate(LifecycleOwner owner) {}

  @override
  void onDispose(LifecycleOwner owner) {
    owner.lifecycle.removeObserver(this);
  }

  @override
  void onAnyEvent(LifecycleOwner owner, LifecycleEvent event) {}
}

mixin LifecycleStateChangeObserverMixin<T extends StatefulWidget>
    on LifecycleObserverAutoRegisterMixin<T>
    implements LifecycleStateChangeObserver {
  @override
  void initState() {
    super.initState();
    registerLifecycleObserver(this);
  }

  @override
  void onStateChange(LifecycleOwner owner, LifecycleState state) {
    if (state == LifecycleState.detached) {
      owner.lifecycle.removeObserver(this);
    }
  }
}

mixin LifecycleEventDefaultObserver implements LifecycleEventObserver {
  @override
  void onInit(LifecycleOwner owner) {}

  @override
  void onReady(LifecycleOwner owner) {}

  @override
  void onActivate(LifecycleOwner owner) {}

  @override
  void onDeactiviate(LifecycleOwner owner) {}

  @override
  void onDispose(LifecycleOwner owner) {}

  @override
  void onAnyEvent(LifecycleOwner owner, LifecycleEvent event) {}
}
