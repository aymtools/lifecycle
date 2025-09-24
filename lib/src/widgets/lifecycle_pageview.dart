import 'package:anlifecycle/src/core/lifecycle.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 适配PageView 中item的生命周期Owner
class LifecyclePageViewItemOwner extends LifecycleOwnerWidget {
  final int index;
  final bool keepAlive;

  /// 适配PageView 中item的生命周期Owner
  /// * [keepAlive] 当前的item是否使用 [KeepAlive]
  /// * 完全可见的的item才是[resumed]
  /// 不完全可见的item是[started]，不可见的item为[created]
  const LifecyclePageViewItemOwner(
      {super.key,
      required this.index,
      this.keepAlive = false,
      required super.child,
      super.scope});

  @override
  LifecycleOwnerStateMixin<LifecycleOwnerWidget> createState() =>
      _LifecyclePageViewItemState();
}

mixin LifecyclePageViewItemOwnerState
    on LifecycleOwnerStateMixin<LifecyclePageViewItemOwner> {
  // int? _lastSelectIndex;
  PageController? _controller;

  ValueNotifier<bool>? __isScrollingNotifier;

  late void Function(PageController) _dispatchLifecycleEventer =
      _dispatchLifecycleEvent;

  void _changeController(PageController? controller) {
    final lastController = _controller;

    if (_controller != controller) {
      _controller?.removeListener(_changeListener);
      __isScrollingNotifier?.removeListener(_onIsScrollingChange);
      // _lastSelectIndex = null;
      _controller = controller;
      _controller?.addListener(_changeListener);
      if (controller == null) {
        _dispatchLifecycleEventer = _dispatchLifecycleEvent;
      } else {
        _dispatchLifecycleEventer = controller.viewportFraction > 1
            ? _dispatchLifecycleEvent2
            : _dispatchLifecycleEvent;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageSelectedDispatchEvent();
      });
    } else if (lastController == null && controller != null) {
      ///  如果未找到 PageView的Controller 则遵从默认规则直接到 resume
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageSelectedDispatchEvent();
      });
    }
  }

  @override
  bool get customDispatchEvent => true;

  set _isScrollingNotifier(ValueNotifier<bool> value) {
    __isScrollingNotifier?.removeListener(_onIsScrollingChange);
    __isScrollingNotifier = value;
    value.addListener(_onIsScrollingChange);
  }

  void _onIsScrollingChange() {
    if (__isScrollingNotifier?.value == false) {
      __isScrollingNotifier = null;
      _pageSelectedDispatchEvent();
    }
  }

  void _changeListener() {
    _pageSelectedDispatchEvent();
  }

  void _pageSelectedDispatchEvent() {
    final controller = _controller;
    if (controller == null) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      return;
    }
    if (!controller.hasClients) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      return;
    }
    // final isScrollingNotifier = controller.position.isScrollingNotifier;
    //
    // if (isScrollingNotifier.value) {
    //   // print('${widget.index} _pageSelectedDispatchEvent isScrolling');
    //   if (__isScrollingNotifier != isScrollingNotifier) {
    //     _isScrollingNotifier = isScrollingNotifier;
    //   }
    //   if (_isVisible(widget.index, controller)) {
    //     // 当处于滚动状态时处于可见并且resumed的状态不进行切换
    //     if(lifecycleRegistry.currentLifecycleState < LifecycleState.started){
    //       lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
    //     }
    //     // lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
    //   } else {
    //     lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
    //   }
    // } else {
    // print(
    //     '${widget.index} _pageSelectedDispatchEvent visibleFraction:$visibleFraction');
    // if (visibleFraction == 1.0) {
    //   lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
    // } else if (visibleFraction > 0.0) {
    //   lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
    // } else {
    //   lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
    // }
    // }

    _dispatchLifecycleEventer(controller);
  }

  void _dispatchLifecycleEvent(PageController controller) {
    final visibleFraction = _visibleFraction(widget.index, controller);
    if (visibleFraction == 1.0) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
    } else if (visibleFraction > 0.0) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
    } else {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
    }
  }

  void _dispatchLifecycleEvent2(PageController controller) {
    final isScrollingNotifier = controller.position.isScrollingNotifier;
    if (isScrollingNotifier.value) {
      if (__isScrollingNotifier != isScrollingNotifier) {
        _isScrollingNotifier = isScrollingNotifier;
      }
      _dispatchLifecycleEvent(controller);
    } else {
      if (_isVisible(widget.index, controller)) {
        // 滚动结束时可见的唯一一个页面
        lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      } else {
        lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
      }
    }
  }

  double _currentPage(PageController controller) {
    return controller.page ?? controller.initialPage.toDouble();
  }

  bool _isVisible(int index, PageController controller) {
    // if (!controller.hasClients) return false;
    // final double? page = controller.page;
    // if (page == null) return false;
    //
    // final fraction = controller.viewportFraction; // 0~1
    // final diff = (page - index).abs();
    //
    // // 如果 diff < 1 ，并且页面的一部分会进入屏幕
    // return diff < 1 / fraction;
    final double f = controller.viewportFraction;
    final double diff = (_currentPage(controller) - index).abs();
    // 可见的阈值（>0 表示有重叠）
    final double threshold = (1 + f) / (2 * f);
    return diff < threshold;
  }

  /// 计算[index]页面可见的比例，0.0~1.0 0 不可见 1 完全可见 其他部分可见
  double _visibleFraction(int index, PageController controller) {
    // if (!controller.hasClients) return 0.0;
    // final double? page = controller.page;
    // if (page == null) return 0.0;
    //
    // final fraction = controller.viewportFraction; // 每页占屏幕的比例
    // final diff = (page - index).abs();
    //
    // if (diff >= 1 / fraction) return 0.0;
    //
    // // 简化后的计算：当 diff=0，完全可见=1.0；随着 diff 增大逐渐减少
    // return (1 - diff * fraction).clamp(0.0, 1.0);
    final double f = controller.viewportFraction;
    final double diff = (_currentPage(controller) - index).abs();
    final double raw = (1 + f) / (2 * f) - diff;
    return raw.clamp(0.0, 1.0); // 确保在 [0,1]
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    PageView? pageView;
    PageController? controller;

    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is PageView) {
        pageView = widget;
        controller = widget.controller;
        return false;
      }
      return true;
    });

    /// 如果未指定PageController pageView会自动生成一个
    if (controller == null && pageView != null) {
      final c = Scrollable.maybeOf(context, axis: pageView!.scrollDirection)
          ?.widget
          .controller;
      if (c is PageController) {
        controller = c;
      }
    }

    assert(() {
      if (controller != null && pageView != null) {
        State? pageViewState =
            context.findAncestorStateOfType<State<PageView>>();
        pageViewState ??=
            Scrollable.maybeOf(context, axis: pageView!.scrollDirection);
        Element? parent;
        context.visitAncestorElements((element) {
          parent = element;
          return false;
        });
        final parentLifecycle = Lifecycle.maybeOf(parent!, listen: false);
        final parent2Lifecycle =
            Lifecycle.maybeOf(pageViewState!.context, listen: false);
        return parentLifecycle == parent2Lifecycle;
      }
      return true;
    }());

    _changeController(controller);
  }

  @override
  void dispose() {
    _controller?.removeListener(_changeListener);
    __isScrollingNotifier?.removeListener(_onIsScrollingChange);
    super.dispose();
  }
}

