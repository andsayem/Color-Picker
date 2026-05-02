import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'screens/camera_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final cameras = await availableCameras();
    runApp(MyApp(cameras: cameras));
  } catch (e) {
    runApp(const CameraErrorApp());
  }
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Color Picker Camera',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: CameraScreen(cameras: cameras),
    );
  }
}

/// 🔥 Fallback UI if camera fails
class CameraErrorApp extends StatelessWidget {
  const CameraErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Camera not available",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
