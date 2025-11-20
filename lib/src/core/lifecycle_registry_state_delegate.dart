part of 'lifecycle.dart';

class _LifecycleWillAddToOwner {
  final LifecycleObserver observer;
  final LifecycleState? startWith;
  final bool fullCycle;
  final bool destroyWithRegistry;

  _LifecycleWillAddToOwner(
      this.observer, this.startWith, this.fullCycle, this.destroyWithRegistry);
}

/// 可以用来管理的代理者
class LifecycleRegistryStateDelegate implements LifecycleRegistryState {
  final LifecycleRegistryState target;
  final BuildContext Function() contextProvider;
  Element Function()? parentProvider;

  LifecycleRegistryStateDelegate(
      {required this.target, required this.contextProvider});

  Lifecycle? _lifecycle;

  LifecycleState _currState = LifecycleState.initialized;

  bool _isFirstStart = true;

  bool _isActivated = false;

  @override
  LifecycleState get currentLifecycleState => _lifecycle == null
      ? _currState
      : _minState(_currState, _lifecycle!.currentLifecycleState);

  Map<LifecycleObserver, _LifecycleWillAddToOwner>? _willAddObservers;

  @override
  Lifecycle get lifecycle {
    if (_lifecycle == null) {
      if (_currState == LifecycleState.destroyed) {
        throw 'currentLifecycleState is destroyed';
      }
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

  final LinkedHashMap<LifecycleObserver, _LifecycleObserverProxyDispatcher>
      _observers = LinkedHashMap.identity();

  @override
  void addLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? startWith,
      bool fullCycle = true,
      bool destroyWithRegistry = true}) {
    if (_currState == LifecycleState.initialized) {
      _willAddObservers ??= {};
      _willAddObservers![observer] = _LifecycleWillAddToOwner(
          observer, startWith, fullCycle, destroyWithRegistry);
      return;
    }
    if (_currState <= LifecycleState.destroyed) return;
    if (lifecycle is _LifecycleRegistryImpl) {
      if (_observers.containsKey(observer)) return;
      final currState = currentLifecycleState;
      final state =
          _minState(currState, startWith ?? LifecycleState.initialized);
      _LifecycleObserverProxyDispatcher dispatcher =
          _LifecycleObserverProxyDispatcher(
              observer, state, fullCycle, _willRemove, destroyWithRegistry);
      _observers[observer] = dispatcher;
      (lifecycle as _LifecycleRegistryImpl)
          ._addObserverDispatcher(observer, dispatcher);
      _moveState(
          [dispatcher], currState, (d) => _observers.containsKey(d._observer));
    } else {
      lifecycle.addLifecycleObserver(observer,
          startWith: startWith, fullCycle: fullCycle);
    }
  }

  void _moveState(
      Iterable<_LifecycleObserverProxyDispatcher> dispatchers,
      LifecycleState toState,
      bool Function(_LifecycleObserverDispatcher) check) {
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
    _lifecycle?.removeLifecycleObserver(observer,
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
      for (var observer in [..._observers.entries]) {
        li._addObserverDispatcher(observer.key, observer.value);
      }
    }
  }

  void _onLifecycleStateChange() => _moveState([..._observers.values],
      currentLifecycleState, (d) => _observers.containsKey(d._observer));

  void initState() {
    if (_currState < LifecycleState.created) {
      _isFirstStart = true;
      _changeToState(LifecycleState.created);
      if (_willAddObservers != null) {
        for (var e in [..._willAddObservers!.entries]) {
          addLifecycleObserver(e.key,
              startWith: e.value.startWith,
              fullCycle: e.value.fullCycle,
              destroyWithRegistry: e.value.destroyWithRegistry);
        }
        _willAddObservers = null;
      }
    }
  }

  void didChangeDependencies() {
    final isFirst = _isFirstStart;
    if (isFirst) {
      _isFirstStart = false;
    }
    final p = contextProvider()
        .dependOnInheritedWidgetOfExactType<_LifecycleEffective>();
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
      _isActivated = true;
      _changeToState(LifecycleState.started);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currState > LifecycleState.initialized && _isActivated) {
          _changeToState(LifecycleState.resumed);
        }
      });
    }
  }

  void deactivate() {
    _isActivated = false;
    //_changeToState(LifecycleState.created);
  }

  void activate() {
    // _currState = LifecycleState.started;
    _isActivated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currState > LifecycleState.initialized && _isActivated) {
        _changeToState(LifecycleState.resumed);
      }
    });
  }

  void dispose() {
    if (_currState <= LifecycleState.destroyed) return;
    _currState = LifecycleState.destroyed;
    final lifecycle = _lifecycle as _LifecycleRegistryImpl?;
    if (lifecycle == null) return;
    _lifecycle = null;

    /// 移除parent管理
    lifecycle.removeLifecycleObserver(_parentStateChanger, fullCycle: false);

    if (_observers.isEmpty) return;

    final dispatchers = [..._observers.values];

    bool checker(_LifecycleObserverDispatcher d) =>
        _observers.containsKey(d._observer);
    final lObservers = lifecycle._observers;
    final lState = lifecycle.currentLifecycleState;

    /// 对当前自己管理的observer 进行转移处理
    for (var dispatcher in dispatchers) {
      if (dispatcher._destroyWithRegistry) {
        /// 如果是跟随register销毁的 则进行状态移动到destroyed
        _LifecycleRegistryImpl._moveState(lifecycle.owner,
            dispatcher._dispatcher, LifecycleState.destroyed, checker);
      } else if (dispatcher._willToLifecycle) {
        /// 如果是要添加到lifecycle的 则进行添加到目标对象
        /// 先移动到目标状态
        if (dispatcher._dispatcher._state != lState) {
          _LifecycleRegistryImpl._moveState(
              lifecycle.owner, dispatcher._dispatcher, lState, checker);

          /// 如果移动过程中发生了移除 则跳过添加
          if (!_observers.containsKey(dispatcher._observer)) {
            continue;
          }
        }

        /// 直接替换保证加入时的顺序
        lObservers[dispatcher._observer] = dispatcher._dispatcher;
      }
    }
    // 最后清空管理
    _observers.clear();

    // //当销毁的时候还存在未绑定到lifecycle的observer，则进行直接添加到对象
    // final willAddToLifecycle =
    // [..._observers.values].where((e) => e._willToLifecycle);
    // if (willAddToLifecycle.isNotEmpty) {
    //   /// 先移除管理
    //   _observers.removeWhere((k, v) => willAddToLifecycle.contains(v));
    //   // 在添加到目标
    //   for (var dispatcher in willAddToLifecycle) {
    //     lifecycle._observers.remove(dispatcher._observer);
    //     lifecycle._addObserverDispatcher(
    //         dispatcher._observer, dispatcher._dispatcher);
    //   }
    // }
    //
    // // 如果时当前register 关注的observer 则执行 移动状态到destroy
    // final willDestroy =
    // [..._observers.values].where((e) => e._destroyWithRegistry);
    // if (willDestroy.isNotEmpty) {
    //   lifecycle._observers.removeWhere((k, v) => willDestroy.contains(v));
    //   for (var dispatcher in willDestroy) {
    //     _LifecycleRegistryImpl._moveState(
    //         lifecycle.owner,
    //         dispatcher._dispatcher,
    //         LifecycleState.destroyed,
    //             (d) => _observers.containsKey(d._observer));
    //   }
    // }
    // _observers.clear();
  }
}
