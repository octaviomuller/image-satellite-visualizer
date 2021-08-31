import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:image_satellite_visualizer/models/client.dart';
import 'package:image_satellite_visualizer/screens/connection.dart';
import 'package:image_satellite_visualizer/screens/image_form/image_form.dart';
import 'package:image_satellite_visualizer/widgets/image_card.dart';
import 'package:image_satellite_visualizer/models/image_data.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  //Hive boxes
  Box? imageBox;
  Box? settingsBox;
  Box? selectedImagesBox;

  String searchTextController = "";

  List<ImageData> demoImages = [];

  //Tab controllers
  late TabController _tabController;
  late int _tabIndex = 0;

  @override
  void initState() {
    //Set boxes
    imageBox = Hive.box('imageBox');
    settingsBox = Hive.box('liquidGalaxySettings');
    selectedImagesBox = Hive.box('selectedImages');

    //Set tab controllers
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _tabIndex = _tabController.index;
      });
    });

    //Set Liquid Galaxy connection variable as false
    settingsBox?.put('connection', false);

    //Load demos
    loadJsonData();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        drawer: Drawer(
          child: Connection(cleanKmls),
        ),
        appBar: AppBar(
          title: Text('Liquid Galaxy - Image Satellite Visualizer'),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'My Images'),
              Tab(text: 'Demo Images'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      screenSize.width * 0.1,
                      screenSize.height * 0.04,
                      screenSize.width * 0.1,
                      screenSize.height * 0.01,
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() {
                        searchTextController = val;
                      }),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Search',
                      ),
                    ),
                  ),
                ),
                //My Images
                ValueListenableBuilder(
                  valueListenable: Hive.box('imageBox').listenable(),
                  builder: (context, box, widget) {
                    return Expanded(
                      flex: 8,
                      child: GridView.count(
                        children: imageCards(_runFilter(searchTextController)),
                        childAspectRatio: 0.8,
                        crossAxisSpacing: screenSize.width * 0.03,
                        crossAxisCount: 3,
                        // padding: EdgeInsetsDirectional.all(screenSize.width * 0.07),
                        padding: EdgeInsetsDirectional.fromSTEB(
                          screenSize.width * 0.07,
                          screenSize.height * 0.01,
                          screenSize.width * 0.07,
                          screenSize.height * 0.01,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            //Demo images
            GridView.count(
              children: imageCards(demoImages),
              childAspectRatio: 0.8,
              crossAxisSpacing: screenSize.width * 0.01,
              crossAxisCount: 3,
              // padding: EdgeInsetsDirectional.all(screenSize.width * 0.07),
              padding: EdgeInsetsDirectional.fromSTEB(
                  screenSize.width * 0.07,
                  screenSize.height * 0.01,
                  screenSize.width * 0.07,
                  screenSize.height * 0.01),
            ),
          ],
        ),
        floatingActionButton: _tabIndex == 0
            ? FloatingActionButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ImageForm(null, true)),
                ),
                tooltip: 'New image',
                child: Icon(Icons.add),
              )
            : Container(),
      ),
    );
  }

  //Callback function to select images
  void setSelection(ImageData image) {
    setState(() {
      image.selected = !image.selected;
    });
  }

  List<dynamic> _runFilter(String enteredKeyword) {
    List<dynamic> results = [];
    if (enteredKeyword.isEmpty) {
      //If the search field is empty or only contains white-space, we'll display all images
      results = imageBox!.values.toList();
    } else {
      results = imageBox!.values
          .toList()
          .where((image) =>
              image.title.toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
      //We use the toLowerCase() method to make it case-insensitive
    }

    return results;
  }

  //Set image cards from image data
  List<Widget> imageCards(List images) {
    List<Widget> list = [];

    for (ImageData image in images) {
      list.add(
        Container(
          padding: const EdgeInsets.all(8.0),
          child: ImageCard(image: image, callback: setSelection, demos: demoImages),
        ),
      );
    }
    return list;
  }

  //Set Image Data objects from json file for demos
  void loadJsonData() async {
    List<ImageData> images = [];
    var jsonText = await rootBundle.loadString('assets/json/demos.json');

    json.decode(jsonText).forEach((element) {
      List<Map<String, String>> colors = [];
      element['colors']
          .forEach((color) => colors.add(Map<String, String>.from(color)));

      images.add(
        ImageData(
          imagePath: element['imagePath'],
          title: element['title'],
          description: element['description'],
          coordinates: Map<String, String>.from(element['coordinates']),
          date: DateTime.parse(element['date']),
          layer: element['layer'],
          layerDescription: element['layerDescription'],
          colors: List<Map<String, String>>.from(colors),
          api: element['api'],
          demo: true,
          storageUrl: 'testeee', //TODO: Set storage url for demos
        ),
      );
    });

    setState(() {
      demoImages = images;
    });
  }

  //Clean all kmls from Liquid Galaxy
  void cleanKmls() {
    Client client = Client(
      ip: settingsBox?.get('ip'),
      username: settingsBox?.get('username'),
      password: settingsBox?.get('password'),
    );

    try {
      //Deselect all images
      setState(() {
        demoImages.forEach((element) {
          element.selected = false;
        });
        imageBox!.values.toList().forEach((element) {
          element.selected = false;
        });
      });

      //Remove all images from selected images box
      selectedImagesBox?.deleteAll(selectedImagesBox!.values);

      //Function that empties the kmls.txt
      client.cleanKML();
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Error cleaning KMLS, check connection"),
            content: Text(
              e.toString(),
            ),
          );
        },
      );
    }
  }
}
