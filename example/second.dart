import 'package:anlifecycle/lifecycle.dart';
import 'package:flutter/material.dart';

import 'lifecycle_printer.dart';

class SecondPage extends StatefulWidget {
  const SecondPage({super.key});

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage>
    with LifecycleObserverRegistryMixin, LifecycleEventPrinter {
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
