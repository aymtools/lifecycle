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

    //在这里会触发首次的state.didChangeDependencies 需要纠结 start事件的处理
    super.mount(parent, newSlot);

    _lifecycle.handleLifecycleEvent(LifecycleEvent.start);
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
