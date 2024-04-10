import 'package:flutter/widgets.dart';

import 'package:anlifecycle/anlifecycle.dart';

class LifecycleApp extends LifecycleOwnerWidget {
  const LifecycleApp({super.key, required super.child});

  @override
  LifecycleAppState<LifecycleApp> createState() => _LifecycleAppState();
}

class _LifecycleAppState extends State<LifecycleApp>
    with LifecycleOwnerStateMixin, LifecycleAppState {}

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

mixin LifecycleAppState<T extends LifecycleOwnerWidget>
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
