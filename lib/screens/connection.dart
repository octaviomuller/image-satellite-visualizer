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
  Box? imageBox;
  Box? settingsBox;
  Box? selectedImagesBox;

  TextEditingController ipTextController = TextEditingController();
  TextEditingController usernameTextController = TextEditingController();
  TextEditingController passwordTextController = TextEditingController();
  TextEditingController urlTextXontroller = TextEditingController();

  bool liquidGalaxySetup = false;

  List<bool> isSelected = [true, false];

  @override
  void initState() {
    imageBox = Hive.box('imageBox');
    settingsBox = Hive.box('liquidGalaxySettings');
    selectedImagesBox = Hive.box('selectedImages');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;

    return SafeArea(
      child: liquidGalaxySetup
          ? Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenSize.height * 0.015,
                    horizontal: screenSize.height * 0.015,
                  ),
                  child: ToggleButtons(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    children: <Widget>[
                      Text('  Ubuntu 16  '),
                      Text('  Ubuntu 18/20  '),
                    ],
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
                isSelected[0]
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: screenSize.height * 0.015,
                          horizontal: screenSize.height * 0.015,
                        ),
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: ipTextController,
                          decoration: new InputDecoration(
                            hintText: 'IP',
                            labelText: 'IP',
                          ),
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: screenSize.height * 0.015,
                          horizontal: screenSize.height * 0.015,
                        ),
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: urlTextXontroller,
                          decoration: new InputDecoration(
                            hintText: 'URL',
                            labelText: 'URL',
                          ),
                        ),
                      ),
                isSelected[0]
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: screenSize.height * 0.015,
                          horizontal: screenSize.height * 0.015,
                        ),
                        child: TextField(
                          controller: usernameTextController,
                          decoration: new InputDecoration(
                            hintText: 'Username',
                            labelText: 'Username',
                          ),
                        ),
                      )
                    : Container(),
                isSelected[0]
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: screenSize.height * 0.015,
                          horizontal: screenSize.height * 0.015,
                        ),
                        child: TextField(
                          obscureText: true,
                          controller: passwordTextController,
                          decoration: new InputDecoration(
                            hintText: 'Password',
                            labelText: 'Password',
                          ),
                        ),
                      )
                    : Container(),
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
                          settingsBox?.put('ip', ipTextController.text);
                          settingsBox?.put(
                              'username', usernameTextController.text);
                          settingsBox?.put(
                              'password', passwordTextController.text);

                          Client client = Client(
                            ip: settingsBox?.get('ip'),
                            username: settingsBox?.get('username'),
                            password: settingsBox?.get('password'),
                          );

                          try {
                            await client.checkConnection();
                            settingsBox?.put('connection', true);
                            client.sendDemos();
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
                ListTile(
                  title: const Text('ABOUT'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SplashScreen(false)),
                  ),
                ),
                ListTile(
                  title: const Text('CLEAN KMLS'),
                  onTap: () => widget.callback(),
                ),
                ListTile(
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
                  onTap: () => setState(() {
                    liquidGalaxySetup = true;
                  }),
                ),
              ],
            ),
    );
  }
}
