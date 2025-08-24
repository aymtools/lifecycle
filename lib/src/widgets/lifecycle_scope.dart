import 'package:anlifecycle/src/core/lifecycle.dart';
import 'package:flutter/widgets.dart';

class LifecycleScopeOwner extends LifecycleOwnerWidget {
  const LifecycleScopeOwner(
      {super.key, required super.child, required super.scope});

  @override
  LifecycleOwnerState<LifecycleScopeOwner> createState() =>
      _LifecycleScopeOwnerState();
}

class _LifecycleScopeOwnerState extends State<LifecycleScopeOwner>
    with LifecycleOwnerStateMixin<LifecycleScopeOwner> {}
