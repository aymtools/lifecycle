import 'package:anlifecycle/lifecycle.dart';
import 'package:flutter/widgets.dart';

mixin LifecycleEventPrinter<W extends StatefulWidget>
    on LifecycleRegistryStateMixin<W> {
  String get otherTag => '';

  @override
  void initState() {
    super.initState();
    final printer = LifecycleObserver.eventAny((event) {
      print('LifecycleEventPrinter $runtimeType $otherTag $event');
    });
    addLifecycleObserver(printer);
  }
}

mixin LifecycleStatePrinter<W extends StatefulWidget>
    on LifecycleRegistryStateMixin<W> {
  String get otherTag => '';

  @override
  void initState() {
    super.initState();
    final printer = LifecycleObserver.stateChange((state) {
      print('LifecycleStatePrinter $runtimeType $otherTag $state');
    });
    addLifecycleObserver(printer);
  }
}
