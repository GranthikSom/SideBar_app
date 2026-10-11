import 'package:flutter/material.dart';


class VerticalWidget extends StatefulWidget {
  const VerticalWidget({super.key});

  @override
  State<VerticalWidget> createState() => _VerticalWidgetState();
}

class _VerticalWidgetState extends State<VerticalWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,  
        width: 100,
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