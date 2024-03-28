import 'package:anlifecycle/lifecycle.dart';
import 'package:flutter/widgets.dart';

mixin LifecycleEventPrinter<W extends StatefulWidget>
    on LifecycleObserverRegisterMixin<W> {
  String get otherTag => '';

  @override
  void initState() {
    super.initState();
    final printer = LifecycleObserver.eventAny((event) {
      print('LifecycleEventPrinter $runtimeType $otherTag $event');
    });
    registerLifecycleObserver(printer);
  }
}

mixin LifecycleStatePrinter<W extends StatefulWidget>
    on LifecycleObserverRegisterMixin<W> {
  String get otherTag => '';

  @override
  void initState() {
    super.initState();
    final printer = LifecycleObserver.stateChange((state) {
      print('LifecycleStatePrinter $runtimeType $otherTag $state');
    });
    registerLifecycleObserver(printer);
  }
}
