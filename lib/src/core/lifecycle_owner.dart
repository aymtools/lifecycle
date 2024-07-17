part of 'lifecycle.dart';

const _lifecycleOwnerBuildReturn = SizedBox.shrink();

abstract class LifecycleOwnerWidget extends StatefulWidget {
  final Widget child;
  final dynamic scope;

  const LifecycleOwnerWidget({super.key, required this.child, this.scope});

  @override
  LifecycleOwnerState<LifecycleOwnerWidget> createState();

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

  LifecycleState get currentState => lifecycle.currentLifecycleState;

  final dynamic scope;

  @override
  bool updateShouldNotify(covariant _EffectiveLifecycle oldWidget) =>
      lifecycle != oldWidget.lifecycle || scope != oldWidget.scope;
}

class _LifecycleOwnerElement extends StatefulElement {
  late final LifecycleRegistry _lifecycle =
      _LifecycleRegistryImpl(lifecycleOwner);

  @override
  LifecycleOwnerWidget get widget => super.widget as LifecycleOwnerWidget;

  LifecycleOwnerState get lifecycleOwner => state as LifecycleOwnerState;

  _LifecycleOwnerElement(LifecycleOwnerWidget super.widget) {
    lifecycleOwner.lifecycleRegistry = _lifecycle;
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
    if (_lifecycle.currentLifecycleState < LifecycleState.created) {
      _lifecycle.handleLifecycleEvent(LifecycleEvent.create);
    }

    final parentLifecycle =
        parent?.findAncestorWidgetOfExactType<_EffectiveLifecycle>()?.lifecycle;
    _lifecycle.bindParentLifecycle(parentLifecycle);

    LifecycleCallbacks.instance._onAttach(parentLifecycle, lifecycleOwner);

    //在这里会触发首次的state.didChangeDependencies 配合firstDidChangeDependencies分发 start事件的处理
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
    final last = _lifecycle.parent;
    if (parentLifecycle != last) {
      if (last != null) {
        LifecycleCallbacks.instance._onDetach(last, lifecycleOwner);
      }
      _lifecycle.bindParentLifecycle(parentLifecycle);
      LifecycleCallbacks.instance._onAttach(parentLifecycle, lifecycleOwner);
    }
    super.didChangeDependencies();
  }

  @override
  void deactivate() {
    super.deactivate();
    if (_lifecycle.currentLifecycleState >= LifecycleState.resumed) {
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

abstract class LifecycleOwnerState<LOW extends LifecycleOwnerWidget>
    extends State<LOW> implements LifecycleOwner {
  set lifecycleRegistry(LifecycleRegistry registry);
}

mixin LifecycleOwnerStateMixin<LOW extends LifecycleOwnerWidget> on State<LOW>
    implements LifecycleOwnerState<LOW> {
  late final LifecycleRegistry _lifecycleRegistry;

  @override
  set lifecycleRegistry(LifecycleRegistry registry) {
    _lifecycleRegistry = registry;
  }

  @override
  @protected
  LifecycleRegistry get lifecycleRegistry => _lifecycleRegistry;

  @override
  Lifecycle get lifecycle => _lifecycleRegistry;

  @override
  LifecycleState get currentLifecycleState => lifecycle.currentLifecycleState;

  bool _isInactivate = false;

  bool get customDispatchEvent => false;

  @override
  dynamic get scope => widget.scope;

  bool _firstDidChangeDependencies = true;

  @override
  void initState() {
    super.initState();
    _firstDidChangeDependencies = true;
  }

  @override
  void addLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? startWith, bool fullCycle = true}) {
    _lifecycleRegistry.addLifecycleObserver(observer,
        startWith: startWith, fullCycle: fullCycle);
  }

  @override
  void removeLifecycleObserver(LifecycleObserver observer,
          {LifecycleState? willEnd, bool? fullCycle}) =>
      _lifecycleRegistry.removeLifecycleObserver(observer,
          willEnd: willEnd, fullCycle: fullCycle);

  @override
  void deactivate() {
    _isInactivate = false;
    if (!customDispatchEvent) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
    }
    super.deactivate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isInactivate = true;
    if (_firstDidChangeDependencies) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      _firstDidChangeDependencies = false;
    }
    if (!customDispatchEvent) {
      if (lifecycleRegistry.currentLifecycleState < LifecycleState.started) {
        lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      }
      WidgetsBinding.instance.addPostFrameCallback(_defDispatchResume);
    }
  }

  @override
  void activate() {
    super.activate();
    _isInactivate = true;
    if (!customDispatchEvent &&
        lifecycleRegistry.currentLifecycleState < LifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback(_defDispatchResume);
    }
  }

  void _defDispatchResume(_) {
    if (_isInactivate &&
        !customDispatchEvent &&
        currentLifecycleState > LifecycleState.destroyed) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
    }
  }

  @override
  Widget build(BuildContext context) => buildReturn;

  Widget get buildReturn => _lifecycleOwnerBuildReturn;
}