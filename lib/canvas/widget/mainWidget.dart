import 'package:flutter/material.dart';
import 'package:sidebar/config/config.dart';

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: sizeConfig.widgetHeight,  
        width: sizeConfig.widgetWidth,
        decoration: BoxDecoration(
          //borderRadius: BorderRadius.circular(10),
          
          color: Colors.black,
        ),
        
        child: Row(
          children: [
            Container(
              height: 100,
              color: Colors.red,)],
          
        ),
      )
     
    );
  }
}