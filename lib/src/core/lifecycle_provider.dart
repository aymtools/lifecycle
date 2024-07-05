part of 'lifecycle_registry.dart';

class LifecycleScope {}

abstract class LifecycleOwnerWidget extends StatefulWidget {
  final Widget child;
  final dynamic scope;

  const LifecycleOwnerWidget({super.key, required this.child, this.scope});

  @override
  LifecycleOwnerStateMixin<LifecycleOwnerWidget> createState();

  @override
  StatefulElement createElement() => _LifecycleOwnerElement(this);
}

class _EffectiveLifecycle extends InheritedWidget {
  const _EffectiveLifecycle({
    required this.lifecycle,
    required this.scope,
    required super.child,
  });

  final Lifecycle lifecycle;

  LifecycleState get currentState => lifecycle.currentState;
  final dynamic scope;

  @override
  bool updateShouldNotify(covariant _EffectiveLifecycle oldWidget) =>
      lifecycle != oldWidget.lifecycle || scope != oldWidget.scope;
}

class _LifecycleOwnerElement extends StatefulElement {
  late final LifecycleRegistry _lifecycle = LifecycleRegistry(lifecycleOwner);

  @override
  LifecycleOwnerWidget get widget => super.widget as LifecycleOwnerWidget;

  LifecycleOwnerStateMixin get lifecycleOwner =>
      state as LifecycleOwnerStateMixin;

  _LifecycleOwnerElement(LifecycleOwnerWidget super.widget) {
    lifecycleOwner._lifecycle = _lifecycle;
  }

  bool _isFirstBuild = true;

  @override
  void update(LifecycleOwnerWidget newWidget) {
    super.update(newWidget);
  }

  @override
  Widget build() {
    final result = super.build();
    assert(
        result == _lifecycleOwnerBuildReturn || result == const Placeholder(),
        'The build content cannot be customized; it must return buildReturn.');
    return _EffectiveLifecycle(
      lifecycle: _lifecycle,
      scope: widget.scope,
      child: widget.child,
    );
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    if (_lifecycle.currentState < LifecycleState.created) {
      _lifecycle.handleLifecycleEvent(LifecycleEvent.create);
    }

    final parentLifecycle = parent
        ?.dependOnInheritedWidgetOfExactType<_EffectiveLifecycle>()
        ?.lifecycle;
    _lifecycle.bindParentLifecycle(parentLifecycle);

    LifecycleCallbacks.instance._onAttach(parentLifecycle, lifecycleOwner);

    //在这里会触发首次的state.didChangeDependencies 配合firstDidChangeDependencies分发 start事件的处理
    lifecycleOwner._firstDidChangeDependencies = true;
    super.mount(parent, newSlot);

    _lifecycle.handleLifecycleEvent(LifecycleEvent.start);
  }

  @override
  void rebuild({bool force = false}) {
    if (_isFirstBuild) {
      _isFirstBuild = false;
      //确保首次start触发在build之前
      _lifecycle.handleLifecycleEvent(LifecycleEvent.start);
    }
    super.rebuild(force: force);
  }

  @override
  void didChangeDependencies() {
    final parentLifecycle =
        dependOnInheritedWidgetOfExactType<_EffectiveLifecycle>()?.lifecycle;
    _lifecycle.bindParentLifecycle(parentLifecycle);
    final lifecycle = parentLifecycle;
    final last = _lifecycle.parent;
    if (lifecycle != last) {
      if (last != null) {
        LifecycleCallbacks.instance._onDetach(last, lifecycleOwner);
      }
      _lifecycle.bindParentLifecycle(parentLifecycle);
      LifecycleCallbacks.instance._onAttach(lifecycle, lifecycleOwner);
    }
    super.didChangeDependencies();
  }

  @override
  void deactivate() {
    super.deactivate();
    if (_lifecycle.currentState >= LifecycleState.resumed) {
      _lifecycle.handleLifecycleEvent(LifecycleEvent.pause);
    }
  }

  @override
  void unmount() {
    _lifecycle.handleLifecycleEvent(LifecycleEvent.destroy);
    if (_lifecycle.parent != null) {
      LifecycleCallbacks.instance._onDetach(_lifecycle.parent!, lifecycleOwner);
      _lifecycle.bindParentLifecycle(null);
    }
    super.unmount();
    _lifecycle.clearObserver();
  }
}

mixin LifecycleObserverRegistryElementMixin on ComponentElement
    implements LifecycleObserverRegistry {
  late final LifecycleObserverRegistryDelegate
      _lifecycleObserverRegistryDelegate = LifecycleObserverRegistryDelegate(
          target: this, contextProvider: parentElementProvider);

  @override
  void addLifecycleObserver(LifecycleObserver observer,
          {LifecycleState? startWith, bool fullCycle = true}) =>
      _lifecycleObserverRegistryDelegate.addLifecycleObserver(observer,
          startWith: startWith, fullCycle: fullCycle);

  @override
  LifecycleState get currentLifecycleState =>
      _lifecycleObserverRegistryDelegate.currentLifecycleState;

  // @override
  // LO? findLifecycleObserver<LO extends LifecycleObserver>() =>
  //     _lifecycleObserverRegistryDelegate.findLifecycleObserver();

  @override
  Lifecycle get lifecycle => _lifecycleObserverRegistryDelegate.lifecycle;

  @override
  void removeLifecycleObserver(LifecycleObserver observer, {bool? fullCycle}) =>
      _lifecycleObserverRegistryDelegate.removeLifecycleObserver(observer,
          fullCycle: fullCycle);

  bool _isFirstBuild = true;

  Element? _parent;

  Element parentElementProvider() {
    var parent = _parent;
    if (parent == null) {
      visitAncestorElements((element) {
        parent = element;
        return false;
      });
    }
    return parent!;
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    _parent = parent!;
    _lifecycleObserverRegistryDelegate.initState();
    super.mount(parent, newSlot);
    _parent = null;
  }

  @override
  void rebuild({bool force = false}) {
    if (_isFirstBuild) {
      _isFirstBuild = false;
      assert(() {
        final e = this;
        if (e is StatefulElement &&
            (e as StatefulElement).state is LifecycleObserverRegistry) {
          return false;
        }
        return true;
      }(),
          'LifecycleObserverRegistryElementMixin cannot be used with LifecycleObserverRegistryState');
      _lifecycleObserverRegistryDelegate.didChangeDependencies();
    }
    super.rebuild(force: force);
  }

  @override
  void unmount() {
    super.unmount();
    _lifecycleObserverRegistryDelegate.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lifecycleObserverRegistryDelegate.didChangeDependencies();
  }
}
