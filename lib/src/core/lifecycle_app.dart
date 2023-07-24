import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'lifecycle.dart';

class LifecycleApp extends StatefulWidget {
  final Widget child;

  const LifecycleApp({Key? key, required this.child}) : super(key: key);

  @override
  _LifecycleAppState createState() => _LifecycleAppState();
}

class _LifecycleAppState extends State<LifecycleApp>
    with LifecycleOwnerState, LifecycleAppState {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

mixin LifecycleAppState<T extends StatefulWidget> on LifecycleOwnerState<T>
    implements WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.deactivate);
        break;
      case AppLifecycleState.resumed:
        lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.activate);
        break;
      case AppLifecycleState.paused:
        lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
        break;
      case AppLifecycleState.detached:
        lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.dispose);
        break;
    }
  }

  @override
  void didChangeAccessibilityFeatures() {}

  @override
  void didChangeLocales(List<Locale>? locale) {}

  @override
  void didChangeMetrics() {}

  @override
  void didChangePlatformBrightness() {}

  @override
  void didChangeTextScaleFactor() {}

  @override
  void didHaveMemoryPressure() {}

  @override
  Future<bool> didPopRoute() => Future<bool>.value(false);

  @override
  Future<bool> didPushRoute(String route) => Future<bool>.value(false);

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) =>
      didPushRoute(routeInformation.location!);

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    return AppExitResponse.exit;
  }
}
