import 'package:anlifecycle/lifecycle.dart';
import 'package:flutter/material.dart';

import 'lifecycle_printer.dart';

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
