import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_satellite_visualizer/models/client.dart';
import 'package:image_satellite_visualizer/screens/splash_screen.dart';

class Connection extends StatefulWidget {
  final callback;
  const Connection(this.callback, {Key? key}) : super(key: key);

  @override
  _ConnectionState createState() => _ConnectionState();
}

class _ConnectionState extends State<Connection> {
  //Hive boxes
  Box? imageBox;
  Box? settingsBox;
  Box? selectedImagesBox;

  //Ubuntu 16 text controllers
  TextEditingController ipTextController =
      TextEditingController(text: '192.168.0.156');
  TextEditingController usernameTextController =
      TextEditingController(text: 'lg');
  TextEditingController passwordTextController =
      TextEditingController(text: 'lq');

  //Ubuntu 18/20 text controllers
  TextEditingController urlIpTextController =
      TextEditingController(text: '192.168.0.156');
  TextEditingController urlKmlPortTextController =
      TextEditingController(text: '5431');
  TextEditingController urlEarthPortTextController =
      TextEditingController(text: '5430');

  //Drawer layout
  bool liquidGalaxySetup = false;

  //Toggle button value
  List<bool> isSelected = [true, false];

  @override
  void initState() {
    //Set boxes
    imageBox = Hive.box('imageBox');
    settingsBox = Hive.box('liquidGalaxySettings');
    selectedImagesBox = Hive.box('selectedImages');

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    return SafeArea(
      //TODO: Create animations
      //Drawer layout changer
      child: liquidGalaxySetup
          ? Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenSize.height * 0.015,
                    horizontal: screenSize.height * 0.015,
                  ),
                  //Change setup method
                  child: ToggleButtons(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    children: <Widget>[
                      Text('  Ubuntu 16  '),
                      Text('  Ubuntu 18/20  '),
                    ],
                    //Changes toggled
                    onPressed: (int index) {
                      setState(
                        () {
                          for (int buttonIndex = 0;
                              buttonIndex < isSelected.length;
                              buttonIndex++) {
                            if (buttonIndex == index) {
                              isSelected[buttonIndex] = true;
                            } else {
                              isSelected[buttonIndex] = false;
                            }
                          }
                        },
                      );
                    },
                    isSelected: isSelected,
                  ),
                ),
                //Changes setup layout
                isSelected[0]
                    ? inputController('IP', ipTextController, screenSize, false)
                    : inputController('IP', urlIpTextController, screenSize, false),
                isSelected[0]
                    ? inputController('Username', usernameTextController, screenSize, false)
                    : inputController('KML Port', urlIpTextController, screenSize, false),
                isSelected[0]
                    ? inputController('Password', passwordTextController, screenSize, true)
                    : inputController('Earth Port', urlEarthPortTextController, screenSize, false),
                Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenSize.height * 0.015,
                    horizontal: screenSize.height * 0.015,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: Text(
                          "CANCEL",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        onPressed: () => setState(() {
                          liquidGalaxySetup = false;
                        }),
                      ),
                      TextButton(
                        child: Text(
                          "SET",
                          style:
                              TextStyle(color: Theme.of(context).accentColor),
                        ),
                        onPressed: () async {
                          //TODO: Create model for liquidgalaxy setup
                          //Set setup variables in settings box

                          //Ubuntu 16 setup
                          if (isSelected[0]) {
                            settingsBox?.put('newLiquidGalaxy', false);
                            settingsBox?.put('ip', ipTextController.text);
                            settingsBox?.put(
                                'username', usernameTextController.text);
                            settingsBox?.put(
                                'password', passwordTextController.text);
                          }
                          //Ubuntu 18/20 setup
                          else {
                            settingsBox?.put('newLiquidGalaxy', true);
                            settingsBox?.put('ip', urlIpTextController.text);
                            settingsBox?.put(
                                'kmlPort', urlKmlPortTextController.text);
                            settingsBox?.put(
                                'earthPort', urlEarthPortTextController.text);
                          }

                          //TODO: Create global client
                          //Create client object
                          Client client = Client(
                            ip: settingsBox?.get('ip'),
                            username: settingsBox?.get('username'),
                            password: settingsBox?.get('password'),
                          );

                          try {
                            //Set connection values
                            await client.checkConnection();
                            settingsBox?.put('connection', true);

                            //TODO: Check if it's necessary in this fork
                            //Send logos for Liquid Galaxy
                            client.sendLogos();

                            //Changes drawer layout back
                            setState(() {
                              liquidGalaxySetup = false;
                            });
                          } catch (e) {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title:
                                      Text("Error on liquid galaxy connection"),
                                  content: Text(
                                    'Check connection settings',
                                  ),
                                );
                              },
                            );

                            //Set connection values
                            settingsBox?.put('connection', false);
                          }
                        },
                      ),
                    ],
                  ),
                )
              ],
            )
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                //Send to about screen
                ListTile(
                  title: const Text('ABOUT'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SplashScreen(false)),
                  ),
                ),
                //Clean all KMLS from liquid galaxy
                ListTile(
                  title: const Text('CLEAN KMLS'),
                  onTap: () => widget.callback(),
                ),
                ListTile(
                  //Liquid Galaxy connection status
                  title: Row(
                    children: [
                      Text('LIQUID GALAXY SETUP'),
                      Spacer(),
                      settingsBox?.get('connection')
                          ? Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            )
                          : Icon(
                              Icons.cancel,
                              color: Colors.red,
                              size: 20,
                            ),
                    ],
                  ),
                  //Changes drawer layout
                  onTap: () => setState(() {
                    liquidGalaxySetup = true;
                  }),
                ),
              ],
            ),
    );
  }

  Widget inputController(
      String label, TextEditingController controller, Size screenSize, bool password) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: screenSize.height * 0.015,
        horizontal: screenSize.height * 0.015,
      ),
      child: TextField(
        obscureText: password,
        controller: controller,
        decoration: new InputDecoration(
          hintText: label,
          labelText: label,
        ),
      ),
    );
  }
}
