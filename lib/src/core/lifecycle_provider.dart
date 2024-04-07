part of 'lifecycle_register.dart';

abstract class LifecycleOwnerWidget extends StatefulWidget {
  final Widget child;
  final String? tag;

  const LifecycleOwnerWidget({super.key, required this.child, this.tag});

  @override
  LifecycleOwnerStateMixin<LifecycleOwnerWidget> createState();

  @override
  StatefulElement createElement() => LifecycleOwnerElement(this);
}

class _EffectiveLifecycle extends InheritedWidget {
  _EffectiveLifecycle({
    required this.lifecycle,
    required this.tag,
    required super.child,
  }) : currentState = lifecycle.currentState;

  final Lifecycle lifecycle;

  final LifecycleState currentState;
  final String? tag;

  @override
  bool updateShouldNotify(covariant _EffectiveLifecycle oldWidget) =>
      lifecycle != oldWidget.lifecycle ||
      currentState != oldWidget.currentState ||
      tag != oldWidget.tag;
}

class LifecycleOwnerElement extends StatefulElement {
  late final LifecycleRegistry _lifecycle = LifecycleRegistry(lifecycleOwner);

  @override
  LifecycleOwnerWidget get widget => super.widget as LifecycleOwnerWidget;

  LifecycleOwnerStateMixin get lifecycleOwner =>
      state as LifecycleOwnerStateMixin;

  LifecycleOwnerElement(LifecycleOwnerWidget super.widget) {
    _lifecycle.addObserver(
      LifecycleObserver.stateChange((state) {
        if (_lifecycle.currentState > LifecycleState.created) {
          markNeedsBuild();
        }
      }),
    );
  }

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
      lifecycle: lifecycleOwner.lifecycle,
      tag: widget.tag,
      child: widget.child,
    );
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    if (_lifecycle.currentState < LifecycleState.created) {
      _lifecycle.handleLifecycleEvent(LifecycleEvent.create);
    }
    lifecycleOwner._lifecycle = _lifecycle;

    final parentLifecycle = parent
        ?.dependOnInheritedWidgetOfExactType<_EffectiveLifecycle>()
        ?.lifecycle;
    _lifecycle.bindParentLifecycle(parentLifecycle);

    //在这里会触发首次的state.didChangeDependencies 需要纠结 start事件的处理
    super.mount(parent, newSlot);

    _lifecycle.handleLifecycleEvent(LifecycleEvent.start);
  }

  @override
  void didChangeDependencies() {
    final parentLifecycle =
        dependOnInheritedWidgetOfExactType<_EffectiveLifecycle>()?.lifecycle;
    _lifecycle.bindParentLifecycle(parentLifecycle);
    super.didChangeDependencies();
  }

  @override
  void unmount() {
    _lifecycle.handleLifecycleEvent(LifecycleEvent.destroy);
    _lifecycle.bindParentLifecycle(null);
    super.unmount();
    _lifecycle.clearObserver();
  }
}

const _lifecycleOwnerBuildReturn = SizedBox.shrink();

mixin LifecycleOwnerStateMixin<T extends LifecycleOwnerWidget> on State<T>
    implements LifecycleOwner, LifecycleObserverRegisterMixin<T> {
  late final LifecycleRegistry _lifecycle;

  @override
  late final _LifecycleObserverRegisterDelegate _delegate =
      _LifecycleObserverRegisterDelegate()..lifecycle = _lifecycle;

  @override
  Lifecycle get lifecycle => _lifecycle;

  @protected
  LifecycleRegistry get lifecycleRegistry => _lifecycle;

  bool _isInactivate = false;

  bool get customDispatchEvent => false;

  @override
  LifecycleState get currentLifecycleState => _delegate.currentLifecycleState;

  @override
  void addLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? startWith, bool fullCycle = true}) {
    _delegate.addLifecycleObserver(observer,
        startWith: startWith, fullCycle: fullCycle);
  }

  @override
  void removeLifecycleObserver(LifecycleObserver observer, {bool? fullCycle}) =>
      _delegate.removeLifecycleObserver(observer, fullCycle: fullCycle);

  @override
  LO? findLifecycleObserver<LO extends LifecycleObserver>() =>
      _delegate.findLifecycleObserver<LO>();

  @override
  void deactivate() {
    _isInactivate = false;
    if (customDispatchEvent) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
    }
    super.deactivate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isInactivate = true;
    if (!customDispatchEvent) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
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

mixin LifecycleObserverRegisterMixin<W extends StatefulWidget> on State<W>
    implements LifecycleObserverRegister {
  final _LifecycleObserverRegisterDelegate _delegate =
      _LifecycleObserverRegisterDelegate();

  @override
  LifecycleState get currentLifecycleState => _delegate.currentLifecycleState;

  @override
  Lifecycle? get lifecycle => _delegate.lifecycle;

  @override
  void addLifecycleObserver(LifecycleObserver observer,
      {LifecycleState? startWith, bool fullCycle = true}) {
    _delegate.addLifecycleObserver(observer,
        startWith: startWith, fullCycle: fullCycle);
  }

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
    final p = context.dependOnInheritedWidgetOfExactType<_EffectiveLifecycle>();
    _delegate.lifecycle = p?.lifecycle;
  }

  @override
  void dispose() {
    _delegate.dispose();
    super.dispose();
  }
}
