import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_satellite_visualizer/models/resolution.dart';

class FirstStep extends StatefulWidget {
  final coordiantesCallback;
  final Map<String, TextEditingController> coordinatesTextControllers;

  final resolutionCallback;
  final Resolution resolution;

  final cloudCoverageCallback;
  final double cloudCoverage;

  const FirstStep({
    required this.coordinatesTextControllers,
    required this.coordiantesCallback,
    required this.resolution,
    required this.resolutionCallback,
    required this.cloudCoverageCallback,
    required this.cloudCoverage,
    Key? key,
  }) : super(key: key);

  @override
  _FirstStepState createState() => _FirstStepState();
}

class _FirstStepState extends State<FirstStep> {
  //Google Maps variables
  Completer<GoogleMapController> _controller = Completer();
  late BitmapDescriptor pinLocationIcon;
  static final CameraPosition _initial = CameraPosition(
    target: LatLng(-23.36, -46.84),
    zoom: 1.0,
  );

  //Locations variables
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  Map<PolygonId, Polygon> polygons = <PolygonId, Polygon>{};
  int _markerIdCounter = 1;
  Resolution mapsResolution = Resolution.km1;
  double cloudCoverage = 0;

  List<bool> isSelected = [false, true];

  @override
  void initState() {
    //Changes the deafult Google Marker icon
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 2.5), 'assets/marker.png')
        .then((onValue) {
      pinLocationIcon = onValue;
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    return Container(
      height: screenSize.height * 0.648,
      width: screenSize.width * 0.6,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location',
                          style: TextStyle(fontSize: screenSize.height * 0.05),
                        ),
                        Text(
                          'Select the location that you want to query',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: screenSize.height * 0.025,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                              onPressed: _resetMarkers,
                              icon: Icon(Icons.refresh),
                              iconSize: screenSize.width * 0.03,
                              splashRadius: screenSize.width * 0.025,
                            ),
                  ],
                ),
                Spacer(),
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: screenSize.height * 0.02),
                        child: Text(
                          'Resolution',
                          style: TextStyle(fontWeight: FontWeight.w300),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenSize.height * 0.01),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5.0)),
                            contentPadding: EdgeInsets.all(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: mapsResolution.toString(),
                              isDense: true,
                              isExpanded: true,
                              items: [
                                DropdownMenuItem(
                                  child: Text("250m"),
                                  value: Resolution.m250.toString(),
                                ),
                                DropdownMenuItem(
                                  child: Text("500m"),
                                  value: Resolution.m500.toString(),
                                ),
                                DropdownMenuItem(
                                  child: Text("1km"),
                                  value: Resolution.km1.toString(),
                                ),
                                DropdownMenuItem(
                                  child: Text("5km"),
                                  value: Resolution.km5.toString(),
                                ),
                                DropdownMenuItem(
                                  child: Text("10km"),
                                  value: Resolution.km10.toString(),
                                ),
                              ],
                              onChanged: (newValue) {
                                Resolution newResolution = Resolution.km1;
                                switch (newValue) {
                                  case "Resolution.m250":
                                    newResolution = Resolution.m250;
                                    break;
                                  case "Resolution.m500":
                                    newResolution = Resolution.m500;
                                    break;
                                  case "Resolution.km1":
                                    newResolution = Resolution.km1;
                                    break;
                                  case "Resolution.km5":
                                    newResolution = Resolution.km5;
                                    break;
                                  case "Resolution.km10":
                                    newResolution = Resolution.km10;
                                    break;
                                }
                                setState(() {
                                  mapsResolution = newResolution;
                                });
                                widget.resolutionCallback(newResolution);
                              },
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: screenSize.height * 0.02),
                        child: Text(
                          'First pair of coordinates',
                          style: TextStyle(fontWeight: FontWeight.w300),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenSize.height * 0.01),
                              child: TextField(
                                keyboardType: TextInputType.number,
                                controller: widget.coordinatesTextControllers[
                                    'lat1Controller'],
                                onEditingComplete: () => _setMarker(
                                    widget.coordinatesTextControllers[
                                        'lat1Controller'],
                                    widget.coordinatesTextControllers[
                                        'lon1Controller'],
                                    0),
                                decoration: new InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(),
                                  ),
                                  hintText: 'Latitude',
                                  labelText: 'Latitude',
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenSize.height * 0.01),
                              child: TextField(
                                keyboardType: TextInputType.number,
                                controller: widget.coordinatesTextControllers[
                                    'lon1Controller'],
                                onEditingComplete: () => _setMarker(
                                    widget.coordinatesTextControllers[
                                        'lat1Controller'],
                                    widget.coordinatesTextControllers[
                                        'lon1Controller'],
                                    0),
                                decoration: new InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(),
                                  ),
                                  hintText: 'Longitude',
                                  labelText: 'Longitude',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: screenSize.height * 0.02),
                        child: Text(
                          'Second pair of coordinates',
                          style: TextStyle(fontWeight: FontWeight.w300),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenSize.height * 0.01),
                              child: TextField(
                                keyboardType: TextInputType.number,
                                controller: widget.coordinatesTextControllers[
                                    'lat2Controller'],
                                onEditingComplete: () => _setMarker(
                                    widget.coordinatesTextControllers[
                                        'lat2Controller'],
                                    widget.coordinatesTextControllers[
                                        'lon2Controller'],
                                    1),
                                decoration: new InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(),
                                  ),
                                  hintText: 'Latitude',
                                  labelText: 'Latitude',
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenSize.height * 0.01),
                              child: TextField(
                                keyboardType: TextInputType.number,
                                controller: widget.coordinatesTextControllers[
                                    'lon2Controller'],
                                onEditingComplete: () => _setMarker(
                                    widget.coordinatesTextControllers[
                                        'lat2Controller'],
                                    widget.coordinatesTextControllers[
                                        'lon2Controller'],
                                    1),
                                decoration: new InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(),
                                  ),
                                  hintText: 'Longitude',
                                  labelText: 'Longitude',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: screenSize.height * 0.02),
                  child: Text(
                    'Cloud Coverage: ${this.cloudCoverage.toString()}',
                    style: TextStyle(fontWeight: FontWeight.w300),
                  ),
                ),
                Slider(
                  value: cloudCoverage,
                  min: 0,
                  max: 100,
                  onChanged: (double value) {
                    setState(() {
                      cloudCoverage = double.parse(value.toStringAsFixed(1));
                    });
                  },
                ),
                Spacer(),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: screenSize.height * 0.02),
              child: Stack(
                children: [
                  GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: _initial,
                    markers: Set<Marker>.of(markers.values),
                    polygons: Set<Polygon>.of(polygons.values),
                    onTap: (LatLng position) =>
                        isSelected[0] ? _addMarker(position) : null,
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      color: Colors.grey[50],
                      child: ToggleButtons(
                        children: <Widget>[
                          Icon(Icons.crop_square_outlined),
                          Icon(Icons.map),
                        ],
                        onPressed: (int index) {
                          setState(() {
                            for (int buttonIndex = 0;
                                buttonIndex < isSelected.length;
                                buttonIndex++) {
                              if (buttonIndex == index) {
                                isSelected[buttonIndex] = true;
                              } else {
                                isSelected[buttonIndex] = false;
                              }
                            }
                          });
                        },
                        isSelected: isSelected,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setMarker(latController, lonController, markerIdReference) {
    if (latController.text == "" || lonController.text == "") return;

    final MarkerId markerId = MarkerId('marker_id_$markerIdReference');
    final LatLng position = LatLng(
        double.parse(latController.text), double.parse(lonController.text));
    final Marker marker = Marker(
      icon: pinLocationIcon,
      markerId: markerId,
      position: position,
      rotation: 0,
    );

    setState(() {
      _markerIdCounter++;
      markers[markerId] = marker;
    });

    _myPolygon(
      markers.values.elementAt(0).position.latitude,
      markers.values.elementAt(0).position.longitude,
      markers.values.elementAt(1).position.latitude,
      markers.values.elementAt(1).position.longitude,
    );
  }

  void _addMarker(LatLng position) async {
    final int markerCount = markers.length;

    if (markerCount == 2) {
      return;
    }

    final String markerIdVal = 'marker_id_$_markerIdCounter';
    _markerIdCounter++;
    final MarkerId markerId = MarkerId(markerIdVal);

    final Marker marker = Marker(
      icon: pinLocationIcon,
      markerId: markerId,
      position: position,
      rotation: 0,
    );

    setState(() {
      markers[markerId] = marker;

      if (markerCount == 0) {
        widget.coordinatesTextControllers['lat1Controller']?.text =
            markers.values.elementAt(0).position.latitude.toString();
        widget.coordinatesTextControllers['lon1Controller']?.text =
            markers.values.elementAt(0).position.longitude.toString();
      } else {
        widget.coordinatesTextControllers['lat2Controller']?.text =
            markers.values.elementAt(1).position.latitude.toString();
        widget.coordinatesTextControllers['lon2Controller']?.text =
            markers.values.elementAt(1).position.longitude.toString();

        _myPolygon(
          markers.values.elementAt(0).position.latitude,
          markers.values.elementAt(0).position.longitude,
          markers.values.elementAt(1).position.latitude,
          markers.values.elementAt(1).position.longitude,
        );
      }
    });
  }

  void _myPolygon(double lat1, double lon1, double lat2, double lon2) {
    final PolygonId polygonId = PolygonId('polygon');

    final List<LatLng> polygonCoords = [];
    polygonCoords.add(LatLng(lat1, lon1));
    polygonCoords.add(LatLng(lat1, lon2));
    polygonCoords.add(LatLng(lat2, lon2));
    polygonCoords.add(LatLng(lat2, lon1));

    final Polygon polygon = Polygon(
      polygonId: polygonId,
      points: polygonCoords,
      strokeColor: Color.fromARGB(50, 255, 0, 0),
      fillColor: Color.fromARGB(50, 255, 0, 0),
    );

    setState(() {
      polygons[polygonId] = polygon;
    });
  }

  void _resetMarkers() {
    setState(() {
      widget.coordinatesTextControllers['lat1Controller']?.text = "";
      widget.coordinatesTextControllers['lon1Controller']?.text = "";
      widget.coordinatesTextControllers['lat2Controller']?.text = "";
      widget.coordinatesTextControllers['lon2Controller']?.text = "";

      markers = <MarkerId, Marker>{};
      polygons = <PolygonId, Polygon>{};
    });
  }
}
