import 'package:flutter/material.dart';
import 'package:sidebar/canvas/widget/vertical.dart';
import 'package:sidebar/canvas/widget/widgetToggle.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
       home : Widgettoggle(),
     // home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

