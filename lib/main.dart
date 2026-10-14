import 'package:flutter/material.dart';
import 'package:sidebar/canvas/widget/mainWidget.dart';
import 'package:sidebar/config/config.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  final windowOptions = WindowOptions(
    size: Size(sizeConfig.widgetWidth, sizeConfig.widgetHeight),
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

      await windowManager.setAlignment(WidgetAlignment.Left);

      await windowManager.show(inactive: true);
    },
  );

runApp(const MyApp());
  
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainWidget(),
    );
  }
}