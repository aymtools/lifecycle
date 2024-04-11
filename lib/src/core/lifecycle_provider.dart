part of 'lifecycle.dart';

abstract class LifecycleOwnerWidget extends StatefulWidget {
  final Widget child;
  final String? tag;

  const LifecycleOwnerWidget({super.key, required this.child, this.tag});

  @override
  LifecycleOwnerStateMixin<LifecycleOwnerWidget> createState();

  @override
  StatefulElement createElement() => _LifecycleOwnerElement(this);
}

class _EffectiveLifecycle extends InheritedWidget {
  const _EffectiveLifecycle({
    required this.lifecycle,
    required this.tag,
    required super.child,
  });

  final Lifecycle lifecycle;

  LifecycleState get currentState => lifecycle.currentState;
  final String? tag;

  @override
  bool updateShouldNotify(covariant _EffectiveLifecycle oldWidget) =>
      lifecycle != oldWidget.lifecycle || tag != oldWidget.tag;
}

class _LifecycleOwnerElement extends StatefulElement {
  late final LifecycleRegistry _lifecycle =
      LifecycleRegistry(lifecycleOwner);

  @override
  LifecycleOwnerWidget get widget => super.widget as LifecycleOwnerWidget;

  LifecycleOwnerStateMixin get lifecycleOwner =>
      state as LifecycleOwnerStateMixin;

  _LifecycleOwnerElement(LifecycleOwnerWidget super.widget) {
    lifecycleOwner._lifecycle = _lifecycle;
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
