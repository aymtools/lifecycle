import 'package:anlifecycle/src/core/lifecycle.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 适配PageView 中item的生命周期Owner
/// * [keepAlive] 当前的item是否使用 [KeepAlive]
/// * [index]在[PageView]中的位置，只有[index]==[PageController.page]的item才是[resumed]，
/// 其他可见的item是[started]，不可见的item为[created]
/// **[PageController.viewportFraction]<0.5 时的行为就比较奇怪，需要特别注意**
class LifecyclePageViewItemOwner extends LifecycleOwnerWidget {
  final int index;
  final bool keepAlive;

  /// 适配PageView 中item的生命周期Owner
  /// * [keepAlive] 当前的item是否使用 [KeepAlive]
  /// * [index]在[PageView]中的位置，只有[index]==[PageController.page]的item才是[resumed]，
  /// 其他可见的item是[started]，不可见的item为[created]
  /// **[PageController.viewportFraction]<0.5 时的行为就比较奇怪，需要特别注意**
  const LifecyclePageViewItemOwner(
      {super.key,
      required this.index,
      this.keepAlive = true,
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
      // print('${widget.index} _onIsScrollingChange');
      _pageSelectedDispatchEvent();
    }
  }

  void _changeListener() {
    // print('${widget.index} _changeListener');
    _pageSelectedDispatchEvent();
  }

  void _pageSelectedDispatchEvent() {
    // print('${widget.index} _pageSelectedDispatchEvent');
    final controller = _controller;
    if (controller == null) {
      // print('${widget.index} _pageSelectedDispatchEvent controller=null');
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      return;
    }
    if (!controller.hasClients) {
      // print(
      //     '${widget.index} _pageSelectedDispatchEvent !controller.hasClients');
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      return;
    }
    final currentSelectIndex = controller.page?.round();
    if (currentSelectIndex == null) {
      // print(
      //     '${widget.index} _pageSelectedDispatchEvent currentSelectIndex == null');
      return;
    }
    // if (_lastSelectIndex == currentSelectIndex || currentSelectIndex == null) {
    //   return;
    // }
    // _lastSelectIndex = currentSelectIndex;
    final isScrollingNotifier = controller.position.isScrollingNotifier;
    if (currentSelectIndex == widget.index) {
      if (!isScrollingNotifier.value) {
        // print(
        //     '${widget.index} _pageSelectedDispatchEvent handleLifecycleEvent resume');
        lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      }
    } else {
      final viewportFraction = controller.viewportFraction;
      final x = viewportFraction >= 1 ? 0 : ((1 / viewportFraction) / 2).ceil();
      // print(
      //     '${widget.index} _pageSelectedDispatchEvent $currentSelectIndex viewportFraction:$viewportFraction x:$x');
      if (currentSelectIndex < (widget.index - x) ||
          currentSelectIndex > (widget.index + x)) {
        // print(
        //     '${widget.index} _pageSelectedDispatchEvent handleLifecycleEvent stop');
        lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
      } else {
        // print(
        //     '${widget.index} _pageSelectedDispatchEvent handleLifecycleEvent pause');
        lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
      }
    }
    if (isScrollingNotifier.value) {
      // print('${widget.index} _pageSelectedDispatchEvent isScrolling');
      if (__isScrollingNotifier != isScrollingNotifier) {
        _isScrollingNotifier = isScrollingNotifier;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    PageController? controller;

    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is PageView) {
        controller = widget.controller;
      }
      return true;
    });

    assert(() {
      if (controller != null) {
        final pageViewState =
            context.findAncestorStateOfType<State<PageView>>();
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

    final lastController = _controller;

    if (_controller != controller) {
      _controller?.removeListener(_changeListener);
      __isScrollingNotifier?.removeListener(_onIsScrollingChange);
      // _lastSelectIndex = null;
      _controller = controller;
      _controller?.addListener(_changeListener);
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
  /// * 只有[index]==[PageController.page]的item才是[resumed]，
  /// 其他可见的item是[started]，不可见的item为[created]
  /// **[PageController.viewportFraction]<0.5 时的行为就比较奇怪，需要特别注意**
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
  /// * 只有[index]==[PageController.page]的item才是[resumed]，
  /// 其他可见的item是[started]，不可见的item为[created]
  /// **[PageController.viewportFraction]<0.5 时的行为就比较奇怪，需要特别注意**
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
  /// * 只有[index]==[PageController.page]的item才是[resumed]，
  /// 其他可见的item是[started]，不可见的item为[created]
  /// **[PageController.viewportFraction]<0.5 时的行为就比较奇怪，需要特别注意**
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
