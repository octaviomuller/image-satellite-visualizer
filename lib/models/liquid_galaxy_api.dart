import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:image_satellite_visualizer/models/image_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LiquidGalaxy {
  final String url;
  List<ImageData> images;

  LiquidGalaxy({
    required this.url,
    required this.images,
  });

  Future<void> sendToGalaxy() async {
    try {
      List<Map<String, dynamic>> payload = [];

    this.images.forEach(
      (element) {
        payload.add(
          <String, dynamic>{
            "name": element.title,
            "type": "groundOverlay",
            "data": {
              "coordinates": {
                "north": element.coordinates['minLat'],
                "south": element.coordinates['maxLat'],
                "east": element.coordinates['minLon'],
                "west": element.coordinates['maxLon']
              },
              "altitude": "300",
              "altitudeMode": "clamptoGround",
              "rotation": "0",
              "url": element.storageUrl
            },
            "lookAt": element.lookAt()
          },
        );
      },
    );

    var response = await http.post(
      Uri.parse("$url:5431/kml/build"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        <String, dynamic>{
          "name": "Image Satellite Visualizer",
          "folderName": "Images",
          "elements": payload
        },
      ),
    );

    print('repsonse: ${response.body}');

    Directory documentDirectory = await getApplicationDocumentsDirectory();
    File file = new File(
        path.join(documentDirectory.path, 'image_satellite_visualizer.kml'));
    file.writeAsStringSync(response.body, encoding: utf8);

    var dio = Dio();

    FormData formData = new FormData.fromMap({
      "kml":  await MultipartFile.fromFile(file.path, filename: "image_satellite_visualizer.kml"),
    });
    var cu = await dio.post("$url:5430/earth/kml/upload", data: formData);
    print('cu: $cu');
    } catch (e) {
      print('error sending: $e');
    }
  }
}