class _LifecyclePageViewItemState extends State<LifecyclePageViewItemOwner>
    with
        LifecycleOwnerStateMixin,
        LifecyclePageViewItemOwnerState,
        AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return buildReturn;
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;
}

List<Widget> _childrenLifecycle(List<Widget> children, bool itemKeepAlive) {
  if (children.isEmpty) return children;
  List<Widget> result = [];
  for (int i = 0; i < children.length; i++) {
    result.add(LifecyclePageViewItemOwner(
        index: i, keepAlive: itemKeepAlive, child: children[i]));
  }
  return result;
}

/// 替换PageView，添加生命周期
class LifecyclePageView extends PageView {
  /// 添加了生命周期，适配PageView 中item的生命周期Owner
  /// * [itemKeepAlive] 当前的item是否使用 [KeepAlive]
  /// * 完全可见的的item才是[resumed]
  /// 不完全可见的item是[started]，不可见的item为[created]
  LifecyclePageView({
    super.key,
    super.scrollDirection = Axis.horizontal,
    super.reverse = false,
    super.controller,
    super.physics,
    super.pageSnapping = true,
    super.onPageChanged,
    List<Widget> children = const <Widget>[],
    super.dragStartBehavior = DragStartBehavior.start,
    super.allowImplicitScrolling = false,
    super.restorationId,
    super.clipBehavior = Clip.hardEdge,
    super.scrollBehavior,
    super.padEnds = true,
    bool itemKeepAlive = false,
  }) : super(children: _childrenLifecycle(children, itemKeepAlive));

  /// 添加了生命周期，适配PageView 中item的生命周期Owner
  /// * [itemKeepAlive] 当前的item是否使用 [KeepAlive]
  /// * 完全可见的的item才是[resumed]
  /// 不完全可见的item是[started]，不可见的item为[created]
  LifecyclePageView.builder({
    super.key,
    super.scrollDirection = Axis.horizontal,
    super.reverse = false,
    super.controller,
    super.physics,
    super.pageSnapping = true,
    super.onPageChanged,
    required NullableIndexedWidgetBuilder itemBuilder,
    super.findChildIndexCallback,
    required int itemCount,
    super.dragStartBehavior = DragStartBehavior.start,
    super.allowImplicitScrolling = false,
    super.restorationId,
    super.clipBehavior = Clip.hardEdge,
    super.scrollBehavior,
    super.padEnds = true,
    bool itemKeepAlive = false,
  }) : super.builder(
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index >= itemCount) return null;
              return LifecyclePageViewItemOwner(
                  index: index,
                  keepAlive: itemKeepAlive,
                  child: Builder(
                      builder: (context) => itemBuilder(context, index)!));
            });

// LifecyclePageView.custom({
//   super.key,
//   super.scrollDirection = Axis.horizontal,
//   super.reverse = false,
//   super.controller,
//   super.physics,
//   super.pageSnapping = true,
//   super.onPageChanged,
//   required super.childrenDelegate,
//   super.dragStartBehavior = DragStartBehavior.start,
//   super.allowImplicitScrolling = false,
//   super.restorationId,
//   super.clipBehavior = Clip.hardEdge,
//   super.scrollBehavior,
//   super.padEnds = true,
// }) : super.custom();
}

/// 替换TabBarView，添加生命周期
class LifecycleTabBarView extends TabBarView {
  /// 添加了生命周期，适配TabBarView 中item的生命周期Owner
  /// * [itemKeepAlive] 当前的item是否使用 [KeepAlive]
  /// * 完全可见的的item才是[resumed]
  /// 不完全可见的item是[started]，不可见的item为[created]
  LifecycleTabBarView({
    super.key,
    List<Widget> children = const <Widget>[],
    super.controller,
    super.physics,
    super.dragStartBehavior = DragStartBehavior.start,
    super.viewportFraction = 1.0,
    super.clipBehavior = Clip.hardEdge,
    bool itemKeepAlive = false,
  }) : super(children: _childrenLifecycle(children, itemKeepAlive));
}

typedef LifecyclePageViewItem = LifecyclePageViewItemOwner;
