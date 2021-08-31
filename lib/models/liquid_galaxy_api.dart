import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LiquidGalaxy {
  final String ip;
  final String earthPort;
  final String kmlPort;
  List images;

  LiquidGalaxy({
    required this.ip,
    required this.images,
    required this.earthPort,
    required this.kmlPort,
  });

  String getKmlUrl() {
    return "http://${this.ip}:${this.kmlPort}/kml/build/";
  }

  String getEarthUrl() {
    return "http://${this.ip}:${this.earthPort}/earth/kml/upload/";
  }

  String getFlyToUrl(longitude, latitude) {
    return "http://${this.ip}:${this.earthPort}/earth/query/flyto/$longitude/$latitude/1000000/0/0";
  }

  Future<void> sendToGalaxy(lastImage) async {
    List<Map<String, dynamic>> payload = [];

    //Set a ground overlay object for each image and add to payoad
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

    //Execute request and get the generated kml in string
    var kmlResponse = await http.post(
      Uri.parse(this.getKmlUrl()),
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

    //Check for errors to show in dialog
    if (kmlResponse.statusCode != 200) throw ("Error building kml");

    //Create a kml local file
    Directory documentDirectory = await getApplicationDocumentsDirectory();
    File file = new File(
        path.join(documentDirectory.path, 'image_satellite_visualizer.kml'));
    file.writeAsStringSync(kmlResponse.body, encoding: utf8);

    var dio = Dio();

    //Create a form data containing the kml
    FormData formData = new FormData.fromMap({
      "kml": await MultipartFile.fromFile(file.path,
          filename: "image_satellite_visualizer.kml"),
    });

    //Execute request with file attached
    var earthResponse = await dio.post(this.getEarthUrl(), data: formData);

    //Check for errors to show in dialog
    if (earthResponse.statusCode != 200) throw ("Error uploading kml");

    if (lastImage.selected) {
      var flyToResponse = await http.get(
        Uri.parse(
          this.getFlyToUrl(
            midpoint(lastImage.coordinates['minLon'],
                lastImage.coordinates['maxLon']),
            midpoint(
              lastImage.coordinates['minLat'],
              lastImage.coordinates['maxLat'],
            ),
          ),
        ),
      );

      if (flyToResponse.statusCode != 200) throw ("Error flying to");
    }
  }

  String midpoint(String? a, String? b) =>
      ((double.parse(a!) + double.parse(b!)) / 2).toString();
}
