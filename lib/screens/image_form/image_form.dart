import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_satellite_visualizer/models/image_data.dart';
import 'package:image_satellite_visualizer/models/image_request.dart';
import 'package:image_satellite_visualizer/models/resolution.dart';
import 'package:image_satellite_visualizer/screens/image_form/steps/final_step.dart';
import 'package:image_satellite_visualizer/screens/image_form/steps/first_step.dart';
import 'package:image_satellite_visualizer/screens/image_form/steps/second_step.dart';
import 'package:geodesy/geodesy.dart' as geodesy;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import 'dart:math';
import 'dart:io';

class ImageForm extends StatefulWidget {
  final ImageData? imageData;
  final bool newImage;
  const ImageForm(this.imageData, this.newImage, {Key? key}) : super(key: key);

  @override
  _ImageFormState createState() => _ImageFormState();
}

class _ImageFormState extends State<ImageForm> {
  RegExp regex = RegExp("&URL=(.*)");

  //Hive box
  Box? imageBox;

  //Package to handle coordinates to distances convertions
  final geodesy.Geodesy geodesyLib = geodesy.Geodesy();

  //Firebase storage instance
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  int _currentStep = 0;

  //Image Data controller
  String selectedApi = "Nasa";
  Map<String, TextEditingController> coordinates = {
    "lat1Controller": TextEditingController(),
    "lon1Controller": TextEditingController(),
    "lat2Controller": TextEditingController(),
    "lon2Controller": TextEditingController(),
  };
  double cloudCoverage = 10.0;
  DateTime date = DateTime.parse('2021-01-15');
  String layer = "";
  String layerShortName = "";
  String layerDescription = "";
  List<dynamic> colors = [{}];
  String? imagePath;
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  Map<String, String> coordinatesMap = {};
  Resolution resolution = Resolution.km1;

