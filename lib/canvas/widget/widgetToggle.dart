import 'package:flutter/material.dart';
import 'package:sidebar/canvas/widget/vertical.dart';



class Widgettoggle extends StatefulWidget {
  const Widgettoggle({super.key});

  @override
  State<Widgettoggle> createState() => _WidgettoggleState();
}


class _WidgettoggleState extends State<Widgettoggle> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VerticalWidget(),
      

    );
  }
}