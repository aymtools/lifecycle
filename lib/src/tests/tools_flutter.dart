import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/widgets.dart';

@visibleForTesting
class LifecycleObserverWatcher extends StatefulWidget {
  final LifecycleObserver observer;
  final Widget? child;

  const LifecycleObserverWatcher(
      {super.key, required this.observer, this.child});

  @override
  State<LifecycleObserverWatcher> createState() =>
      _LifecycleObserverWatcherState();
}

class _LifecycleObserverWatcherState extends State<LifecycleObserverWatcher> {
  bool _isNotFirst = false;

  void _addObserver(BuildContext context) {
    if (_isNotFirst) return;
    _isNotFirst = true;
    Lifecycle.of(context).addLifecycleObserver(widget.observer);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _addObserver(context);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? const SizedBox.shrink();
  }
}

@visibleForTesting
class LifecycleTestScope extends LifecycleOwnerWidget {
  const LifecycleTestScope({super.key, required super.child})
      : super(scope: 'test_scope');

  @override
  LifecycleOwnerState<LifecycleOwnerWidget> createState() =>
      _TestLifecycleScopeState();
}

class _TestLifecycleScopeState extends State<LifecycleOwnerWidget>
    with LifecycleOwnerStateMixin<LifecycleOwnerWidget> {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return buildReturn;
  }
}
