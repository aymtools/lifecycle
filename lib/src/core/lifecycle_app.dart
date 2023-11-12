import 'package:flutter/widgets.dart';

import 'lifecycle.dart';
import 'lifecycle_mixin.dart';

class LifecycleApp extends StatefulWidget {
  final Widget child;

  const LifecycleApp({Key? key, required this.child}) : super(key: key);

  @override
  State<LifecycleApp> createState() => _LifecycleAppState();
}

class _LifecycleAppState extends State<LifecycleApp>
    with LifecycleOwnerStateMixin, LifecycleAppState {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

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
        _lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
        break;
      case AppLifecycleState.detached:
        _lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
        break;
    }
  }
}

mixin LifecycleAppState<T extends StatefulWidget>
    on LifecycleOwnerStateMixin<T> {
  late _NativeAppLifecycleStateObserver _nativeAppLifecycleStateObserver;

  @override
  void initState() {
    super.initState();
    _nativeAppLifecycleStateObserver =
        _NativeAppLifecycleStateObserver(lifecycleRegistry);
    WidgetsBinding.instance.addObserver(_nativeAppLifecycleStateObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_nativeAppLifecycleStateObserver);
    super.dispose();
  }
}
