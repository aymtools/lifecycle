part of 'lifecycle.dart';

abstract class LifecycleRegistryState implements ILifecycleRegistry {}

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
      {LifecycleState? startWith, bool fullCycle = true}) {
    assert(lifecycle is _LifecycleRegistryImpl);
    if (_currState <= LifecycleState.destroyed) return;
    if (_observers.containsKey(observer)) return;

    final state =
        _minState(currentLifecycleState, startWith ?? LifecycleState.destroyed);

    _NoObserverDispatcher dispatcher =
        _NoObserverDispatcher(state, observer, fullCycle, _willRemove);

    _observers[observer] = dispatcher;

    (lifecycle as _LifecycleRegistryImpl)
        ._addObserverDispatcher(observer, dispatcher);
  }

  void _willRemove(
      Lifecycle lifecycle, LifecycleObserver observer, LifecycleState willEnd) {
    final dispatcher = _observers[observer]?._dispatcher;
    if (dispatcher == null) return;

    if (willEnd.index < dispatcher._state.index) {
      _LifecycleRegistryImpl._moveState(lifecycle.owner, dispatcher, willEnd);
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

  late final parentStateChang =
      LifecycleObserver.stateChange((_) => _onLifecycleStateChange());

  set _parentLifecycle(Lifecycle? lifecycle) {
    _lifecycle?.removeLifecycleObserver(parentStateChang,
        willEnd: lifecycle?.currentLifecycleState);

    _lifecycle = lifecycle;

    _lifecycle?.addLifecycleObserver(parentStateChang,
        startWith: lifecycle?.currentLifecycleState, fullCycle: true);
  }

  void _onLifecycleStateChange() {
    final owner = lifecycle.owner;
    _observers.values.toList().forEach((observer) {
      _LifecycleRegistryImpl._moveState(owner, observer, currentLifecycleState);
    });
  }

  void initState() {
    _changeToState(LifecycleState.created);
    _isFirstStart = true;
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
    _changeToState(LifecycleState.destroyed);
    assert(_observers.isEmpty);
    _observers.clear();
  }
}

mixin LifecycleRegistryStateMixin<W extends StatefulWidget> on State<W>
    implements LifecycleRegistryState {
  late final LifecycleRegistryStateDelegate _delegate =
      LifecycleRegistryStateDelegate(
          target: this, contextProvider: () => context);

  @override
  void addLifecycleObserver(LifecycleObserver observer,
          {LifecycleState? startWith, bool fullCycle = true}) =>
      _delegate.addLifecycleObserver(observer,
          startWith: startWith, fullCycle: fullCycle);

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
          {LifecycleState? startWith, bool fullCycle = true}) =>
      _delegate.addLifecycleObserver(observer,
          startWith: startWith, fullCycle: fullCycle);

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
          'LifecycleObserverRegistryElementMixin cannot be used with ILifecycleRegistry');
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
