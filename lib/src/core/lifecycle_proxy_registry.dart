part of 'lifecycle.dart';

class LifecycleRegistryStateDelegate implements LifecycleRegistryState {
  final LifecycleRegistryState target;
  final BuildContext Function() contextProvider;
  Element Function()? parentProvider;

  LifecycleRegistryStateDelegate(
      {required this.target, required this.contextProvider});

  Lifecycle? _lifecycle;

  LifecycleState _currState = LifecycleState.initialized;

  bool _isFirstStart = true;

  @override
  LifecycleState get currentLifecycleState => _lifecycle == null
      ? _currState
      : _minState(_currState, _lifecycle!.currentLifecycleState);

  @override
  Lifecycle get lifecycle {
    if (_lifecycle == null) {
      late Element? parent = parentProvider?.call();
      if (parent == null) {
        parent = contextProvider() as Element;
        assert(parent.mounted);
        parent.visitAncestorElements((element) {
          parent = element;
          return false;
        });
      }
      assert(parent?.mounted == true);

      final lifecycle = Lifecycle.of(parent!, listen: false);
      return lifecycle;
    }
    return _lifecycle!;
  }

  final HashMap<LifecycleObserver, _ProxyObserverDispatcher> _observers =
      HashMap<LifecycleObserver, _ProxyObserverDispatcher>();

  @override
  void addLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? startWith,
      bool fullCycle = true,
      bool destroyWithRegistry = true}) {
    assert(lifecycle is _LifecycleRegistryImpl);
    if (_currState <= LifecycleState.destroyed) return;
    if (_observers.containsKey(observer)) return;
    final currState = currentLifecycleState;

    final state = _minState(currState, startWith ?? LifecycleState.destroyed);

    _ProxyObserverDispatcher dispatcher = _ProxyObserverDispatcher(
        observer, state, fullCycle, _willRemove, destroyWithRegistry);

    _observers[observer] = dispatcher;

    (lifecycle as _LifecycleRegistryImpl)
        ._addObserverDispatcher(observer, dispatcher);

    _moveState(
        [dispatcher], currState, (d) => _observers.containsKey(d._observer));
  }

  void _moveState(Iterable<_ProxyObserverDispatcher> dispatchers,
      LifecycleState toState, bool Function(_ObserverDispatcher) check) {
    final owner = lifecycle.owner;
    final life = (_lifecycle as _LifecycleRegistryImpl?);

    dispatchers = dispatchers
        .where((e) => e._dispatcher._state != toState && e._willToLifecycle);

    for (var dispatcher in dispatchers) {
      final observer = dispatcher._observer;

      final inner = _LifecycleRegistryImpl._moveState(
          owner, dispatcher._dispatcher, toState, check);

      if (dispatcher._state > LifecycleState.destroyed &&
          toState > LifecycleState.destroyed &&
          _observers.containsKey(observer) &&
          life != null &&
          inner._state == dispatcher._state) {
        dispatcher._willToLifecycle = false;
        if (!dispatcher._destroyWithRegistry) {
          life._observers[observer] = inner;
          _observers.remove(observer);
        }
      }
    }
  }

  void _willRemove(
      Lifecycle lifecycle, LifecycleObserver observer, LifecycleState willEnd) {
    final dispatcher = _observers.remove(observer);
    if (dispatcher == null) return;

    if (willEnd.index < dispatcher._dispatcher._state.index) {
      _moveState([dispatcher], willEnd, (_) => true);
    }
  }

  @override
  void removeLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? willEnd, bool? fullCycle}) {
    lifecycle.removeLifecycleObserver(observer,
        willEnd: willEnd, fullCycle: fullCycle);
    _observers.remove(observer);
  }

  void _changeToState(LifecycleState state) {
    if (_currState == state) return;
    _currState = state;
    _onLifecycleStateChange();
  }

  late final _parentStateChanger =
      LifecycleObserver.stateChange((_) => _onLifecycleStateChange());

  set _parentLifecycle(Lifecycle? lifecycle) {
    final state = currentLifecycleState;
    Lifecycle? life = _lifecycle;

    if (life != null) {
      life.removeLifecycleObserver(_parentStateChanger,
          willEnd: LifecycleState.resumed);
      if (lifecycle == null) {
        // 为什么会走到这里？？？？
        assert(false, '为什么会走到这里？？？？');
        dispose();
        return;
      } else {
        (life as _LifecycleRegistryImpl)
            ._observers
            .removeWhere((k, v) => _observers.containsKey(k));
      }
    }

    _lifecycle = lifecycle;

    if (lifecycle != null) {
      lifecycle.addLifecycleObserver(_parentStateChanger,
          startWith: state, fullCycle: true);
      final li = (lifecycle as _LifecycleRegistryImpl);
      _observers.forEach((k, v) {
        li._addObserverDispatcher(k, v);
      });
    }
  }

  void _onLifecycleStateChange() => _moveState([..._observers.values],
      currentLifecycleState, (d) => _observers.containsKey(d._observer));

  void initState() {
    if (_currState < LifecycleState.created) {
      _isFirstStart = true;
      _changeToState(LifecycleState.created);
    }
  }

  void didChangeDependencies() {
    final isFirst = _isFirstStart;
    if (isFirst) {
      _isFirstStart = false;
    }
    final p = contextProvider()
        .dependOnInheritedWidgetOfExactType<_EffectiveLifecycle>();
    final lifecycle = p?.lifecycle;
    final last = _lifecycle;
    if (lifecycle != last) {
      if (last != null) {
        LifecycleCallbacks.instance._onDetach(last, target);
      }
      _parentLifecycle = lifecycle;
      if (lifecycle != null) {
        LifecycleCallbacks.instance._onAttach(lifecycle, target);
      }
    }
    if (isFirst) {
      _changeToState(LifecycleState.started);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _changeToState(LifecycleState.resumed);
      });
    }
  }

  void deactivate() {
    // _changeToState(LifecycleState.started);
  }

  void activate() {
    // _currState = LifecycleState.started;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _changeToState(LifecycleState.resumed);
    });
  }

  void dispose() {
    if (_currState <= LifecycleState.destroyed) return;

    // 如果时当前register关注的observer则执行 移动状态到destroy
    final willDestroy =
        [..._observers.values].where((e) => e._destroyWithRegistry);
    if (willDestroy.isNotEmpty) {
      final life = (_lifecycle as _LifecycleRegistryImpl);
      life._observers.removeWhere((k, v) => willDestroy.contains(v));
      for (var dispatcher in willDestroy) {
        _LifecycleRegistryImpl._moveState(life.owner, dispatcher._dispatcher,
            LifecycleState.destroyed, (_) => true);
      }
      _observers.removeWhere((k, v) => willDestroy.contains(v));
    }

    //当销毁的时候还存在未绑定到lifecycle的observer，则进行直接添加到对象
    final willAddToLifecycle =
        [..._observers.values].where((e) => e._willToLifecycle);
    if (willAddToLifecycle.isNotEmpty) {
      final life = (_lifecycle as _LifecycleRegistryImpl);
      for (var dispatcher in willAddToLifecycle) {
        life._observers.remove(dispatcher._observer);
        life._addObserverDispatcher(
            dispatcher._observer, dispatcher._dispatcher);
      }
      _observers.removeWhere((k, v) => willAddToLifecycle.contains(v));
    }

    _currState = LifecycleState.destroyed;
    _observers.clear();
    _lifecycle?.removeLifecycleObserver(_parentStateChanger);
    _lifecycle = null;
  }
}

