import 'package:anlifecycle/anlifecycle.dart';
import 'package:anlifecycle/test.dart';
import 'package:flutter/material.dart';

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