  @override
  void initState() {
    super.initState();

    if (widget.imageData != null) {
      coordinates["lat1Controller"]?.text =
          widget.imageData!.coordinates['minLat'].toString();
      coordinates["lon1Controller"]?.text =
          widget.imageData!.coordinates['minLon'].toString();
      coordinates["lat2Controller"]?.text =
          widget.imageData!.coordinates['maxLat'].toString();
      coordinates["lon2Controller"]?.text =
          widget.imageData!.coordinates['maxLon'].toString();
      nameController.text = widget.imageData!.title;
      descriptionController.text = widget.imageData!.description;
      date = widget.imageData!.date;
      _currentStep = 1;
    }

    //Set Hive box
    imageBox = Hive.box('imageBox');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('New Image'),
        leading: BackButton(color: Colors.white),
      ),
      body: Theme(
        data: ThemeData(
          colorScheme:
              ColorScheme.light(primary: Theme.of(context).accentColor),
        ),
        //TODO: Change stepper
        child: Stepper(
          type: StepperType.horizontal,
          physics: ScrollPhysics(),
          currentStep: _currentStep,
          onStepTapped: (step) => tapped(step),
          onStepContinue: continued,
          onStepCancel: cancel,
          steps: <Step>[
            //Location and date step
            Step(
              title: new Text('Location'),
              content: FirstStep(
                coordinatesTextControllers: coordinates,
                coordiantesCallback: setCoordinates,
                resolution: resolution,
                resolutionCallback: setResolution,
                cloudCoverage: cloudCoverage,
                cloudCoverageCallback: setCloudCoverage,
              ),
              isActive: _currentStep >= 0 && widget.imageData == null,
              state:
                  _currentStep >= 1 ? StepState.complete : StepState.disabled,
            ),
            //Layer step
            Step(
              title: new Text('Layers and Date'),
              content: FilterStep(
                date: date,
                layer: layer,
                dateCallback: setDate,
                callback: setLayer,
                selectedApi: selectedApi,
              ),
              isActive: _currentStep >= 0,
              state:
                  _currentStep >= 2 ? StepState.complete : StepState.disabled,
            ),
            //Name and description step
            Step(
              title: new Text('Final'),
              content:
                  FinalStep(nameController, descriptionController, imagePath),
              isActive: _currentStep >= 0,
              state:
                  _currentStep >= 3 ? StepState.complete : StepState.disabled,
            ),
          ],
        ),
      ),
    );
  }

  //Step tap event
  tapped(int step) {
    //Set imagePath to null if leaving final step
    if (step != 2) imagePath = null;

    if (step == 0) {
      if (widget.imageData != null) return;
    }

    setState(() => _currentStep = step);
  }

  //Step continue event
  continued() {
    //Increasing step if not in the final one
    if (_currentStep < 2) {
      //First step validation
      if (_currentStep == 0) {
        //Check coordinates
        coordinatesCheck()
            //Check if size is respecting the boundaries limits
            ? sizeCheck()
                ? setState(() => _currentStep += 1)
                : showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content:
                            Text('Height/Width must not be greater than 3000'),
                      );
                    })
            : showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: Text('Coordinates are required'),
                  );
                });
      }
      //Third step validation
      else if (_currentStep == 1) {
        layer.isNotEmpty
            ? setState(() {
                try {
                  createRequest();
                  _currentStep += 1;
                } catch (e) {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: Text(e.toString()),
                        );
                      });
                }
              })
            : showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: Text('Layer is required'),
                  );
                });
      }
    }
    //Final step validation
    else {
      imagePath != null
          ? infoCheck()
              ? createImage()
              : showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: Text('Name/Description is required'),
                    );
                  })
          : showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: Text('Await for image'),
                );
              });
    }
  }

  //Step cancel event
  cancel() {
    if (_currentStep > 0) {
      if (_currentStep == 1) {
        if (widget.imageData != null) return;
      }
      //Set imagePath to null if leaving final step
      if (_currentStep == 2) imagePath = null;

      setState(() => _currentStep -= 1);
    } else {
      //If in first step goes back to main screen
      Navigator.of(context).pop();
    }
  }

  //Create image request
  void createRequest() async {
    //Set coordinates to minimun and maximum
    var minLat = min(double.parse(coordinates['lat1Controller']!.text),
        double.parse(coordinates['lat2Controller']!.text));
    var maxLat = max(double.parse(coordinates['lat1Controller']!.text),
        double.parse(coordinates['lat2Controller']!.text));
    var minLon = min(double.parse(coordinates['lon1Controller']!.text),
        double.parse(coordinates['lon2Controller']!.text));
    var maxLon = max(double.parse(coordinates['lon1Controller']!.text),
        double.parse(coordinates['lon2Controller']!.text));

    //Set bounding box
    Map<String, double> bbox = {
      'lat1': minLat,
      'lat2': maxLat,
      'lon1': minLon,
      'lon2': maxLon,
    };

    //Create a request object
    ImageRequest request = new ImageRequest(
      layers: [layer],
      time: '2020-03-30',
      bbox: bbox,
      resolution: resolution,
      cloudCoverage: cloudCoverage,
    );

    //Create request url
    String url;
    if (selectedApi == "Nasa") {
      url = request.getNasaRequestUrl();
      print(request.getNasaRequestUrl());
    } else if (selectedApi == "SentinelHub") {
      url = request.getSentinelHubRequestUrl();
      print(request.getSentinelHubRequestUrl());
    } else {
      var match = regex.firstMatch(request.getCopernicusRequestUrl())?.group(1);
      url = match!;
      print(match);
    }

    //TODO: Create http request model
    //Perfoms the http request
    var response = await http.get(Uri.parse(url));

    //Successful request
    if (response.statusCode == 200) {
      //Create image local file
      Directory documentDirectory = await getApplicationDocumentsDirectory();
      File file = new File(path.join(documentDirectory.path,
          '${DateTime.now().millisecondsSinceEpoch}.jpeg'));
      file.writeAsBytesSync(response.bodyBytes);

      setState(() {
        imagePath = file.path;
        coordinatesMap = {
          'minLat': minLat.toString(),
          'minLon': minLon.toString(),
          'maxLat': maxLat.toString(),
          'maxLon': maxLon.toString(),
        };
      });
    }
    //Unsuccessful request
    else {
      setState(() {
        _currentStep--;
      });
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text('Error fetching image'),
          );
        },
      );
    }
  }

  //Create Image Data
  void createImage() async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    //Add image to box
    if (widget.newImage) {
      //Create Image Data object
      var imageData = ImageData(
        imagePath: imagePath!,
        title: nameController.text,
        description: descriptionController.text,
        coordinates: coordinatesMap,
        api: selectedApi,
        date: date,
        layer: layerShortName,
        layerDescription: layerDescription,
        colors: colors,
        demo: false,
        storageUrl: await uploadFile(imagePath!, nameController.text),
      );
      imageBox?.add(imageData);
    } else {
      widget.imageData!.imagePath = imagePath!;
      widget.imageData!.title = nameController.text;
      widget.imageData!.description = descriptionController.text;
      widget.imageData!.coordinates = coordinatesMap;
      widget.imageData!.api = selectedApi;
      widget.imageData!.date = date;
      widget.imageData!.layer = layerShortName;
      widget.imageData!.layerDescription = layerDescription;
      widget.imageData!.colors = colors;
      widget.imageData!.demo = false;
      widget.imageData!.storageUrl =
          await uploadFile(imagePath!, nameController.text);
    }

    //TODO: Search for popUntil
    Navigator.pop(context);
    Navigator.pop(context);
  }

  //Upload image to Firebase storage
  Future<String> uploadFile(String filePath, String title) async {
    File file = File(filePath);

    try {
      //Upload file to storage
      await firebase_storage.FirebaseStorage.instance
          .ref('images/$title.png')
          .putFile(file);
    } catch (e) {
      print('error storage: $e');
    }

    //Returns image access url
    return "https://storage.googleapis.com/image-satellite-visualizer-lg.appspot.com/images/$title.png";
  }

  //API callback
  void setApi(String api) {
    setState(() {
      selectedApi = api;
    });
  }

  //Coordinates callback
  void setCoordinates(Map<MarkerId, Marker> markers) {
    setState(() {
      coordinates['lat1Controller']?.text =
          markers.values.elementAt(0).position.latitude.toString();
      coordinates['lon1Controller']?.text =
          markers.values.elementAt(0).position.longitude.toString();
      coordinates['lat2Controller']?.text =
          markers.values.elementAt(1).position.latitude.toString();
      coordinates['lon2Controller']?.text =
          markers.values.elementAt(1).position.longitude.toString();
    });
  }

  //Resolution callback
  void setResolution(Resolution newResolution) {
    setState(() {
      resolution = newResolution;
    });
  }

  //Date callback
  void setDate(DateTime newDate) {
    setState(() {
      date = newDate;
    });
  }

  //Layer callback
  void setLayer(
      String incomingLayer,
      String incomingShortName,
      String incomingLayerDescription,
      List<dynamic> incomingColors,
      String api) {
    setState(() {
      layer = incomingLayer;
      layerShortName = incomingShortName;
      layerDescription = incomingLayerDescription;
      colors = incomingColors;
      selectedApi = api;
    });
  }

  //Cloud coverage callback
  void setCloudCoverage(double incomingCloudCoverage) {
    setState(() {
      cloudCoverage = incomingCloudCoverage;
    });
  }

  //Get width and height of image in kilometers
  Map<String, String> getSize() {
    int height = (geodesyLib.distanceBetweenTwoGeoPoints(
              geodesy.LatLng(double.parse(coordinates['lat1Controller']!.text),
                  double.parse(coordinates['lon1Controller']!.text)),
              geodesy.LatLng(double.parse(coordinates['lat2Controller']!.text),
                  double.parse(coordinates['lon1Controller']!.text)),
            ) /
            1000)
        .round();
    int width = (geodesyLib.distanceBetweenTwoGeoPoints(
              geodesy.LatLng(double.parse(coordinates['lat1Controller']!.text),
                  double.parse(coordinates['lon1Controller']!.text)),
              geodesy.LatLng(double.parse(coordinates['lat1Controller']!.text),
                  double.parse(coordinates['lon2Controller']!.text)),
            ) /
            1000)
        .round();
    return {
      'height': height.toString(),
      'width': width.toString(),
    };
  }

  //Check if width or height is greater then 3000
  bool sizeCheck() {
    return double.parse(getSize()['width']!) < 3000 ||
            double.parse(getSize()['height']!) < 3000
        ? true
        : false;
  }

  //Coordoninates validation
  bool coordinatesCheck() {
    for (var element in coordinates.values) {
      if (element.text.isEmpty) return false;
    }
    return true;
  }

  //Name/description validation
  bool infoCheck() {
    if (nameController.text.isEmpty || descriptionController.text.isEmpty)
      return false;
    return true;
  }
}
