part of 'lifecycle.dart';

class LifecycleRegistryStateDelegate implements LifecycleRegistryState {
  final LifecycleRegistryState target;
  final BuildContext Function() contextProvider;

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
      late Element parent = contextProvider() as Element;
      assert(parent.mounted);
      parent.visitAncestorElements((element) {
        parent = element;
        return false;
      });

      final p = parent.findAncestorWidgetOfExactType<_EffectiveLifecycle>();
      final lifecycle = p?.lifecycle;
      return lifecycle!;
    }
    return _lifecycle!;
  }

  final HashMap<LifecycleObserver, _NoObserverDispatcher> _observers =
      HashMap<LifecycleObserver, _NoObserverDispatcher>();

  @override
  void addLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? startWith,
      bool fullCycle = true,
      bool toLifecycle = false}) {
    assert(lifecycle is _LifecycleRegistryImpl);
    if (_currState <= LifecycleState.destroyed) return;
    if (_observers.containsKey(observer)) return;
    final currState = currentLifecycleState;

    final state = _minState(currState, startWith ?? LifecycleState.destroyed);

    _NoObserverDispatcher dispatcher = _NoObserverDispatcher(
        state, observer, fullCycle, _willRemove, toLifecycle);

    _observers[observer] = dispatcher;

    (lifecycle as _LifecycleRegistryImpl)
        ._addObserverDispatcher(observer, dispatcher);

    _moveState([dispatcher], currState);
  }

  void _moveState(
      Iterable<_NoObserverDispatcher> dispatchers, LifecycleState toState) {
    final owner = lifecycle.owner;
    final life = (_lifecycle as _LifecycleRegistryImpl?);
    final lState = life?.currentLifecycleState;

    dispatchers = dispatchers.where((e) => e._dispatcher._state != toState);

    for (var dispatcher in dispatchers) {
      final inner = _LifecycleRegistryImpl._moveState(
          owner, dispatcher._dispatcher, toState);

      //对于需要迁移到lifecycle的observer进行迁移
      if (dispatcher._toLifecycle &&
          _observers.containsKey(dispatcher.observer) &&
          life != null &&
          inner._state == lState) {
        final o = dispatcher.observer;
        removeLifecycleObserver(o, willEnd: LifecycleState.resumed);
        life._addObserverDispatcher(o, inner);
      }
    }
  }

  void _willRemove(
      Lifecycle lifecycle, LifecycleObserver observer, LifecycleState willEnd) {
    final dispatcher = _observers.remove(observer);
    if (dispatcher == null) return;

    if (willEnd.index < dispatcher._dispatcher._state.index) {
      _moveState([dispatcher], willEnd);
    }
  }

  @override
  void removeLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? willEnd, bool? fullCycle}) {
    lifecycle.removeLifecycleObserver(observer,
        willEnd: willEnd, fullCycle: fullCycle);
  }

  void _changeToState(LifecycleState state) {
    _currState = state;
    _onLifecycleStateChange();
  }

  late final _parentStateChanger =
      LifecycleObserver.stateChange((_) => _onLifecycleStateChange());

  set _parentLifecycle(Lifecycle? lifecycle) {
    final state = currentLifecycleState;
    _lifecycle?.removeLifecycleObserver(_parentStateChanger,
        willEnd: LifecycleState.resumed);

    _lifecycle = lifecycle;

    _lifecycle?.addLifecycleObserver(_parentStateChanger,
        startWith: state, fullCycle: true);
  }

  void _onLifecycleStateChange() =>
      _moveState([..._observers.values], currentLifecycleState);

  void initState() {
    _isFirstStart = true;
    _changeToState(LifecycleState.created);
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
    _changeToState(LifecycleState.started);
  }

  void activate() {
    _currState = LifecycleState.started;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _changeToState(LifecycleState.resumed);
    });
  }

  void dispose() {
    final obs = [..._observers.values];
    final willAddToLifecycle = obs.where((e) => e._toLifecycle);

    //当销毁的时候还存在未绑定到lifecycle的observer，则进行直接添加到对象
    if (willAddToLifecycle.isNotEmpty) {
      final life = lifecycle;
      final startWith = currentLifecycleState;
      for (var e in willAddToLifecycle) {
        life.addLifecycleObserver(e.observer,
            startWith: startWith, fullCycle: e._fullCycle);
      }
      _observers.removeWhere((_, e) => e._toLifecycle);
    }

    _changeToState(LifecycleState.destroyed);
    final life = _lifecycle;
    if (life != null) {
      final obs = [..._observers.keys];
      for (var e in obs) {
        life.removeLifecycleObserver(e);
      }
    }

    _observers.clear();
    _parentLifecycle = null;
  }
}

mixin LifecycleRegistryStateMixin<W extends StatefulWidget> on State<W>
    implements LifecycleRegistryState {
  late final LifecycleRegistryStateDelegate _delegate =
      LifecycleRegistryStateDelegate(
          target: this, contextProvider: () => context);

  @override
  void addLifecycleObserver(LifecycleObserver observer,
          {LifecycleState? startWith,
          bool fullCycle = true,
          bool toLifecycle = false}) =>
      _delegate.addLifecycleObserver(observer,
          startWith: startWith, fullCycle: fullCycle, toLifecycle: toLifecycle);

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
          bool toLifecycle = false}) =>
      _delegate.addLifecycleObserver(observer,
          startWith: startWith, fullCycle: fullCycle, toLifecycle: toLifecycle);

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
    _delegate.initState();
    super.mount(parent, newSlot);
  }

  @override
  void rebuild({bool force = false}) {
    if (_isFirstBuild) {
      _isFirstBuild = false;
      assert(() {
        final e = this;
        if (e is StatefulElement &&
            (e as StatefulElement).state is ILifecycleRegistry) {
          return false;
        }
        return true;
      }(),
          'LifecycleRegistryElementMixin state cannot be used with ILifecycleRegistry');
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
