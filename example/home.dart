import 'package:anlifecycle/lifecycle.dart';
import 'package:flutter/material.dart';

import 'lifecycle_printer.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with LifecycleObserverRegistryMixin, LifecycleEventPrinter {
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
