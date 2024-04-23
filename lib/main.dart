import 'dart:io';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mlauncher/helpers/grid_view.dart';
import 'package:mlauncher/pages/home_screen.dart';
import 'package:mlauncher/pages/left_screen.dart';
import 'package:mlauncher/pages/right_screen.dart';
import 'package:mlauncher/variables/colors.dart';
import 'package:mlauncher/variables/strings.dart';

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
      home: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          _pageController.jumpToPage(1);
        },
        child: Scaffold(
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

  TextEditingController searchTextController = TextEditingController();

  void _openAppDrawer(BuildContext buildContext) {
    double screenHeight = MediaQuery.of(buildContext).size.height;
    isRecentAppsVisible = true;
    displayedApps = [];
    recentApps = [];
    searchTextController.text = "";

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
                        "all apps",
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
                    if (Navigator.canPop(buildContext)) {
                      Navigator.pop(buildContext);
                    }
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
                              return Container();
                            },
                          ),
                        ),
                      )
                    : Container(),

                // search results
                SizedBox(
                  height: MediaQuery.of(context).viewInsets.bottom > 0
                      ? screenHeight -
                          50 -
                          330 -
                          225 +
                          (isRecentAppsVisible ? 0 : 75 + 16)
                      : screenHeight -
                          50 -
                          80 -
                          225 +
                          (isRecentAppsVisible ? 0 : 75 + 16),
                  child: ListView.builder(
                    reverse: true,
                    itemCount: displayedApps.length,
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

                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  height: 50,
                  child: Center(
                    child: Row(
                      children: [
                        Expanded(child: Container()),
                        GestureDetector(
                          child: Container(
                            decoration: BoxDecoration(
                              color: opaqueBackgroundColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Image.asset("icons/app_google.png"),
                          ),
                          onTap: () {
                            if (Navigator.canPop(buildContext)) {
                              Navigator.pop(buildContext);
                            }
                            searchGoogle(searchTextController.text);
                          },
                        ),
                        Container(width: 8),
                        GestureDetector(
                          child: Container(
                            decoration: BoxDecoration(
                              color: opaqueBackgroundColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Image.asset("icons/app_youtube.png"),
                          ),
                          onTap: () {
                            if (Navigator.canPop(buildContext)) {
                              Navigator.pop(buildContext);
                            }
                            searchYoutube(searchTextController.text);
                          },
                        ),
                        Container(width: 8),
                        GestureDetector(
                          child: Container(
                            decoration: BoxDecoration(
                              color: opaqueBackgroundColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Image.asset("icons/app_amazon.png"),
                          ),
                          onTap: () {
                            if (Navigator.canPop(buildContext)) {
                              Navigator.pop(buildContext);
                            }
                            searchAmazon(searchTextController.text);
                          },
                        ),
                        Container(width: 8),
                        GestureDetector(
                          child: Container(
                            decoration: BoxDecoration(
                              color: opaqueBackgroundColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Image.asset("icons/app_firefox.png"),
                          ),
                          onTap: () {
                            if (Navigator.canPop(buildContext)) {
                              Navigator.pop(buildContext);
                            }
                            searchFirefox(searchTextController.text);
                          },
                        ),
                        Container(width: 8),
                        GestureDetector(
                          child: Container(
                            decoration: BoxDecoration(
                              color: opaqueBackgroundColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Image.asset("icons/app_chatgpt.png"),
                          ),
                          onTap: () {
                            if (Navigator.canPop(buildContext)) {
                              Navigator.pop(buildContext);
                            }
                            searchChatGPT(searchTextController.text);
                          },
                        ),
                        Container(width: 8),
                      ],
                    ),
                  ),
                ),

                // search bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 8.0,
                  ),
                  child: TextField(
                    controller: searchTextController,
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
                      // alignLabelWithHint: true,
                      // labelText: "app name...",
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
                      if (Navigator.canPop(buildContext)) {
                        Navigator.pop(buildContext);
                      }

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

                      value = value.trim();

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

    // called after the bottom sheet is completely shown
    Future.delayed(const Duration(milliseconds: 200), () async {
      FocusScope.of(context).requestFocus(_focusNode);
      loadApps(buildContext);
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
              return Container();
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

  Future<void> loadApps(BuildContext buildContext) async {
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
      filterApps(searchTextController.text, buildContext);
    });
  }

  void filterApps(String query, BuildContext buildContext) {
    // check if the query is empty
    if (query == '') {
      setState(() {
        displayedApps = [];
      });
    } else {
      setState(() {
        displayedApps = allApps
            .where((app) =>
                app.appName.toLowerCase().contains(query.toLowerCase()))
            .toList();

        // open app if only one match remains - removed because it might interfere with the search function.
        // instead, now the only match opens by pressing the search button on the keyboard
        // if (displayedApps.length == 1 &&
        //     displayedApps[0].appName[0].toLowerCase() ==
        //         query[0].toLowerCase()) {
        //   _openApp(0, buildContext);

        //   if (Navigator.canPop(buildContext)) Navigator.pop(buildContext);
        // }

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
    if (Navigator.canPop(buildContext)) Navigator.pop(buildContext);
    HapticFeedback.mediumImpact();
    displayedApps[index].openApp();
    setState(() {
      displayedApps = [];
    });
  }

  void _openAppSettings(int index, BuildContext buildContext) {
    if (Navigator.canPop(buildContext)) Navigator.pop(buildContext);
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

  Future<void> openSettingsActivity() async {
    try {
      await _channel.invokeMethod('openSettingsActivity');
    } catch (e) {
      // print('Error invoking openSettingsActivity method: $e');
    }
  }

  Future<void> searchGoogle(String query) async {
    try {
      await _channel.invokeMethod(methodSearchGoogle, {'query': query});
    } catch (e) {
      // print('Error invoking searchGoogle method: $e');
    }
  }

  Future<void> searchFirefox(String query) async {
    try {
      await _channel.invokeMethod(methodSearchFirefox, {'query': query});
    } catch (e) {
      // print('Error invoking search firefox method: $e');
    }
  }

  Future<void> searchYoutube(String query) async {
    try {
      await _channel.invokeMethod(methodSearchYoutube, {'query': query});
    } catch (e) {
      // print('Error invoking search youtube method: $e');
    }
  }

  Future<void> searchChatGPT(String query) async {
    try {
      await _channel.invokeMethod(methodSearchChatGPT, {'query': query});
    } catch (e) {
      // print('Error invoking search chat gpt method: $e');
    }
  }

  Future<void> searchAmazon(String query) async {
    try {
      await _channel.invokeMethod(methodSearchAmazon, {'query': query});
    } catch (e) {
      // print('Error invoking search amazon method: $e');
    }
  }

  static const MethodChannel _channel = MethodChannel('main_channel');
}