mixin LifecycleRegistryStateMixin<W extends StatefulWidget> on State<W>
    implements LifecycleRegistryState {
  late LifecycleRegistryStateDelegate _delegate =
      LifecycleRegistryStateDelegate(
          target: this, contextProvider: () => context);

  @override
  void addLifecycleObserver(LifecycleObserver observer,
          {LifecycleState? startWith,
          bool fullCycle = true,
          bool destroyWithRegistry = true}) =>
      _delegate.addLifecycleObserver(observer,
          startWith: startWith,
          fullCycle: fullCycle,
          destroyWithRegistry: destroyWithRegistry);

  @override
  LifecycleState get currentLifecycleState => _delegate.currentLifecycleState;

  @override
  Lifecycle get lifecycle => _delegate.lifecycle;

  @override
  void removeLifecycleObserver(LifecycleObserver observer,
          {LifecycleState? willEnd, bool? fullCycle}) =>
      _delegate.removeLifecycleObserver(observer,
          willEnd: willEnd, fullCycle: fullCycle);

  @override
  void initState() {
    super.initState();
    _delegate.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _delegate.didChangeDependencies();
  }

  @override
  void deactivate() {
    super.deactivate();
    _delegate.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _delegate.activate();
  }

  @override
  void dispose() {
    super.dispose();
    _delegate.dispose();
  }
}

mixin LifecycleRegistryElementMixin on ComponentElement
    implements LifecycleRegistryState {
  late final LifecycleRegistryStateDelegate _delegate =
      LifecycleRegistryStateDelegate(target: this, contextProvider: () => this);

  @override
  void addLifecycleObserver(LifecycleObserver observer,
          {LifecycleState? startWith,
          bool fullCycle = true,
          bool destroyWithRegistry = true}) =>
      _delegate.addLifecycleObserver(observer,
          startWith: startWith,
          fullCycle: fullCycle,
          destroyWithRegistry: destroyWithRegistry);

  @override
  LifecycleState get currentLifecycleState => _delegate.currentLifecycleState;

  @override
  Lifecycle get lifecycle => _delegate.lifecycle;

  @override
  void removeLifecycleObserver(LifecycleObserver observer,
          {LifecycleState? willEnd, bool? fullCycle}) =>
      _delegate.removeLifecycleObserver(observer,
          willEnd: willEnd, fullCycle: fullCycle);

  bool _isFirstBuild = true;

  @override
  void mount(Element? parent, Object? newSlot) {
    final e = this;
    if (e is StatefulElement &&
        (e as StatefulElement).state is ILifecycleRegistry) {
      final state = (e as StatefulElement).state;
      if (state is LifecycleRegistryStateMixin) {
        state._delegate = _delegate;
      } else {
        assert(false,
            'LifecycleRegistryElementMixin state cannot be used with ILifecycleRegistry');
      }
    }

    if (parent != null) {
      _delegate.parentProvider = () => parent;
    }
    _delegate.initState();
    super.mount(parent, newSlot);
    _delegate.parentProvider = null;
  }

  @override
  void rebuild({bool force = false}) {
    if (_isFirstBuild) {
      _isFirstBuild = false;
      _delegate.didChangeDependencies();
    }
    super.rebuild(force: force);
  }

  @override
  void unmount() {
    super.unmount();
    _delegate.dispose();
  }

  @override
  void didChangeDependencies() {
    _delegate.didChangeDependencies();
    super.didChangeDependencies();
  }

  @override
  void deactivate() {
    _delegate.deactivate();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _delegate.deactivate();
  }
}
