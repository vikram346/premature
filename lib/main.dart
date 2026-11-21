
import 'package:flutter/material.dart';
import 'screens/homescreen.dart';

void main() {
  runApp(const StreamBoxApp());
}

class StreamBoxApp extends StatelessWidget {
  const StreamBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StreamBox',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}
