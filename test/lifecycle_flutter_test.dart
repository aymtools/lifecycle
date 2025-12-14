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
        LifecycleTestApp(
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

    // testWidgets('pushRoute', (tester) async {
    //   final observerPageHome = TestLifecycleCollectStateObserver();
    //   final observerPageNext = TestLifecycleCollectStateObserver();
    //   final navigatorObserver = LifecycleNavigatorObserver.hookMode();
    //
    //   expect(navigatorObserver.getRouteHistory().length, 0);
    //
    //   final home = LifecycleObserverWatcher(
    //     observer: observerPageHome,
    //     child: Builder(builder: (context) {
    //       return TextButton(
    //           onPressed: () {
    //             Navigator.of(context).pushNamed('/next');
    //           },
    //           child: const Text('Next'));
    //     }),
    //   );
    //   final next = LifecycleObserverWatcher(
    //     observer: observerPageNext,
    //     child: Builder(builder: (context) {
    //       return TextButton(
    //           onPressed: () {
    //             Navigator.of(context).pop();
    //           },
    //           child: const Text('pop'));
    //     }),
    //   );
    //
    //   await tester.pumpWidget(
    //     LifecycleTestApp(
    //       initRouteName: '/',
    //       navigatorObserver: navigatorObserver,
    //       onGenerateRoute: (settings) {
    //         switch (settings.name) {
    //           case '/':
    //             return MaterialPageRoute(
    //                 settings: settings, builder: (context) => home);
    //           case '/next':
    //             return MaterialPageRoute(
    //                 settings: settings, builder: (context) => next);
    //           default:
    //             return null;
    //         }
    //       },
    //     ),
    //   );
    //
    //   expect(observerPageHome.stateHistory, [
    //     LifecycleState.created,
    //     LifecycleState.started,
    //     LifecycleState.resumed
    //   ]);
    //   expect(observerPageNext.stateHistory, []);
    //
    //   expect(navigatorObserver.getTopRoute()?.settings.name, '/');
    //   expect(navigatorObserver.getRouteHistory().length, 1);
    //
    //   await tester.tap(find.byType(TextButton));
    //
    //   await tester.pump();
    //
    //   expect(observerPageHome.historySub(3),
    //       [LifecycleState.started, LifecycleState.created]);
    //   expect(observerPageNext.stateHistory, [
    //     LifecycleState.created,
    //     LifecycleState.started,
    //     LifecycleState.resumed
    //   ]);
    //
    //   await tester.pumpAndSettle();
    //
    //   expect(navigatorObserver.getTopRoute()?.settings.name, '/next');
    //   final routes = navigatorObserver.getRouteHistory();
    //   expect(routes.length, 2);
    //   expect(navigatorObserver.checkVisible(routes.first), false);
    //   expect(navigatorObserver.checkVisible(routes.last), true);
    //
    //   expect(observerPageHome.historySub(3),
    //       [LifecycleState.started, LifecycleState.created]);
    //   expect(observerPageNext.stateHistory, [
    //     LifecycleState.created,
    //     LifecycleState.started,
    //     LifecycleState.resumed
    //   ]);
    //
    //   binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    //   await tester.pump();
    //   expect(observerPageHome.historySub(5), []);
    //   expect(observerPageNext.historySub(3),
    //       [LifecycleState.started, LifecycleState.created]);
    //
    //   binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    //   expect(observerPageHome.historySub(5), []);
    //   expect(observerPageNext.historySub(5),
    //       [LifecycleState.started, LifecycleState.resumed]);
    //
    //   await tester.tap(find.byType(TextButton));
    //
    //   await tester.pump();
    //   expect(observerPageHome.historySub(5), [
    //     LifecycleState.started,
    //     LifecycleState.resumed,
    //   ]);
    //   expect(observerPageNext.historySub(7), [
    //     LifecycleState.started,
    //     LifecycleState.created,
    //   ]);
    //
    //   await tester.pumpAndSettle();
    //   expect(observerPageHome.historySub(5), [
    //     LifecycleState.started,
    //     LifecycleState.resumed,
    //   ]);
    //   expect(observerPageNext.historySub(7), [
    //     LifecycleState.started,
    //     LifecycleState.created,
    //     LifecycleState.destroyed,
    //   ]);
    //
    //   expect(navigatorObserver.getTopRoute()?.settings.name, '/');
    //   expect(navigatorObserver.getRouteHistory().length, 1);
    //
    // });

    testWidgets('pushRoute', (tester) async {
      // 1. 准备观察者
      final observerPageHome = TestLifecycleCollectStateObserver();
      final observerPageNext = TestLifecycleCollectStateObserver();
      final navigatorObserver = LifecycleNavigatorObserver.hookMode();

      // 2. 定义 Key 以便精准查找
      const Key btnNextKey = Key('btn_next');
      const Key btnPopKey = Key('btn_pop');

      expect(navigatorObserver.getRouteHistory().length, 0);

      // 3. 构建页面 Widget
      final home = LifecycleObserverWatcher(
        observer: observerPageHome,
        child: Builder(builder: (context) {
          return TextButton(
              key: btnNextKey, // 添加 Key
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
              key: btnPopKey, // 添加 Key
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('pop'));
        }),
      );

      // 4. 启动应用
      await tester.pumpWidget(
        LifecycleTestApp(
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

      // --- 阶段 1: 初始状态 (Home) ---
      expect(observerPageHome.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);
      expect(observerPageNext.stateHistory, []);

      expect(navigatorObserver.getTopRoute()?.settings.name, '/');
      expect(navigatorObserver.getRouteHistory().length, 1);

      // --- 阶段 2: 跳转到下一页 (Push /next) ---
      await tester.tap(find.byKey(btnNextKey)); // 使用 Key 点击

      await tester.pump(); // 触发动画开始

      // Home: Resumed -> Started -> Created (因为被覆盖，不可见)
      // Next: Created -> Started -> Resumed
      expect(observerPageHome.historySub(3),
          [LifecycleState.started, LifecycleState.created]);
      expect(observerPageNext.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);

      await tester.pumpAndSettle(); // 等待转场结束

      expect(navigatorObserver.getTopRoute()?.settings.name, '/next');
      final routes = navigatorObserver.getRouteHistory();
      expect(routes.length, 2);
      // MaterialPageRoute 默认不透明，覆盖后上一个页面不可见 (visible=false)
      expect(navigatorObserver.checkVisible(routes.first), false);
      expect(navigatorObserver.checkVisible(routes.last), true);

      // 再次确认状态
      expect(observerPageHome.historySub(3),
          [LifecycleState.started, LifecycleState.created]);
      expect(observerPageNext.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);

      // --- 阶段 3: App 进入后台 (Paused) ---
      // 使用 tester.binding
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // Home 已经在 Created (不可见)，所以无变化
      expect(observerPageHome.historySub(5), []);
      // Next: Resumed -> Started -> Created
      expect(observerPageNext.historySub(3),
          [LifecycleState.started, LifecycleState.created]);

      // --- 阶段 4: App 恢复前台 (Resumed) ---
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      await tester.pump();

      // Home 依然不可见，无变化
      expect(observerPageHome.historySub(5), []);
      // Next: Created -> Started -> Resumed
      expect(observerPageNext.historySub(5),
          [LifecycleState.started, LifecycleState.resumed]);

      // --- 阶段 5: 返回上一页 (Pop) ---
      await tester.tap(find.byKey(btnPopKey)); // 使用 Key 点击

      await tester.pump(); // 触发动画

      // Home 开始恢复: Created -> Started -> Resumed
      expect(observerPageHome.historySub(5), [
        LifecycleState.started,
        LifecycleState.resumed,
      ]);
      // Next 开始销毁: Resumed -> Started -> Created
      expect(observerPageNext.historySub(7), [
        LifecycleState.started,
        LifecycleState.created,
      ]);

      await tester.pumpAndSettle(); // 等待销毁

      // 最终确认
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
      // 1. 准备观察者
      final observerPageHome = TestLifecycleCollectStateObserver();
      final observerDialog = TestLifecycleCollectStateObserver();
      final navigatorObserver = LifecycleNavigatorObserver.hookMode();

      // 2. 定义 Key 以便精准查找
      const Key btnOpenDialogKey = Key('btn_open_dialog');
      const Key btnCloseDialogKey = Key('btn_close_dialog');

      // 3. 构建 Widget
      final dialogContent = LifecycleObserverWatcher(
        observer: observerDialog,
        child: Builder(builder: (context) {
          return TextButton(
              key: btnCloseDialogKey, // 添加 Key
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
              key: btnOpenDialogKey, // 添加 Key
              onPressed: () {
                showDialog(context: context, builder: (_) => dialogContent);
              },
              child: const Text('Dialog'));
        }),
      );

      // 4. 启动应用
      await tester.pumpWidget(
        LifecycleTestApp(
          navigatorObserver: navigatorObserver,
          home: home,
        ),
      );

      // --- 阶段 1: 初始加载 ---
      expect(observerPageHome.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);
      expect(observerDialog.stateHistory, []);

      expect(navigatorObserver.getTopRoute()?.settings.name,
          Navigator.defaultRouteName);
      expect(navigatorObserver.getRouteHistory().length, 1);

      // --- 阶段 2: 打开 Dialog ---
      await tester.tap(find.byKey(btnOpenDialogKey));

      await tester.pump(); // 触发动画开始

      // Home 失去焦点 (Resumed -> Started)，Dialog 开始加载
      expect(observerPageHome.historySub(3), [LifecycleState.started]);
      expect(observerDialog.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);

      await tester.pumpAndSettle(); // 等待转场动画完成

      // 再次确认状态稳定
      expect(observerPageHome.historySub(3), [LifecycleState.started]);
      expect(observerDialog.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);

      // --- 阶段 3: App 进入后台 (Paused) ---
      // 使用 tester.binding
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // Home: Started -> Created
      // Dialog: Resumed -> Started -> Created
      expect(observerPageHome.historySub(4), [LifecycleState.created]);
      expect(observerDialog.historySub(3),
          [LifecycleState.started, LifecycleState.created]);

      // 验证路由栈可见性 (Dialog 背景透明，所以两个路由通常都视为 visible)
      expect(navigatorObserver.getTopRoute() != null, true);
      expect(navigatorObserver.getTopRoute()!.settings.name == null,
          true); // Dialog route 通常没有名字
      final routes = navigatorObserver.getRouteHistory();
      expect(routes.length, 2);
      expect(navigatorObserver.checkVisible(routes.first), true);
      expect(navigatorObserver.checkVisible(routes.last), true);

      // --- 阶段 4: App 变为非活动 (Inactive) ---
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      expect(observerPageHome.historySub(5), [LifecycleState.started]);
      expect(observerDialog.historySub(5), [LifecycleState.started]);

      // --- 阶段 5: App 恢复前台 (Resumed) ---
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      // Home 依然在 Dialog 后面 (无变化), Dialog 恢复交互 (Resumed)
      expect(observerPageHome.historySub(6), []);
      expect(observerDialog.historySub(6), [LifecycleState.resumed]);

      // --- 阶段 6: 关闭 Dialog ---
      await tester.tap(find.byKey(btnCloseDialogKey));
      await tester.pump();

      // Home 恢复交互 (Resumed)
      expect(observerPageHome.historySub(6), [
        LifecycleState.resumed,
      ]);
      // Dialog 开始销毁
      expect(observerDialog.historySub(7), [
        LifecycleState.started,
        LifecycleState.created,
      ]);

      await tester.pumpAndSettle(); // 等待销毁动画

      // Home 状态保持
      expect(observerPageHome.historySub(6), [
        LifecycleState.resumed,
      ]);
      // Dialog 完全销毁
      expect(observerDialog.historySub(7), [
        LifecycleState.started,
        LifecycleState.created,
        LifecycleState.destroyed,
      ]);

      expect(navigatorObserver.getTopRoute()?.settings.name,
          Navigator.defaultRouteName);
      expect(navigatorObserver.getRouteHistory().length, 1);
    });
  });
}
