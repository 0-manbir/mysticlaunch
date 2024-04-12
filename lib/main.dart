import 'dart:io';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mlauncher/helpers/grid_view.dart';
import 'package:mlauncher/pages/home_screen.dart';
import 'package:mlauncher/pages/left_screen.dart';
import 'package:mlauncher/pages/right_screen.dart';
import 'package:mlauncher/variables/colors.dart';
import 'package:mlauncher/variables/strings.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final PageController _pageController = PageController(initialPage: 1);

  void _onPageChanged(index) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          toolbarHeight: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            systemNavigationBarColor: backgroundColor,
            statusBarColor: Colors.transparent,
          ),
        ),
        body: Builder(
          builder: (context) {
            // swipe gestures------------------------------------------
            return GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  // Swipe down
                  expandNotification();
                } else if (details.primaryVelocity! < 0) {
                  // Swipe up
                  _openAppDrawer(context);
                }
              },

              // pages-------------------------------------------------
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: const [
                  LeftScreen(),
                  HomeScreen(),
                  RightScreen(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // app drawer--------------------------------------------------------------------------------------------------------------

  final FocusNode _focusNode = FocusNode();
  List<Application> allApps = [];
  List<Application> displayedApps = [];
  List<Application> recentApps = [];
  String currentText = '';
  bool isRecentAppsVisible = true;

  void _openAppDrawer(BuildContext buildContext) {
    double screenHeight = MediaQuery.of(buildContext).size.height;
    isRecentAppsVisible = true;

    showModalBottomSheet(
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      isScrollControlled: true,
      context: buildContext,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 1,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(height: 32),

                GestureDetector(
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(8.0),
                    height: 75,
                    width: 100,
                    decoration: BoxDecoration(
                      color: opaqueBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        "show all apps",
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          fontSize: 26,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w400,
                          color: lightTextColor,
                        ),
                      ),
                    ),
                  ),
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    AppsGridView().showGridView(
                      buildContext,
                      false,
                    );
                    Navigator.pop(buildContext);
                  },
                ),

                // recent apps
                isRecentAppsVisible
                    ? Container(
                        margin: const EdgeInsets.only(
                          bottom: 16.0,
                          left: 16.0,
                          right: 16.0,
                        ),
                        padding: const EdgeInsets.all(10.0),
                        height: 75,
                        decoration: BoxDecoration(
                          color: opaqueBackgroundColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 10,
                            itemBuilder: (context, index) {
                              if (recentApps.isNotEmpty) {
                                return recentAppsApp(context, index);
                              }
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: opaqueBackgroundColor,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Icon(
                                        Icons.error_outline_rounded,
                                        size: 40.0,
                                        color: lightTextColor,
                                      ),
                                    ),
                                    Container(width: 8),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.only(
                          bottom: 16.0,
                          left: 16.0,
                          right: 16.0,
                        ),
                        padding: const EdgeInsets.all(10.0),
                        height: 75,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),

                // search results
                SizedBox(
                  height: MediaQuery.of(context).viewInsets.bottom > 0
                      ? screenHeight - 330 - 225
                      : screenHeight - 80 - 225,
                  child: ListView.builder(
                    reverse: true,
                    // itemCount: displayedApps.length,
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      if (displayedApps.length <= index) {
                        return Container();
                      }
                      return GestureDetector(
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 15.0,
                            vertical: 10.0,
                          ),
                          child: Center(
                            child: Text(
                              displayedApps[index].appName.toLowerCase(),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 20,
                                color: lightTextColor,
                                fontFamily: 'Rubik',
                                fontWeight: FontWeight.w400,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                        onTap: () {
                          _openApp(index, context);
                        },
                        onLongPress: () {
                          _openAppSettings(index, context);
                        },
                      );
                    },
                  ),
                ),

                // search bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 8.0,
                  ),
                  child: TextField(
                    focusNode: _focusNode,
                    maxLines: 1,
                    textInputAction: TextInputAction.search,
                    cursorColor: darkTextColor,
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      color: lightTextColor,
                      fontSize: 18,
                    ),
                    decoration: InputDecoration(
                      alignLabelWithHint: true,
                      labelText: "app name...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.transparent),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      labelStyle: TextStyle(
                        fontFamily: 'Rubik',
                        color: darkTextColor,
                        fontSize: 18,
                      ),
                    ),
                    onSubmitted: (value) {
                      // enter pressed
                      Navigator.pop(context);

                      if (displayedApps.isEmpty) {
                        // no app remains, search on google
                        searchGoogle(value);
                        return;
                      }

                      _openApp(0, context);
                    },
                    onChanged: (value) {
                      if (value.isEmpty) {
                        setState(() {
                          isRecentAppsVisible = true;
                        });
                      } else if (isRecentAppsVisible) {
                        setState(() {
                          isRecentAppsVisible = false;
                        });
                      }

                      filterApps(value, context);

                      setState(() {
                        currentText = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // call functions after the bottom sheet is completely shown
    Future.delayed(const Duration(milliseconds: 200), () async {
      // open keyboard
      FocusScope.of(context).requestFocus(_focusNode);

      // get a list of installed applications
      loadApps();

      HapticFeedback.mediumImpact();
    });
  }

  Widget recentAppsApp(BuildContext buildContext, int index) {
    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
          // color: opaqueBackgroundColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: FutureBuilder<String?>(
          key: UniqueKey(),
          future: getAppIcon(recentApps[index].packageName),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (snapshot.data != null) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    children: [
                      Image.file(
                        File(snapshot.data!),
                        width: 60,
                      ),
                      Container(width: 8),
                    ],
                  ),
                );
              } else {
                return const Text('App icon path is null.');
              }
            } else {
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: opaqueBackgroundColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 40.0,
                        color: lightTextColor,
                      ),
                    ),
                    Container(width: 8),
                  ],
                ),
              );
            }
          },
        ),
      ),
      onTap: () {
        recentApps[index].openApp();
      },
      onLongPress: () {
        recentApps[index].openSettingsScreen();
      },
    );
  }

  void loadApps() async {
    List<Application> apps = await DeviceApps.getInstalledApplications(
      onlyAppsWithLaunchIntent: true,
      includeSystemApps: true,
    );

    List<Application> sortedApps = List.from(apps);
    sortedApps
        .sort((a, b) => b.installTimeMillis.compareTo(a.installTimeMillis));

    setState(() {
      allApps = apps;
      displayedApps = [];
      recentApps = sortedApps;
    });
  }

  void filterApps(String query, BuildContext buildContext) {
    // check if the query is empty
    if (query.trim() == '') {
      setState(() {
        displayedApps = [];
      });
    } else {
      setState(() {
        displayedApps = allApps
            .where((app) =>
                app.appName.toLowerCase().contains(query.toLowerCase()))
            .toList();

        if (displayedApps.length == 1 &&
            displayedApps[0].appName[0].toLowerCase() ==
                query[0].toLowerCase()) {
          _openApp(0, buildContext);
          Navigator.pop(buildContext);
        }

        // Custom sorting: prioritize apps that start with the query
        displayedApps.sort((a, b) {
          bool startsWithA =
              a.appName.toLowerCase().startsWith(query.toLowerCase());
          bool startsWithB =
              b.appName.toLowerCase().startsWith(query.toLowerCase());

          if (startsWithA && !startsWithB) {
            return -1; // a comes first
          } else if (!startsWithA && startsWithB) {
            return 1; // b comes first
          } else {
            return a.appName.compareTo(b.appName); // normal alphabetical order
          }
        });
      });
    }
  }

  // helper methods---------------------------------------------------------------------------------------------------------------
  void _openApp(int index, BuildContext buildContext) {
    Navigator.pop(buildContext);
    HapticFeedback.mediumImpact();
    displayedApps[index].openApp();
    setState(() {
      displayedApps = [];
    });
  }

  void _openAppSettings(int index, BuildContext buildContext) {
    Navigator.pop(buildContext);
    HapticFeedback.mediumImpact();

    displayedApps[index].openSettingsScreen();

    setState(() {
      displayedApps = [];
    });
  }

  bool doesIconFileExist(String packageName) {
    String iconFileName = 'icon_$packageName.png';
    String iconFilePath =
        '/data/user/0/$mlauncherPackageName/cache/$iconFileName';

    File iconFile = File(iconFilePath);
    return iconFile.existsSync();
  }

  Future<String?> getAppIcon(String packageName) async {
    try {
      // Check if the icon file already exists
      if (doesIconFileExist(packageName)) {
        return '/data/user/0/$mlauncherPackageName/cache/icon_$packageName.png';
      }

      String? appIconPath = await _channel
          .invokeMethod(methodGetAppIcon, {'packageName': packageName});
      return appIconPath;
    } catch (e) {
      return null;
    }
  }

  // native methods----------------------------------------------------------------------------------------------------------
  Future<void> expandNotification() async {
    try {
      await _channel.invokeMethod(methodExpandNotifications);
    } catch (e) {
      // print('Error invoking expand method: $e');
    }
  }

  Future<void> searchGoogle(String query) async {
    try {
      await _channel.invokeMethod(methodSearchGoogle, {'query': query});
    } catch (e) {
      // print('Error invoking searchGoogle method: $e');
    }
  }

  static const MethodChannel _channel = MethodChannel('main_channel');
}
