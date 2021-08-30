import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_satellite_visualizer/widgets/layer_info.dart';

class FilterStep extends StatefulWidget {
  final callback;
  final dateCallback;
  final String layer;
  final String selectedApi;
  final DateTime date;

  const FilterStep({
    required this.layer,
    required this.date,
    required this.callback,
    required this.selectedApi,
    required this.dateCallback,
    Key? key,
  }) : super(key: key);

  @override
  _FilterStepState createState() => _FilterStepState();
}

class _FilterStepState extends State<FilterStep> {
  List<Item> _data = [];

  @override
  void initState() {
    loadJsonData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          flex: 6,
          child: Container(
            height: screenSize.height * 0.65,
            padding: EdgeInsets.symmetric(horizontal: screenSize.height * 0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  'Layer',
                  style: TextStyle(fontSize: screenSize.height * 0.05),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: screenSize.height * 0.01),
                  child: Text(
                    'Select the layer that you want to query',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: screenSize.height * 0.025,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: _buildPanel(screenSize),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            height: screenSize.height * 0.65,
            padding: EdgeInsets.symmetric(horizontal: screenSize.height * 0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  'Date',
                  style: TextStyle(fontSize: screenSize.height * 0.05),
                ),
                Text(
                  'Select the date that you want to query',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: screenSize.height * 0.025,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(screenSize.height * 0.01),
                        child: Center(
                          child: Text(
                            '${widget.date.year}/${widget.date.month}/${widget.date.day}',
                            style: TextStyle(
                              fontSize: screenSize.height * 0.03,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: OutlinedButton(
                          child: Text('GET DATE'),
                          onPressed: () async => await _selectDate(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPanel(Size screenSize) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenSize.height * 0.01,
        vertical: screenSize.height * 0.03,
      ),
      child: ExpansionPanelList(
        expansionCallback: (int index, bool isExpanded) {
          setState(() {
            _data[index].isExpanded = !isExpanded;
          });
        },
        children: _data.map<ExpansionPanel>((Item item) {
          return ExpansionPanel(
            headerBuilder: (BuildContext context, bool isExpanded) {
              return ListTile(
                title: Text(
                  item.title,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                ),
              );
            },
            body: Column(
              children: List<Widget>.generate(
                item.components.length,
                (index) => InkWell(
                  onTap: () {
                    print('api: ${item.components[index]['api']}');
                    widget.callback(
                      item.components[index]['value'],
                      item.components[index]['shortName'],
                      item.components[index]['description'],
                      item.components[index]['colors'],
                      item.components[index]['api'],
                    );
                  },
                  child: ListTile(
                    title: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(item.components[index]['name']!),
                        Spacer(),
                        Padding(
                          padding: EdgeInsets.all(screenSize.height * 0.008),
                          child: IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return LayerInfo(item.components[index]);
                                },
                              );
                            },
                            icon: Icon(Icons.info),
                            splashRadius: screenSize.height * 0.035,
                          ),
                        ),
                      ],
                    ),
                    tileColor: item.components[index]['value'] == widget.layer
                        ? Colors.grey[200]
                        : Colors.grey[50],
                  ),
                ),
              ),
            ),
            isExpanded: item.isExpanded,
          );
        }).toList(),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.date,
      firstDate: DateTime(2015, 8),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != widget.date) widget.dateCallback(picked);
  }

  void loadJsonData() async {
    List<Item> layers = [];

    var jsonText = await rootBundle.loadString('assets/json/layers.json');
    json.decode(jsonText).forEach((element) {
      layers.add(
        Item(
          title: element["title"],
          components: element["components"],
        ),
      );
    });

    setState(() {
      _data = layers;
    });
  }
}

class Item {
  final String title;
  final List<dynamic> components;
  bool isExpanded = false;

  Item({
    required this.title,
    required this.components,
  });
}
