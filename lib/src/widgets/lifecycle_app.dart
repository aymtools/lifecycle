import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/widgets.dart';

class _NativeAppLifecycleStateObserver with WidgetsBindingObserver {
  final LifecycleRegistry _lifecycleRegistry;

  _NativeAppLifecycleStateObserver(this._lifecycleRegistry);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        _lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
        break;
      case AppLifecycleState.resumed:
        _lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
        break;
      case AppLifecycleState.paused:
        // case AppLifecycleState.hidden:
        _lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
        break;
      case AppLifecycleState.detached:
        _lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
        break;
    }
  }
}

mixin LifecycleAppOwnerState<T extends LifecycleOwnerWidget>
    on LifecycleOwnerStateMixin<T> {
  late final _NativeAppLifecycleStateObserver _nativeAppLifecycleStateObserver =
      _NativeAppLifecycleStateObserver(lifecycleRegistry);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_nativeAppLifecycleStateObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_nativeAppLifecycleStateObserver);
    super.dispose();
  }
}

class LifecycleAppOwner extends LifecycleOwnerWidget {
  const LifecycleAppOwner({super.key, required super.child});

  @override
  LifecycleAppOwnerState<LifecycleAppOwner> createState() =>
      _LifecycleAppState();
}

abstract class LifecycleAppOwnerBaseState<LOW extends LifecycleAppOwner>
    extends State<LOW> with LifecycleOwnerStateMixin, LifecycleAppOwnerState {}

class _LifecycleAppState
    extends LifecycleAppOwnerBaseState<LifecycleAppOwner> {}

typedef LifecycleApp = LifecycleAppOwner;
typedef LifecycleAppState<T extends LifecycleOwnerWidget>
    = LifecycleAppOwnerState<T>;
typedef LifecycleAppBaseState<LOW extends LifecycleAppOwner>
    = LifecycleAppOwnerBaseState<LOW>;
