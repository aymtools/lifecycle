import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Flutter Lifecycle Tests', () {
    testWidgets('Lifecycle events are triggered correctly', (tester) async {
      await tester.pumpWidget(const TestLifecycleApp());

      expect(find.text('Lifecycle Test'), findsOneWidget);
    });
  });
}

class TestCounter extends StatefulWidget {
  const TestCounter({super.key});

  @override
  State<TestCounter> createState() => _TestCounterState();
}

class _TestCounterState extends State<TestCounter> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class TestLifecycleScope extends LifecycleOwnerWidget {
  const TestLifecycleScope({super.key, required super.child})
      : super(scope: 'test_scope');

  @override
  LifecycleOwnerState<LifecycleOwnerWidget> createState() =>
      _TestLifecycleScopeState();
}

class _TestLifecycleScopeState extends State<LifecycleOwnerWidget>
    with LifecycleOwnerStateMixin<LifecycleOwnerWidget> {}

class TestLifecycleApp extends StatelessWidget {
  const TestLifecycleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LifecycleAppOwner(
      child: MaterialApp(
        title: 'Test Lifecycle App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        navigatorObservers: [
          LifecycleNavigatorObserver.hookMode(),
        ],
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Lifecycle Test'),
          ),
          body: Center(
            child: Text('Flutter Lifecycle Test'),
          ),
        ),
      ),
    );
  }
}
