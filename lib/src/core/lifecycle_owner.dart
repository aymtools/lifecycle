part of 'lifecycle.dart';

const _lifecycleOwnerBuildReturn = SizedBox.shrink();

/// LifecycleOwner的寄存管理widget
abstract class LifecycleOwnerWidget extends StatefulWidget {
  final Widget child;
  final dynamic scope;

  const LifecycleOwnerWidget({super.key, required this.child, this.scope});

  @override
  LifecycleOwnerState<LifecycleOwnerWidget> createState();

  @override
  StatefulElement createElement() => _LifecycleOwnerElement(this);
}

class _LifecycleEffective extends InheritedWidget {
  const _LifecycleEffective({
    required this.lifecycle,
    required this.scope,
    required super.child,
  });

  final Lifecycle lifecycle;

  LifecycleState get currentState => lifecycle.currentLifecycleState;

  final dynamic scope;

  @override
  bool updateShouldNotify(covariant _LifecycleEffective oldWidget) =>
      lifecycle != oldWidget.lifecycle || scope != oldWidget.scope;
}

class _LifecycleOwnerElement extends StatefulElement {
  LifecycleOwnerState? _owner;

  LifecycleRegistry get _lifecycle => lifecycleOwner.lifecycleRegistry;

  @override
  LifecycleOwnerWidget get widget => super.widget as LifecycleOwnerWidget;

  LifecycleOwnerState get lifecycleOwner {
    _owner ??= state as LifecycleOwnerState;
    return _owner!;
  }

  _LifecycleOwnerElement(LifecycleOwnerWidget super.widget);

  // bool _isFirstBuild = true;

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
    return _LifecycleEffective(
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
    Lifecycle? parentLifecycle;
    if (parent != null) {
      parentLifecycle = Lifecycle.maybeOf(parent, listen: false);
    }
    _lifecycle.bindParentLifecycle(parentLifecycle);

    LifecycleCallbacks.instance._onAttach(parentLifecycle, lifecycleOwner);

    //在这里会触发首次的state.didChangeDependencies 配合firstDidChangeDependencies分发 start事件的处理
    super.mount(parent, newSlot);

    // super.mount 会间接调用首次的 FirstBuild 所以可以 移除调用 void rebuild({bool force = false})
    _lifecycle.handleLifecycleEvent(LifecycleEvent.start);
  }

  // flutter 2.17中 无参数 保证兼容 状态由state.didChangeDependencies 首次调用来保证首次start触发在build之前
  // @override
  // void rebuild({bool force = false}) {
  //   if (_isFirstBuild) {
  //     _isFirstBuild = false;
  //     //确保首次start触发在build之前
  //     _lifecycle.handleLifecycleEvent(LifecycleEvent.start);
  //   }
  //   super.rebuild(force: force);
  // }

  @override
  void didChangeDependencies() {
    final parentLifecycle =
        dependOnInheritedWidgetOfExactType<_LifecycleEffective>()?.lifecycle;
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
    final l = _lifecycle;
    l.handleLifecycleEvent(LifecycleEvent.destroy);
    if (l.parent != null) {
      LifecycleCallbacks.instance._onDetach(l.parent!, lifecycleOwner);
      l.bindParentLifecycle(null);
    }
    super.unmount();
  }
}

/// 用来管理 lifecycleRegistry 的 state
abstract class LifecycleOwnerState<LOW extends LifecycleOwnerWidget>
    extends State<LOW> implements LifecycleOwner {}

/// 可混入 快速管理 使用 [lifecycleRegistry]
mixin LifecycleOwnerStateMixin<LOW extends LifecycleOwnerWidget> on State<LOW>
    implements LifecycleOwnerState<LOW> {
  late final LifecycleRegistry _lifecycleRegistry =
      _LifecycleRegistryImpl(this);

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

  void _defDispatchResume(dynamic _) {
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

@visibleForTesting
class LifecycleOwnerMock extends LifecycleOwner {
  @override
  final dynamic scope;
  @override
  late final LifecycleRegistryMock lifecycleRegistry =
      LifecycleRegistryMock(this);

  LifecycleOwnerMock([this.scope]);
}

@Deprecated('use LifecycleOwnerMock')
@visibleForTesting
typedef MockLifecycleOwner = LifecycleOwnerMock;
