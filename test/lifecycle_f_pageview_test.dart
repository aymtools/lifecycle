import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tools.dart';
import 'tools_flutter.dart';

void main() {
  late LifecycleNavigatorObserver navigatorObserver;
  late TestLifecycleCollectStateObserver appCollectStateObserver;
  late TestLifecycleCollectStateObserver pageCollectStateObserver;

  late PageController pageViewController;

  late TestLifecycleCollectStateObserver oneCollectStateObserver,
      twoCollectStateObserver,
      threeCollectStateObserver;

  setUp(() {
    navigatorObserver = LifecycleNavigatorObserver.hookMode();
    appCollectStateObserver = TestLifecycleCollectStateObserver();
    pageCollectStateObserver = TestLifecycleCollectStateObserver();
    pageViewController = PageController(initialPage: 0);
    oneCollectStateObserver = TestLifecycleCollectStateObserver();
    twoCollectStateObserver = TestLifecycleCollectStateObserver();
    threeCollectStateObserver = TestLifecycleCollectStateObserver();
  });
  group('PageView', () {
    group('LifecyclePageViewItemOwner', () {
      testWidgets('lifecycle', (tester) async {
        expect(navigatorObserver.getRouteHistory().length, 0);
        await tester.pumpWidget(
          LifecycleTestApp(
            observer: appCollectStateObserver,
            navigatorObserver: navigatorObserver,
            homeObserver: pageCollectStateObserver,
            home: PageView(
              controller: pageViewController,
              children: [
                LifecyclePageViewItemOwner(
                  index: 0,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: oneCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 1,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: twoCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 2,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: threeCollectStateObserver),
                ),
              ],
            ),
          ),
        );

        expect(navigatorObserver.getRouteHistory().length, 1);
        expect(appCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);
        expect(pageCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);
        expect(oneCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);
        expect(twoCollectStateObserver.stateHistory, []);
        expect(threeCollectStateObserver.stateHistory, []);

        pageViewController.animateToPage(1,
            duration: Duration(milliseconds: 100), curve: Curves.linear);
        await tester.pumpAndSettle();

        expect(pageViewController.page?.round(), 1);
        expect(appCollectStateObserver.historySub(3), []);
        expect(pageCollectStateObserver.historySub(3), []);
        expect(oneCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
        ]);
        expect(twoCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);
        expect(threeCollectStateObserver.stateHistory, []);

        pageViewController.animateToPage(2,
            duration: Duration(milliseconds: 100), curve: Curves.linear);
        await tester.pumpAndSettle();

        expect(appCollectStateObserver.historySub(3), []);
        expect(pageCollectStateObserver.historySub(3), []);

        expect(oneCollectStateObserver.historySub(5), []);
        expect(twoCollectStateObserver.historySub(5), []);
        expect(threeCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);

        navigatorObserver.navigator?.pushReplacement(
            MaterialPageRoute(builder: (_) => SizedBox.shrink()));

        await tester.pumpAndSettle();
        expect(navigatorObserver.getRouteHistory().length, 1);
        expect(appCollectStateObserver.historySub(3), []);
        expect(pageCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
        expect(oneCollectStateObserver.historySub(5), [
          LifecycleState.destroyed,
        ]);
        expect(twoCollectStateObserver.historySub(5), [
          LifecycleState.destroyed,
        ]);
        expect(threeCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
      });

      testWidgets('jumpToPage', (tester) async {
        expect(navigatorObserver.getRouteHistory().length, 0);
        await tester.pumpWidget(
          LifecycleTestApp(
            observer: appCollectStateObserver,
            navigatorObserver: navigatorObserver,
            home: PageView(
              controller: pageViewController,
              children: [
                LifecyclePageViewItemOwner(
                  index: 0,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: oneCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 1,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: twoCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 2,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: threeCollectStateObserver),
                ),
              ],
            ),
          ),
        );

        expect(navigatorObserver.getRouteHistory().length, 1);
        expect(appCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);

        expect(oneCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);
        expect(twoCollectStateObserver.stateHistory, []);
        expect(threeCollectStateObserver.stateHistory, []);

        pageViewController.jumpToPage(1);
        await tester.pumpAndSettle();

        expect(pageViewController.page?.round(), 1);
        expect(appCollectStateObserver.historySub(3), []);
        expect(oneCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
        ]);
        expect(twoCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);
        expect(threeCollectStateObserver.stateHistory, []);

        pageViewController.jumpToPage(2);
        await tester.pumpAndSettle();

        expect(appCollectStateObserver.historySub(3), []);
        expect(oneCollectStateObserver.historySub(5), []);
        expect(twoCollectStateObserver.historySub(5), []);
        expect(threeCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);

        navigatorObserver.navigator?.pushReplacement(
            MaterialPageRoute(builder: (_) => SizedBox.shrink()));

        await tester.pumpAndSettle();
        expect(navigatorObserver.getRouteHistory().length, 1);
        expect(appCollectStateObserver.historySub(3), []);
        expect(oneCollectStateObserver.historySub(5), [
          LifecycleState.destroyed,
        ]);
        expect(twoCollectStateObserver.historySub(5), [
          LifecycleState.destroyed,
        ]);
        expect(threeCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
      });

      testWidgets('animateToPage 2', (tester) async {
        expect(navigatorObserver.getRouteHistory().length, 0);
        await tester.pumpWidget(
          LifecycleTestApp(
            observer: appCollectStateObserver,
            navigatorObserver: navigatorObserver,
            home: PageView(
              controller: pageViewController,
              children: [
                LifecyclePageViewItemOwner(
                  index: 0,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: oneCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 1,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: twoCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 2,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: threeCollectStateObserver),
                ),
              ],
            ),
          ),
        );

        expect(navigatorObserver.getRouteHistory().length, 1);

        expect(oneCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);
        expect(twoCollectStateObserver.stateHistory, []);
        expect(threeCollectStateObserver.stateHistory, []);

        pageViewController.animateToPage(2,
            duration: Duration(milliseconds: 100), curve: Curves.linear);
        await tester.pumpAndSettle();

        expect(pageViewController.page?.round(), 2);
        expect(oneCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
        ]);
        expect(twoCollectStateObserver.stateHistory, []);
        expect(threeCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);

        navigatorObserver.navigator?.pushReplacement(
            MaterialPageRoute(builder: (_) => SizedBox.shrink()));

        await tester.pumpAndSettle();
        expect(navigatorObserver.getRouteHistory().length, 1);
        expect(appCollectStateObserver.historySub(3), []);
        expect(oneCollectStateObserver.historySub(5), [
          LifecycleState.destroyed,
        ]);
        expect(twoCollectStateObserver.stateHistory, []);
        expect(threeCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
      });

      testWidgets('jumpToPage 2', (tester) async {
        expect(navigatorObserver.getRouteHistory().length, 0);
        await tester.pumpWidget(
          LifecycleTestApp(
            observer: appCollectStateObserver,
            navigatorObserver: navigatorObserver,
            home: PageView(
              controller: pageViewController,
              children: [
                LifecyclePageViewItemOwner(
                  index: 0,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: oneCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 1,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: twoCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 2,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: threeCollectStateObserver),
                ),
              ],
            ),
          ),
        );

        expect(navigatorObserver.getRouteHistory().length, 1);

        expect(oneCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);
        expect(twoCollectStateObserver.stateHistory, []);
        expect(threeCollectStateObserver.stateHistory, []);

        pageViewController.jumpToPage(2);
        await tester.pumpAndSettle();

        expect(pageViewController.page?.round(), 2);
        expect(oneCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
        ]);
        expect(twoCollectStateObserver.stateHistory, []);
        expect(threeCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);

        navigatorObserver.navigator?.pushReplacement(
            MaterialPageRoute(builder: (_) => SizedBox.shrink()));

        await tester.pumpAndSettle();
        expect(navigatorObserver.getRouteHistory().length, 1);
        expect(appCollectStateObserver.historySub(3), []);
        expect(oneCollectStateObserver.historySub(5), [
          LifecycleState.destroyed,
        ]);
        expect(twoCollectStateObserver.stateHistory, []);
        expect(threeCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
      });

      testWidgets('keepAlive=false', (tester) async {
        expect(navigatorObserver.getRouteHistory().length, 0);
        pageViewController = PageController(initialPage: 0);
        await tester.pumpWidget(
          LifecycleTestApp(
            observer: appCollectStateObserver,
            navigatorObserver: navigatorObserver,
            home: PageView(
              controller: pageViewController,
              children: [
                LifecyclePageViewItemOwner(
                  index: 0,
                  keepAlive: false,
                  child: LifecycleObserverWatcher(
                      observer: oneCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 1,
                  keepAlive: false,
                  child: LifecycleObserverWatcher(
                      observer: twoCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 2,
                  keepAlive: false,
                  child: LifecycleObserverWatcher(
                      observer: threeCollectStateObserver),
                ),
              ],
            ),
          ),
        );

        expect(navigatorObserver.getRouteHistory().length, 1);

        expect(oneCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);
        expect(twoCollectStateObserver.stateHistory, []);
        expect(threeCollectStateObserver.stateHistory, []);

        pageViewController.animateToPage(1,
            duration: Duration(milliseconds: 100), curve: Curves.linear);
        await tester.pumpAndSettle();

        expect(pageViewController.page?.round(), 1);
        expect(oneCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
        expect(twoCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);
        expect(threeCollectStateObserver.stateHistory, []);

        navigatorObserver.navigator?.pushReplacement(
            MaterialPageRoute(builder: (_) => SizedBox.shrink()));

        await tester.pumpAndSettle();
        expect(navigatorObserver.getRouteHistory().length, 1);
        expect(appCollectStateObserver.historySub(3), []);
        expect(oneCollectStateObserver.historySub(6), []);
        expect(twoCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
        expect(threeCollectStateObserver.historySub(0), []);
      });

      testWidgets('keepAlive=false animateToPage 2', (tester) async {
        expect(navigatorObserver.getRouteHistory().length, 0);
        pageViewController = PageController(initialPage: 0);
        await tester.pumpWidget(
          LifecycleTestApp(
            observer: appCollectStateObserver,
            navigatorObserver: navigatorObserver,
            home: PageView(
              controller: pageViewController,
              children: [
                LifecyclePageViewItemOwner(
                  index: 0,
                  keepAlive: false,
                  child: LifecycleObserverWatcher(
                      observer: oneCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 1,
                  keepAlive: false,
                  child: LifecycleObserverWatcher(
                      observer: twoCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 2,
                  keepAlive: false,
                  child: LifecycleObserverWatcher(
                      observer: threeCollectStateObserver),
                ),
              ],
            ),
          ),
        );

        expect(navigatorObserver.getRouteHistory().length, 1);

        expect(oneCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);
        expect(twoCollectStateObserver.stateHistory, []);
        expect(threeCollectStateObserver.stateHistory, []);

        pageViewController.animateToPage(2,
            duration: Duration(milliseconds: 100), curve: Curves.linear);
        await tester.pumpAndSettle();

        expect(pageViewController.page?.round(), 2);
        expect(oneCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
        expect(twoCollectStateObserver.stateHistory, []);
        expect(threeCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);

        navigatorObserver.navigator?.pushReplacement(
            MaterialPageRoute(builder: (_) => SizedBox.shrink()));

        await tester.pumpAndSettle();
        expect(navigatorObserver.getRouteHistory().length, 1);
        expect(appCollectStateObserver.historySub(3), []);
        expect(oneCollectStateObserver.historySub(6), []);
        expect(twoCollectStateObserver.historySub(0), []);
        expect(threeCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
      });

      testWidgets('viewportFraction=0.5', (tester) async {
        expect(navigatorObserver.getRouteHistory().length, 0);
        pageViewController =
            PageController(initialPage: 0, viewportFraction: 0.5);
        await tester.pumpWidget(
          LifecycleTestApp(
            observer: appCollectStateObserver,
            navigatorObserver: navigatorObserver,
            home: PageView(
              controller: pageViewController,
              children: [
                LifecyclePageViewItemOwner(
                  index: 0,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: oneCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 1,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: twoCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 2,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: threeCollectStateObserver),
                ),
              ],
            ),
          ),
        );

        expect(navigatorObserver.getRouteHistory().length, 1);

        expect(oneCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);
        expect(twoCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
        ]);
        expect(threeCollectStateObserver.stateHistory, []);

        pageViewController.animateToPage(1,
            duration: Duration(milliseconds: 100), curve: Curves.linear);
        await tester.pumpAndSettle();

        expect(pageViewController.page?.round(), 1);
        expect(oneCollectStateObserver.historySub(3), [LifecycleState.started]);
        expect(twoCollectStateObserver.historySub(2), [LifecycleState.resumed]);
        expect(threeCollectStateObserver.historySub(0), [
          LifecycleState.created,
          LifecycleState.started,
        ]);

        navigatorObserver.navigator?.pushReplacement(
            MaterialPageRoute(builder: (_) => SizedBox.shrink()));

        await tester.pumpAndSettle();
        expect(navigatorObserver.getRouteHistory().length, 1);
        expect(appCollectStateObserver.historySub(3), []);
        expect(oneCollectStateObserver.historySub(4), [
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
        expect(twoCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
        expect(threeCollectStateObserver.historySub(2), [
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
      });

      testWidgets('viewportFraction=0.5 2', (tester) async {
        expect(navigatorObserver.getRouteHistory().length, 0);
        pageViewController =
            PageController(initialPage: 0, viewportFraction: 0.5);
        await tester.pumpWidget(
          LifecycleTestApp(
            observer: appCollectStateObserver,
            navigatorObserver: navigatorObserver,
            home: PageView(
              controller: pageViewController,
              children: [
                LifecyclePageViewItemOwner(
                  index: 0,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: oneCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 1,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: twoCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 2,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: threeCollectStateObserver),
                ),
              ],
            ),
          ),
        );

        expect(navigatorObserver.getRouteHistory().length, 1);

        expect(oneCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);
        expect(twoCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
        ]);
        expect(threeCollectStateObserver.stateHistory, []);

        pageViewController.animateToPage(1,
            duration: Duration(milliseconds: 100), curve: Curves.linear);
        await tester.pumpAndSettle();

        expect(pageViewController.page?.round(), 1);
        expect(oneCollectStateObserver.historySub(3), [LifecycleState.started]);
        expect(twoCollectStateObserver.historySub(2), [LifecycleState.resumed]);
        expect(threeCollectStateObserver.historySub(0), [
          LifecycleState.created,
          LifecycleState.started,
        ]);

        pageViewController.animateToPage(2,
            duration: Duration(milliseconds: 100), curve: Curves.linear);
        await tester.pumpAndSettle();

        expect(pageViewController.page?.round(), 2);
        expect(oneCollectStateObserver.historySub(4), [
          LifecycleState.created,
        ]);
        expect(twoCollectStateObserver.historySub(3), [
          LifecycleState.started,
        ]);
        expect(threeCollectStateObserver.historySub(2), [
          LifecycleState.resumed,
        ]);

        navigatorObserver.navigator?.pushReplacement(
            MaterialPageRoute(builder: (_) => SizedBox.shrink()));

        await tester.pumpAndSettle();
        expect(navigatorObserver.getRouteHistory().length, 1);
        expect(appCollectStateObserver.historySub(3), []);
        expect(oneCollectStateObserver.historySub(5), [
          LifecycleState.destroyed,
        ]);
        expect(twoCollectStateObserver.historySub(4), [
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
        expect(threeCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
      });

      testWidgets('viewportFraction=0.5 animateToPage 2', (tester) async {
        expect(navigatorObserver.getRouteHistory().length, 0);
        pageViewController =
            PageController(initialPage: 0, viewportFraction: 0.5);
        await tester.pumpWidget(
          LifecycleTestApp(
            observer: appCollectStateObserver,
            navigatorObserver: navigatorObserver,
            home: PageView(
              controller: pageViewController,
              children: [
                LifecyclePageViewItemOwner(
                  index: 0,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: oneCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 1,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: twoCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 2,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: threeCollectStateObserver),
                ),
              ],
            ),
          ),
        );

        expect(navigatorObserver.getRouteHistory().length, 1);

        expect(oneCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);
        expect(twoCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
        ]);
        expect(threeCollectStateObserver.stateHistory, []);

        print('animateToPage(2');
        pageViewController.animateToPage(2,
            duration: Duration(milliseconds: 100), curve: Curves.linear);
        await tester.pumpAndSettle();

        expect(pageViewController.page?.round(), 2);
        expect(oneCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
        ]);
        expect(twoCollectStateObserver.historySub(2), []);
        expect(threeCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);

        print('pushReplacement new Page');
        navigatorObserver.navigator?.pushReplacement(
            MaterialPageRoute(builder: (_) => SizedBox.shrink()));

        await tester.pumpAndSettle();
        expect(navigatorObserver.getRouteHistory().length, 1);
        expect(appCollectStateObserver.historySub(3), []);
        expect(
            oneCollectStateObserver.historySub(5), [LifecycleState.destroyed]);
        expect(twoCollectStateObserver.historySub(2),
            [LifecycleState.created, LifecycleState.destroyed]);
        expect(threeCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
      });

      testWidgets('viewportFraction=0.6', (tester) async {
        expect(navigatorObserver.getRouteHistory().length, 0);
        pageViewController =
            PageController(initialPage: 0, viewportFraction: 0.6);
        await tester.pumpWidget(
          LifecycleTestApp(
            observer: appCollectStateObserver,
            navigatorObserver: navigatorObserver,
            home: PageView(
              controller: pageViewController,
              children: [
                LifecyclePageViewItemOwner(
                  index: 0,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: oneCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 1,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: twoCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 2,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: threeCollectStateObserver),
                ),
              ],
            ),
          ),
        );

        expect(navigatorObserver.getRouteHistory().length, 1);

        expect(oneCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);
        expect(twoCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
        ]);
        expect(threeCollectStateObserver.stateHistory, []);

        pageViewController.animateToPage(1,
            duration: Duration(milliseconds: 100), curve: Curves.linear);
        await tester.pumpAndSettle();

        expect(pageViewController.page?.round(), 1);
        expect(oneCollectStateObserver.historySub(3), [LifecycleState.started]);
        expect(twoCollectStateObserver.historySub(2), [LifecycleState.resumed]);
        expect(threeCollectStateObserver.historySub(0), [
          LifecycleState.created,
          LifecycleState.started,
        ]);

        pageViewController.animateToPage(2,
            duration: Duration(milliseconds: 100), curve: Curves.linear);
        await tester.pumpAndSettle();

        expect(pageViewController.page?.round(), 2);
        expect(oneCollectStateObserver.historySub(4), [
          LifecycleState.created,
        ]);
        expect(twoCollectStateObserver.historySub(3), [
          LifecycleState.started,
        ]);
        expect(threeCollectStateObserver.historySub(2), [
          LifecycleState.resumed,
        ]);

        navigatorObserver.navigator?.pushReplacement(
            MaterialPageRoute(builder: (_) => SizedBox.shrink()));

        await tester.pumpAndSettle();
        expect(navigatorObserver.getRouteHistory().length, 1);
        expect(appCollectStateObserver.historySub(3), []);
        expect(oneCollectStateObserver.historySub(5), [
          LifecycleState.destroyed,
        ]);
        expect(twoCollectStateObserver.historySub(4), [
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
        expect(threeCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
      });

      testWidgets('viewportFraction=0.6 animateToPage 2', (tester) async {
        expect(navigatorObserver.getRouteHistory().length, 0);
        pageViewController =
            PageController(initialPage: 0, viewportFraction: 0.6);
        await tester.pumpWidget(
          LifecycleTestApp(
            observer: appCollectStateObserver,
            navigatorObserver: navigatorObserver,
            home: PageView(
              controller: pageViewController,
              children: [
                LifecyclePageViewItemOwner(
                  index: 0,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: oneCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 1,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: twoCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 2,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: threeCollectStateObserver),
                ),
              ],
            ),
          ),
        );

        expect(navigatorObserver.getRouteHistory().length, 1);

        expect(oneCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);
        expect(twoCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
        ]);
        expect(threeCollectStateObserver.stateHistory, []);

        print('animateToPage(2');
        pageViewController.animateToPage(2,
            duration: Duration(milliseconds: 100), curve: Curves.linear);
        await tester.pumpAndSettle();

        expect(pageViewController.page?.round(), 2);
        expect(oneCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
        ]);
        expect(twoCollectStateObserver.historySub(2), []);
        expect(threeCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);

        print('pushReplacement new Page');
        navigatorObserver.navigator?.pushReplacement(
            MaterialPageRoute(builder: (_) => SizedBox.shrink()));

        await tester.pumpAndSettle();
        expect(navigatorObserver.getRouteHistory().length, 1);
        expect(appCollectStateObserver.historySub(3), []);
        expect(
            oneCollectStateObserver.historySub(5), [LifecycleState.destroyed]);
        expect(twoCollectStateObserver.historySub(2),
            [LifecycleState.created, LifecycleState.destroyed]);
        expect(threeCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
      });
      testWidgets('viewportFraction=0.3', (tester) async {
        expect(navigatorObserver.getRouteHistory().length, 0);
        pageViewController =
            PageController(initialPage: 0, viewportFraction: 0.3);
        await tester.pumpWidget(
          LifecycleTestApp(
            observer: appCollectStateObserver,
            navigatorObserver: navigatorObserver,
            home: PageView(
              controller: pageViewController,
              children: [
                LifecyclePageViewItemOwner(
                  index: 0,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: oneCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 1,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: twoCollectStateObserver),
                ),
                LifecyclePageViewItemOwner(
                  index: 2,
                  keepAlive: true,
                  child: LifecycleObserverWatcher(
                      observer: threeCollectStateObserver),
                ),
              ],
            ),
          ),
        );

        expect(navigatorObserver.getRouteHistory().length, 1);

        expect(oneCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);
        expect(twoCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed,
        ]);
        expect(threeCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
        ]);

        pageViewController.animateToPage(1,
            duration: Duration(milliseconds: 100), curve: Curves.linear);
        await tester.pumpAndSettle();

        expect(pageViewController.page?.round(), 1);
        expect(oneCollectStateObserver.historySub(3), []);
        expect(twoCollectStateObserver.historySub(3), []);
        expect(
            threeCollectStateObserver.historySub(2), [LifecycleState.resumed]);

        pageViewController.animateToPage(2,
            duration: Duration(milliseconds: 100), curve: Curves.linear);
        await tester.pumpAndSettle();

        expect(pageViewController.page?.round(), 2);
        expect(oneCollectStateObserver.historySub(4), []);
        expect(twoCollectStateObserver.historySub(3), []);
        expect(threeCollectStateObserver.historySub(2), [
          LifecycleState.resumed,
        ]);

        navigatorObserver.navigator?.pushReplacement(
            MaterialPageRoute(builder: (_) => SizedBox.shrink()));

        await tester.pumpAndSettle();
        expect(navigatorObserver.getRouteHistory().length, 1);
        expect(appCollectStateObserver.historySub(3), []);
        expect(oneCollectStateObserver.historySub(4), [
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
        expect(twoCollectStateObserver.historySub(4), [
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
        expect(threeCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
      });

      // testWidgets('viewportFraction=0.3 animateToPage 5', (tester) async {
      //   expect(navigatorObserver.getRouteHistory().length, 0);
      //   pageViewController =
      //       PageController(initialPage: 0, viewportFraction: 0.3);
      //   final fourCollectStateObserver = TestLifecycleCollectStateObserver();
      //   final fiveCollectStateObserver = TestLifecycleCollectStateObserver();
      //   final sixCollectStateObserver = TestLifecycleCollectStateObserver();
      //
      //   await tester.pumpWidget(
      //     LifecycleTestApp(
      //       observer: appCollectStateObserver,
      //       navigatorObserver: navigatorObserver,
      //       home: PageView(
      //         controller: pageViewController,
      //         children: [
      //           LifecyclePageViewItemOwner(
      //             index: 0,
      //             keepAlive: true,
      //             child: LifecycleObserverWatcher(
      //                 observer: oneCollectStateObserver),
      //           ),
      //           LifecyclePageViewItemOwner(
      //             index: 1,
      //             keepAlive: true,
      //             child: LifecycleObserverWatcher(
      //                 observer: twoCollectStateObserver),
      //           ),
      //           LifecyclePageViewItemOwner(
      //             index: 2,
      //             keepAlive: true,
      //             child: LifecycleObserverWatcher(
      //                 observer: threeCollectStateObserver),
      //           ),
      //           LifecyclePageViewItemOwner(
      //             index: 3,
      //             keepAlive: true,
      //             child: LifecycleObserverWatcher(
      //                 observer: fourCollectStateObserver),
      //           ),
      //           LifecyclePageViewItemOwner(
      //             index: 4,
      //             keepAlive: true,
      //             child: LifecycleObserverWatcher(
      //                 observer: fiveCollectStateObserver),
      //           ),
      //           LifecyclePageViewItemOwner(
      //             index: 5,
      //             keepAlive: true,
      //             child: LifecycleObserverWatcher(
      //                 observer: sixCollectStateObserver),
      //           ),
      //         ],
      //       ),
      //     ),
      //   );
      //
      //   expect(navigatorObserver.getRouteHistory().length, 1);
      //
      //   expect(oneCollectStateObserver.stateHistory, [
      //     LifecycleState.created,
      //     LifecycleState.started,
      //     LifecycleState.resumed
      //   ]);
      //   expect(twoCollectStateObserver.stateHistory, [
      //     LifecycleState.created,
      //     LifecycleState.started,
      //   ]);
      //   expect(threeCollectStateObserver.stateHistory, [
      //     LifecycleState.created,
      //     LifecycleState.started,
      //   ]);
      //   expect(fourCollectStateObserver.stateHistory, []);
      //   expect(fiveCollectStateObserver.stateHistory, []);
      //   expect(sixCollectStateObserver.stateHistory, []);
      //
      //   print('animateToPage(5');
      //   pageViewController.animateToPage(5,
      //       duration: Duration(milliseconds: 100), curve: Curves.linear);
      //   await tester.pumpAndSettle();
      //
      //   expect(pageViewController.page?.round(), 5);
      //   expect(oneCollectStateObserver.historySub(3), [
      //     LifecycleState.started,
      //     LifecycleState.created,
      //   ]);
      //   expect(twoCollectStateObserver.historySub(2), [
      //     LifecycleState.created,
      //   ]);
      //   expect(threeCollectStateObserver.historySub(2), [
      //     LifecycleState.created,
      //   ]);
      //   expect(fourCollectStateObserver.stateHistory, [
      //     LifecycleState.created,
      //     LifecycleState.started,
      //   ]);
      //   expect(fiveCollectStateObserver.stateHistory, [
      //     LifecycleState.created,
      //     LifecycleState.started,
      //   ]);
      //   expect(sixCollectStateObserver.stateHistory, [
      //     LifecycleState.created,
      //     LifecycleState.started,
      //     LifecycleState.resumed,
      //   ]);
      //
      //   print('pushReplacement new Page');
      //   navigatorObserver.navigator?.pushReplacement(
      //       MaterialPageRoute(builder: (_) => SizedBox.shrink()));
      //
      //   await tester.pumpAndSettle();
      //   expect(navigatorObserver.getRouteHistory().length, 1);
      //   expect(appCollectStateObserver.historySub(3), []);
      //   expect(oneCollectStateObserver.historySub(5), [
      //     LifecycleState.destroyed,
      //   ]);
      //   expect(twoCollectStateObserver.historySub(3), [
      //     LifecycleState.destroyed,
      //   ]);
      //   expect(threeCollectStateObserver.historySub(2), [
      //     LifecycleState.created,
      //     LifecycleState.destroyed,
      //   ]);
      //   expect(fourCollectStateObserver.historySub(2), [
      //     LifecycleState.created,
      //     LifecycleState.destroyed,
      //   ]);
      //   expect(fiveCollectStateObserver.historySub(2), [
      //     LifecycleState.created,
      //     LifecycleState.destroyed,
      //   ]);
      //   expect(sixCollectStateObserver.historySub(3), [
      //     LifecycleState.started,
      //     LifecycleState.created,
      //     LifecycleState.destroyed,
      //   ]);
      // });
    });

    testWidgets('LifecyclePageView', (tester) async {
      expect(navigatorObserver.getRouteHistory().length, 0);

      final page = LifecycleObserverWatcher(
        observer: pageCollectStateObserver,
        child: LifecyclePageView(
          controller: pageViewController,
          itemKeepAlive: true,
          children: [
            LifecycleObserverWatcher(observer: oneCollectStateObserver),
            LifecycleObserverWatcher(observer: twoCollectStateObserver),
            LifecycleObserverWatcher(observer: threeCollectStateObserver),
          ],
        ),
      );

      await tester.pumpWidget(
        LifecycleTestApp(
          observer: appCollectStateObserver,
          navigatorObserver: navigatorObserver,
          home: SizedBox.shrink(),
        ),
      );

      expect(navigatorObserver.getRouteHistory().length, 1);

      expect(appCollectStateObserver.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);
      navigatorObserver.navigator
          ?.push(MaterialPageRoute(builder: (_) => page));
      await tester.pumpAndSettle();

      expect(navigatorObserver.getRouteHistory().length, 2);

      expect(pageCollectStateObserver.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);
      expect(oneCollectStateObserver.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);
      expect(twoCollectStateObserver.stateHistory, []);
      expect(threeCollectStateObserver.stateHistory, []);

      await tester.pumpAndSettle();
      expect(appCollectStateObserver.historySub(3), []);
      expect(pageCollectStateObserver.historySub(3), []);
      expect(oneCollectStateObserver.historySub(3), []);
      expect(twoCollectStateObserver.stateHistory, []);
      expect(threeCollectStateObserver.stateHistory, []);

      await tester.pumpAndSettle();
      // await Future.delayed(Duration());

      expect(oneCollectStateObserver.historySub(2), [LifecycleState.resumed]);

      pageViewController.animateToPage(1,
          duration: Duration(milliseconds: 100), curve: Curves.linear);
      await tester.pumpAndSettle();
      expect(appCollectStateObserver.historySub(3), []);
      expect(pageCollectStateObserver.historySub(3), []);
      expect(oneCollectStateObserver.historySub(3), [
        LifecycleState.started,
        LifecycleState.created,
      ]);
      expect(twoCollectStateObserver.stateHistory, [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed
      ]);
      expect(threeCollectStateObserver.stateHistory, []);

      await tester.pumpAndSettle();
      expect(oneCollectStateObserver.historySub(5), []);
      expect(twoCollectStateObserver.historySub(3), []);
      expect(threeCollectStateObserver.historySub(0), []);

      pageViewController.animateToPage(2,
          duration: Duration(milliseconds: 100), curve: Curves.linear);
      await tester.pumpAndSettle();
      expect(oneCollectStateObserver.historySub(5), []);
      expect(twoCollectStateObserver.historySub(3), [
        LifecycleState.started,
        LifecycleState.created,
      ]);
      expect(threeCollectStateObserver.historySub(0), [
        LifecycleState.created,
        LifecycleState.started,
        LifecycleState.resumed,
      ]);

      navigatorObserver.navigator
          ?.removeRoute(navigatorObserver.getTopRoute()!);
      await tester.pumpAndSettle();
      expect(navigatorObserver.getRouteHistory().length, 1);

      expect(oneCollectStateObserver.historySub(5), [
        LifecycleState.destroyed,
      ]);
      expect(twoCollectStateObserver.historySub(5), [
        LifecycleState.destroyed,
      ]);
      expect(threeCollectStateObserver.historySub(3), [
        LifecycleState.started,
        LifecycleState.created,
        LifecycleState.destroyed,
      ]);
      expect(pageCollectStateObserver.historySub(3), [
        LifecycleState.started,
        LifecycleState.created,
        LifecycleState.destroyed,
      ]);
    });

    group('TabBarView', () {
      testWidgets('create', (tester) async {
        expect(navigatorObserver.getRouteHistory().length, 0);
        final tabController = TabController(length: 3, vsync: tester);

        final page = LifecycleObserverWatcher(
          observer: pageCollectStateObserver,
          child: LifecycleTabBarView(
            controller: tabController,
            itemKeepAlive: true,
            children: [
              LifecycleObserverWatcher(observer: oneCollectStateObserver),
              LifecycleObserverWatcher(observer: twoCollectStateObserver),
              LifecycleObserverWatcher(observer: threeCollectStateObserver),
            ],
          ),
        );

        await tester.pumpWidget(
          LifecycleTestApp(
            observer: appCollectStateObserver,
            navigatorObserver: navigatorObserver,
            home: SizedBox.shrink(),
          ),
        );

        expect(navigatorObserver.getRouteHistory().length, 1);

        expect(appCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);
        navigatorObserver.navigator
            ?.push(MaterialPageRoute(builder: (_) => page));
        await tester.pumpAndSettle();

        expect(navigatorObserver.getRouteHistory().length, 2);

        expect(pageCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);
        expect(oneCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);
        expect(twoCollectStateObserver.stateHistory, []);
        expect(threeCollectStateObserver.stateHistory, []);

        await tester.pumpAndSettle();
        expect(appCollectStateObserver.historySub(3), []);
        expect(pageCollectStateObserver.historySub(3), []);
        expect(oneCollectStateObserver.historySub(3), []);
        expect(twoCollectStateObserver.stateHistory, []);
        expect(threeCollectStateObserver.stateHistory, []);

        await tester.pumpAndSettle();
        // await Future.delayed(Duration());

        expect(oneCollectStateObserver.historySub(2), [LifecycleState.resumed]);

        tabController.animateTo(1,
            duration: Duration(milliseconds: 100), curve: Curves.linear);
        await tester.pumpAndSettle();
        expect(appCollectStateObserver.historySub(3), []);
        expect(pageCollectStateObserver.historySub(3), []);
        expect(oneCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
        ]);
        expect(twoCollectStateObserver.stateHistory, [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed
        ]);
        expect(threeCollectStateObserver.stateHistory, []);

        await tester.pumpAndSettle();
        expect(oneCollectStateObserver.historySub(5), []);
        expect(twoCollectStateObserver.historySub(3), []);
        expect(threeCollectStateObserver.historySub(0), []);

        tabController.animateTo(2,
            duration: Duration(milliseconds: 100), curve: Curves.linear);
        await tester.pumpAndSettle();
        expect(oneCollectStateObserver.historySub(5), []);
        expect(twoCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
        ]);
        expect(threeCollectStateObserver.historySub(0), [
          LifecycleState.created,
          LifecycleState.started,
          LifecycleState.resumed,
        ]);

        navigatorObserver.navigator
            ?.removeRoute(navigatorObserver.getTopRoute()!);
        await tester.pumpAndSettle();
        expect(navigatorObserver.getRouteHistory().length, 1);

        expect(oneCollectStateObserver.historySub(5), [
          LifecycleState.destroyed,
        ]);
        expect(twoCollectStateObserver.historySub(5), [
          LifecycleState.destroyed,
        ]);
        expect(threeCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
        expect(pageCollectStateObserver.historySub(3), [
          LifecycleState.started,
          LifecycleState.created,
          LifecycleState.destroyed,
        ]);
      });
    });
  });
}
