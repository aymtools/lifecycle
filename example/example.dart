import 'package:anlifecycle/lifecycle.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

final routes = <String, WidgetBuilder>{
  '/': (context) => const MyHomePage(title: 'LifecycleApp'),
  '/first': (_) => const FistPage(),
  '/second': (_) => const SecondPage(),
  '/pageView': (_) => const PageViewExample(),
};

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LifecycleApp(
      child: MaterialApp(
        title: 'LifecycleApp Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        navigatorObservers: [
          LifecycleNavigatorObserver.hookMode(),
        ],
        routes: routes,
      ),
    );
  }
}

mixin LifecycleEventPrinter<W extends StatefulWidget>
    on LifecycleRegistryStateMixin<W> {
  String get otherTag => '';

  @override
  void initState() {
    super.initState();
    final printer = LifecycleObserver.eventAny((event) {
      print('LifecycleEventPrinter $runtimeType $otherTag $event');
    });
    addLifecycleObserver(printer);
  }
}

mixin LifecycleStatePrinter<W extends StatefulWidget>
    on LifecycleRegistryStateMixin<W> {
  String get otherTag => '';

  @override
  void initState() {
    super.initState();
    final printer = LifecycleObserver.stateChange((state) {
      print('LifecycleStatePrinter $runtimeType $otherTag $state');
    });
    addLifecycleObserver(printer);
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with LifecycleRegistryStateMixin, LifecycleEventPrinter {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed('/first');
          },
          child: const Text('Tap go first page'),
        ),
      ),
    );
  }
}

class FistPage extends StatefulWidget {
  const FistPage({super.key});

  @override
  State<FistPage> createState() => _FistPageState();
}

class _FistPageState extends State<FistPage>
    with LifecycleRegistryStateMixin, LifecycleEventPrinter {
  @override
  Widget build(BuildContext context) {
    print('FistPage build');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fist Page'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed('/second');
              },
              child: const Text('Tap go second page'),
            ),
            const Padding(padding: EdgeInsets.only(top: 12)),
            GestureDetector(
              onTap: () {
                showDialog(
                    context: context,
                    builder: (context) => const Text('dialog'));
              },
              child: const Text('Tap show Dialog'),
            ),
            const Padding(padding: EdgeInsets.only(top: 12)),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed('/pageView');
              },
              child: const Text('Tap go PageView page'),
            ),
          ],
        ),
      ),
    );
  }
}

class SecondPage extends StatefulWidget {
  const SecondPage({super.key});

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage>
    with LifecycleRegistryStateMixin, LifecycleEventPrinter {
  @override
  Widget build(BuildContext context) {
    print('SecondPage build');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Page'),
      ),
      body: const Center(
        child: Text('Second'),
      ),
    );
  }
}

class PageViewExample extends StatefulWidget {
  const PageViewExample({super.key});

  @override
  State<PageViewExample> createState() => _PageViewExampleState();
}

class _PageViewExampleState extends State<PageViewExample>
    with LifecycleRegistryStateMixin, LifecycleEventPrinter {
  final PageController _pageController = PageController(initialPage: 2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PageViewExample'),
      ),
      body: LifecyclePageView(
        controller: _pageController,
        children: [
          for (int i = 0; i < 9; i++) ItemView(index: i),
        ],
        // itemCount: 10,
        // itemBuilder: (context, index) => ItemView(index: index),
      ),
    );
  }
}

class ItemView extends StatefulWidget {
  final int index;

  const ItemView({super.key, required this.index});

  @override
  State<ItemView> createState() => _ItemViewState();
}

class _ItemViewState extends State<ItemView>
    with LifecycleRegistryStateMixin, LifecycleEventPrinter {
  @override
  String get otherTag => 'Page index ${widget.index}';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green[(widget.index + 1) * 100],
      child: Center(
        child: Text('Page index ${widget.index}'),
      ),
    );
  }
}
