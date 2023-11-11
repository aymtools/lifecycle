import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'lifecycle.dart';
import 'lifecycle_mixin.dart';

class LifecyclePageViewItem extends StatefulWidget {
  // final PageController controller;
  final int index;
  final Widget child;

  const LifecyclePageViewItem(
      {super.key, required this.index, required this.child});

  @override
  State<LifecyclePageViewItem> createState() => _LifecyclePageViewItemState();
}

class _LifecyclePageViewItemState extends State<LifecyclePageViewItem>
    with LifecycleOwnerStateMixin {
  int? _lastSelectIndex;
  PageController? _controller;

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
    final currentSelectIndex = controller.page?.round();
    if (_lastSelectIndex == currentSelectIndex || currentSelectIndex == null) {
      return;
    }
    _lastSelectIndex = currentSelectIndex;
    if (currentSelectIndex == widget.index) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
    } else {
      final viewportFraction = controller.viewportFraction;
      if (viewportFraction >= 1 ||
          currentSelectIndex < (widget.index - 1) ||
          currentSelectIndex > (widget.index + 1)) {
        lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
      } else {
        lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    PageController? controller =
        context.findAncestorWidgetOfExactType<PageView>()?.controller;
    if (_controller != controller) {
      _controller?.removeListener(_changeListener);
      _lastSelectIndex = null;
      _controller = controller;
      _controller?.addListener(_changeListener);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pageSelectedDispatchEvent();
      });
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_changeListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

List<Widget> _childrenLifecycle(List<Widget> children) {
  if (children.isEmpty) return children;
  List<Widget> result = [];
  for (int i = 0; i < children.length; i++) {
    final e = children[i];
    result.add(LifecyclePageViewItem(index: i, child: e));
  }
  return result;
}

class LifecyclePageView extends PageView {
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
  }) : super(children: _childrenLifecycle(children));

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
    super.itemCount,
    super.dragStartBehavior = DragStartBehavior.start,
    super.allowImplicitScrolling = false,
    super.restorationId,
    super.clipBehavior = Clip.hardEdge,
    super.scrollBehavior,
    super.padEnds = true,
  }) : super.builder(itemBuilder: (context, index) {
          final c = itemBuilder(context, index);
          if (c == null) return null;
          return LifecyclePageViewItem(index: index, child: c);
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
