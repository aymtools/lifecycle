import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tools.dart';
import 'tools_flutter.dart';

void main() {
  late TestWidgetsFlutterBinding binding;
  setUp(() {
    binding = TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Flutter Lifecycle', () {
    testWidgets('handleAppLifecycleStateChanged', (tester) async {
      final observerApp = TestLifecycleCollectStateObserver();
      final observerPage = TestLifecycleCollectStateObserver();

      await tester.pumpWidget(
        TestLifecycleApp(
          observer: observerApp,
          home: LifecycleObserverWatcher(
            observer: observerPage,
          ),
        ),
      );
      expect(observerApp.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);

      expect(observerPage.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);

      // 模拟 app 进入后台
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(observerApp.historySub(3),
          [LifecycleState.started, LifecycleState.created]);

      expect(observerPage.historySub(3),
          [LifecycleState.started, LifecycleState.created]);

      // 模拟 app 可见但不活动
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(observerApp.historySub(5), [LifecycleState.started]);
      expect(observerPage.historySub(5), [LifecycleState.started]);
    });

    testWidgets('pushRoute', (tester) async {
      final observerPageHome = TestLifecycleCollectStateObserver();
      final observerPageNext = TestLifecycleCollectStateObserver();
      final navigatorObserver = LifecycleNavigatorObserver.hookMode();

      expect(navigatorObserver.getRouteHistory().length, 0);

      final home = LifecycleObserverWatcher(
        observer: observerPageHome,
        child: Builder(builder: (context) {
          return TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/next');
              },
              child: const Text('Next'));
        }),
      );
      final next = LifecycleObserverWatcher(
        observer: observerPageNext,
        child: Builder(builder: (context) {
          return TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('pop'));
        }),
      );

      await tester.pumpWidget(
        TestLifecycleApp(
          initRouteName: '/',
          navigatorObserver: navigatorObserver,
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(
                    settings: settings, builder: (context) => home);
              case '/next':
                return MaterialPageRoute(
                    settings: settings, builder: (context) => next);
              default:
                return null;
            }
          },
        ),
      );

      expect(observerPageHome.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);
      expect(observerPageNext.stateHistory, []);

      expect(navigatorObserver.getTopRoute()?.settings.name, '/');
      expect(navigatorObserver.getRouteHistory().length, 1);

      await tester.tap(find.byType(TextButton));

      await tester.pump();

      expect(observerPageHome.historySub(3),
          [LifecycleState.started, LifecycleState.created]);
      expect(observerPageNext.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);

      await tester.pumpAndSettle();

      expect(navigatorObserver.getTopRoute()?.settings.name, '/next');
      final routes = navigatorObserver.getRouteHistory();
      expect(routes.length, 2);
      expect(navigatorObserver.checkVisible(routes.first), false);
      expect(navigatorObserver.checkVisible(routes.last), true);

      expect(observerPageHome.historySub(3),
          [LifecycleState.started, LifecycleState.created]);
      expect(observerPageNext.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(observerPageHome.historySub(5), []);
      expect(observerPageNext.historySub(3),
          [LifecycleState.started, LifecycleState.created]);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(observerPageHome.historySub(5), []);
      expect(observerPageNext.historySub(5),
          [LifecycleState.started, LifecycleState.resumed]);

      await tester.tap(find.byType(TextButton));

      await tester.pump();
      expect(observerPageHome.historySub(5), [
        LifecycleState.started,
        LifecycleState.resumed,
      ]);
      expect(observerPageNext.historySub(7), [
        LifecycleState.started,
        LifecycleState.created,
      ]);

      await tester.pumpAndSettle();
      expect(observerPageHome.historySub(5), [
        LifecycleState.started,
        LifecycleState.resumed,
      ]);
      expect(observerPageNext.historySub(7), [
        LifecycleState.started,
        LifecycleState.created,
        LifecycleState.destroyed,
      ]);

      expect(navigatorObserver.getTopRoute()?.settings.name, '/');
      expect(navigatorObserver.getRouteHistory().length, 1);
    });

    testWidgets('pushDialog', (tester) async {
      final observerPageHome = TestLifecycleCollectStateObserver();
      final observerDialog = TestLifecycleCollectStateObserver();
      final navigatorObserver = LifecycleNavigatorObserver.hookMode();

      final dialogContent = LifecycleObserverWatcher(
        observer: observerDialog,
        child: Builder(builder: (context) {
          return TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('pop'));
        }),
      );
      final home = LifecycleObserverWatcher(
        observer: observerPageHome,
        child: Builder(builder: (context) {
          return TextButton(
              onPressed: () {
                showDialog(context: context, builder: (_) => dialogContent);
              },
              child: const Text('Dialog'));
        }),
      );

      await tester.pumpWidget(
        TestLifecycleApp(
          navigatorObserver: navigatorObserver,
          home: home,
        ),
      );

      expect(observerPageHome.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);
      expect(observerDialog.stateHistory, []);

      expect(navigatorObserver.getTopRoute()?.settings.name, '/');
      expect(navigatorObserver.getRouteHistory().length, 1);

      await tester.tap(find.byType(TextButton));

      await tester.pump();

      expect(observerPageHome.historySub(3), [LifecycleState.started]);
      expect(observerDialog.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);

      await tester.pumpAndSettle();

      expect(observerPageHome.historySub(3), [LifecycleState.started]);
      expect(observerDialog.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(observerPageHome.historySub(4), [LifecycleState.created]);
      expect(observerDialog.historySub(3),
          [LifecycleState.started, LifecycleState.created]);

      expect(navigatorObserver.getTopRoute(), isNotNull);
      expect(navigatorObserver.getTopRoute()!.settings.name, isNull);
      final routes = navigatorObserver.getRouteHistory();
      expect(routes.length, 2);
      expect(navigatorObserver.checkVisible(routes.first), true);
      expect(navigatorObserver.checkVisible(routes.last), true);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      expect(observerPageHome.historySub(5), [LifecycleState.started]);
      expect(observerDialog.historySub(5), [LifecycleState.started]);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(observerPageHome.historySub(6), []);
      expect(observerDialog.historySub(6), [LifecycleState.resumed]);

      await tester.tap(find.text('pop'));
      await tester.pump();
      expect(observerPageHome.historySub(6), [
        LifecycleState.resumed,
      ]);
      expect(observerDialog.historySub(7), [
        LifecycleState.started,
        LifecycleState.created,
      ]);

      await tester.pumpAndSettle();
      expect(observerPageHome.historySub(6), [
        LifecycleState.resumed,
      ]);
      expect(observerDialog.historySub(7), [
        LifecycleState.started,
        LifecycleState.created,
        LifecycleState.destroyed,
      ]);

      expect(navigatorObserver.getTopRoute()?.settings.name, '/');
      expect(navigatorObserver.getRouteHistory().length, 1);
    });

    testWidgets('PageViewItem', (tester) async {
      final navigatorObserver = LifecycleNavigatorObserver.hookMode();
      final observerApp = TestLifecycleCollectStateObserver();
      final observerPage = TestLifecycleCollectStateObserver();
      final observerItemOne = TestLifecycleCollectStateObserver();
      final observerItemTwo = TestLifecycleCollectStateObserver();
      final observerItemThree = TestLifecycleCollectStateObserver();

      expect(navigatorObserver.getRouteHistory().length, 0);

      final pageViewController = PageController(initialPage: 0);
      final page = LifecycleObserverWatcher(
        observer: observerPage,
        child: LifecyclePageView(
          controller: pageViewController,
          itemKeepAlive: true,
          children: [
            LifecycleScopeOwner(
                child: Builder(builder: (context) {
                  print('====${Lifecycle.maybeOf(context).hashCode}');
                  return Container(
                    child: LifecycleObserverWatcher(
                      key: ValueKey(1),
                      observer: observerItemOne,
                      child: Builder(
                        builder: (context) {
                          print(
                              '-----------${Lifecycle.maybeOf(context).hashCode}');
                          return SizedBox.shrink();
                        },
                      ),
                    ),
                  );
                }),
                scope: 'x'),
            LifecycleObserverWatcher(
                key: ValueKey(2), observer: observerItemTwo),
            LifecycleObserverWatcher(
                key: ValueKey(3), observer: observerItemThree),
          ],
        ),
      );

      await tester.pumpWidget(
        TestLifecycleApp(
          observer: observerApp,
          navigatorObserver: navigatorObserver,
          home: SizedBox.shrink(),
        ),
      );

      expect(navigatorObserver.getRouteHistory().length, 1);

      expect(observerApp.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);
      navigatorObserver.navigator
          ?.push(MaterialPageRoute(builder: (_) => page));
      await tester.pumpAndSettle();

      expect(navigatorObserver.getRouteHistory().length, 2);

      expect(observerPage.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);
      expect(observerItemOne.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);
      expect(observerItemTwo.stateHistory, []);
      expect(observerItemThree.stateHistory, []);

      await tester.pumpAndSettle();
      expect(observerApp.historySub(3), []);
      expect(observerPage.historySub(3), []);
      expect(observerItemOne.historySub(3), []);
      expect(observerItemTwo.stateHistory, []);
      expect(observerItemThree.stateHistory, []);

      await tester.pumpAndSettle();
      // await Future.delayed(Duration());

      expect(observerItemOne.historySub(2), [LifecycleState.resumed]);

      pageViewController.animateToPage(1,
          duration: Duration(milliseconds: 100), curve: Curves.linear);
      await tester.pumpAndSettle();
      expect(observerApp.historySub(3), []);
      expect(observerPage.historySub(3), []);
      expect(observerItemOne.historySub(3), [
        LifecycleState.started,
        LifecycleState.created,
      ]);
      expect(observerItemTwo.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);
      expect(observerItemThree.stateHistory, []);

      await tester.pumpAndSettle();
      expect(observerItemOne.historySub(5), []);
      expect(observerItemTwo.historySub(3), []);
      expect(observerItemThree.historySub(0), []);

      pageViewController.animateToPage(2,
          duration: Duration(milliseconds: 100), curve: Curves.linear);
      await tester.pumpAndSettle();
      expect(observerItemOne.historySub(5), []);
      expect(observerItemTwo.historySub(3), [
        LifecycleState.started,
        LifecycleState.created,
      ]);
      expect(observerItemThree.historySub(0), [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed,
      ]);

      navigatorObserver.navigator
          ?.removeRoute(navigatorObserver.getTopRoute()!);
      await tester.pumpAndSettle();
      expect(navigatorObserver.getRouteHistory().length, 1);

      expect(observerItemOne.historySub(5), [
        LifecycleState.destroyed,
      ]);
      expect(observerItemTwo.historySub(5), [
        LifecycleState.destroyed,
      ]);
      expect(observerItemThree.historySub(3), [
        LifecycleState.started,
        LifecycleState.created,
        LifecycleState.destroyed,
      ]);
      expect(observerPage.historySub(3), [
        LifecycleState.started,
        LifecycleState.created,
        LifecycleState.destroyed,
      ]);
    });
  });
}
