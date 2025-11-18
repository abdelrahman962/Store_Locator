import 'package:flutter/material.dart';

import 'store_tracking.dart';

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
      home: const MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
