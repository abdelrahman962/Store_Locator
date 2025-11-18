import 'package:flutter/material.dart';

import 'stores_tracking.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Store Locator',
      theme: ThemeData(),
      home: const StoreMapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
