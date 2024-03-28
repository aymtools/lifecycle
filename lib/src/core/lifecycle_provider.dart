part of 'lifecycle_mixin.dart';

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

  LifecycleOwnerElement(LifecycleOwnerWidget widget) : super(widget) {
    _lifecycle.addObserver(
      LifecycleObserver.stateChange((state) {
        if (state > LifecycleState.created) {
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
        '不可自定义build');
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

    final p = parent?.dependOnInheritedWidgetOfExactType<_EffectiveLifecycle>();
    _lifecycle.bindParentLifecycle(p?.lifecycle);
    _lifecycle.handleLifecycleEvent(LifecycleEvent.create);

    super.mount(parent, newSlot);
  }

  @override
  void didChangeDependencies() {
    final p = dependOnInheritedWidgetOfExactType<_EffectiveLifecycle>();
    _lifecycle.bindParentLifecycle(p?.lifecycle);
    super.didChangeDependencies();
  }

  @override
  void deactivate() {
    super.deactivate();
    _lifecycle.bindParentLifecycle(null);
  }

  @override
  void unmount() {
    _lifecycle.handleLifecycleEvent(LifecycleEvent.destroy);
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
