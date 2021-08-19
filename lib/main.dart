import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_satellite_visualizer/models/image_data.dart';
import 'package:image_satellite_visualizer/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  //Hive initialization
  await Hive.initFlutter();

  //Image Data model adapter registration
  Hive.registerAdapter(ImageDataAdapter());

  //Opening all boxes need for the project
  await Hive.openBox('imageBox');
  await Hive.openBox('liquidGalaxySettings');
  await Hive.openBox('selectedImages');

  //Firebase initialization
  Firebase.initializeApp();

  //Set app for landscape only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Galaxy - Image Satellite Visualizer',
      theme: ThemeData(
        primaryColor: Colors.blueGrey[700],
        accentColor: Colors.tealAccent[700],
      ),
      home: SplashScreen(true),
    );
  }
}
