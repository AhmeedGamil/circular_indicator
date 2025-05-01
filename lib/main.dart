import 'package:flutter/material.dart';
import 'circular_indicator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Circular Indicator Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: Scaffold(
          appBar: AppBar(
            title: Text(
              "Circular Indicator",
              style: TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            backgroundColor: Colors.blueAccent,
          ),
          body: SafeArea(
            child: Center(
              child: Container(
                color: Colors.grey[100],
                height: double.infinity,
                width: double.infinity,
                child: CircularIndicator(
                  indicatorColor: Colors.pink,
                  raduis: 100,
                  strokeWidth: 30,
                  isAnimated: true,
                  animationTime: 4,
                ),
              ),
            ),
          ),
        ));
  }
}

