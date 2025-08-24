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
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(builder: (context) => home);
              case '/next':
                return MaterialPageRoute(builder: (context) => next);
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
    });

    testWidgets('pushDialog', (tester) async {
      final observerPageHome = TestLifecycleCollectStateObserver();
      final observerDialog = TestLifecycleCollectStateObserver();
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
          home: home,
        ),
      );

      expect(observerPageHome.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);
      expect(observerDialog.stateHistory, []);

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
    });
  });
}
