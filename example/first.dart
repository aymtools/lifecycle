import 'package:an_lifecycle/an_lifecycle.dart';
import 'package:flutter/material.dart';

import 'lifecycle_printer.dart';

class FistPage extends StatefulWidget {
  const FistPage({super.key});

  @override
  State<FistPage> createState() => _FistPageState();
}

class _FistPageState extends State<FistPage>
    with LifecycleObserverRegisterMixin, LifecycleEventPrinter {
  @override
  Widget build(BuildContext context) {
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
