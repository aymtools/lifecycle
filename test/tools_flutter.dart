import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/material.dart';

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

  void _firstBuild(BuildContext context) {
    if (_isNotFirst) return;
    _isNotFirst = true;
    Lifecycle.of(context).addLifecycleObserver(widget.observer);
  }

  @override
  Widget build(BuildContext context) {
    _firstBuild(context);
    return widget.child ?? const SizedBox.shrink();
  }
}

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

class LifecycleTestApp extends StatelessWidget {
  final LifecycleObserver? observer;
  final Widget? home;
  final LifecycleObserver? homeObserver;
  final String? initRouteName;
  final Route<dynamic>? Function(RouteSettings)? onGenerateRoute;
  final LifecycleNavigatorObserver navigatorObserver;

  LifecycleTestApp({
    super.key,
    this.observer,
    this.home,
    this.homeObserver,
    this.initRouteName,
    this.onGenerateRoute,
    LifecycleNavigatorObserver? navigatorObserver,
  }) : navigatorObserver =
            navigatorObserver ?? LifecycleNavigatorObserver.hookMode();

  @override
  Widget build(BuildContext context) {
    return LifecycleAppOwner(
      child: MaterialApp(
        title: 'Test Lifecycle App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        navigatorObservers: [
          navigatorObserver,
        ],
        builder: (context, child) {
          if (observer == null) return child!;
          return LifecycleObserverWatcher(
            observer: observer!,
            child: child!,
          );
        },
        home: homeObserver == null
            ? home
            : LifecycleObserverWatcher(
                observer: homeObserver!,
                child: home,
              ),
        initialRoute: initRouteName,
        onGenerateRoute: onGenerateRoute,
      ),
    );
  }
}
