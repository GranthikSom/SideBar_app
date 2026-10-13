import 'package:flutter/material.dart';
import 'package:sidebar/config/config.dart';

import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  final windowOptions = WindowOptions(
    size: Size(sizeConfig.widgetWidth, double.infinity),
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );
 
  windowManager.waitUntilReadyToShow(
    windowOptions,
    () async {
      await windowManager.setAsFrameless();
      await windowManager.setHasShadow(false);
      await windowManager.setResizable(false);
      await windowManager.setMovable(false);

      await windowManager.setAlwaysOnTop(true);

      await windowManager.setVisibleOnAllWorkspaces(
        true,
        visibleOnFullScreen: true,
      );

      await windowManager.setAlignment(Alignment.centerLeft);

      await windowManager.show(inactive: true);
    },
  );

  
}
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