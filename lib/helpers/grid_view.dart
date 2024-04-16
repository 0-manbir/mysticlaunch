import 'dart:async';
import 'dart:io';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mlauncher/variables/colors.dart';
import 'package:mlauncher/variables/strings.dart';

class AppsGridView {
  List displayedApps = [];

  late String iconFilePath;

  Future<ApplicationInfo?> showGridView(
    BuildContext buildContext,
    bool returnApplicationInfo,
  ) async {
    double screenWidth = MediaQuery.of(buildContext).size.width;
    double screenHeight = MediaQuery.of(buildContext).size.height;

    Completer<ApplicationInfo?> completer = Completer();

    await loadApps();
    sortAppsByName();

    showModalBottomSheet(
      backgroundColor: backgroundColor,
      // rectangular corners
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      isScrollControlled: true,
      // ignore: use_build_context_synchronously
      context: buildContext,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 1,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(height: 12),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "all apps:",
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 24,
                        color: lightTextColor,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: screenHeight - 90,
                    width: screenWidth,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 15.0,
                        crossAxisSpacing: 15.0,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: displayedApps.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FutureBuilder<String?>(
                                  key: UniqueKey(),
                                  future: getAppIcon(
                                      displayedApps[index].packageName),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.done) {
                                      if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      } else if (snapshot.data != null) {
                                        return Image.file(
                                          File(snapshot.data!),
                                          width: 70,
                                          height: 70,
                                        );
                                      } else {
                                        return const Text(
                                            'App icon path is null.');
                                      }
                                    } else {
                                      return const CircularProgressIndicator();
                                    }
                                  },
                                ),
                                Text(
                                  displayedApps[index].appName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Rubik',
                                    fontSize: 12,
                                    color: lightTextColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            if (returnApplicationInfo) {
                              ApplicationInfo selectedApp = ApplicationInfo(
                                appName: displayedApps[index].appName,
                                packageName: displayedApps[index].packageName,
                                iconPath: iconFilePath,
                              );

                              completer.complete(selectedApp);
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            } else {
                              _openApp(index, context);
                              completer.complete(null);
                            }
                          },
                          onLongPress: () {
                            if (!returnApplicationInfo) {
                              _openAppSettings(index, context);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return completer.future;
  }

  // methods

  void _openApp(int index, BuildContext buildContext) {
    Navigator.pop(buildContext);
    HapticFeedback.mediumImpact();
    displayedApps[index].openApp();
  }

  void _openAppSettings(int index, BuildContext buildContext) {
    // if (Navigator.canPop(buildContext)) Navigator.pop(buildContext);
    HapticFeedback.mediumImpact();

    displayedApps[index].openSettingsScreen();
  }

  Future<void> loadApps() async {
    List apps = await DeviceApps.getInstalledApplications(
      onlyAppsWithLaunchIntent: true,
      includeSystemApps: true,
      // includeAppIcons: true,
    );

    displayedApps = apps;
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
        String filePath =
            '/data/user/0/$mlauncherPackageName/cache/icon_$packageName.png';
        iconFilePath = filePath;
        return filePath;
      }

      String? appIconPath = await _channel
          .invokeMethod(methodGetAppIcon, {'packageName': packageName});

      iconFilePath = appIconPath!;
      return appIconPath;
    } catch (e) {
      return null;
    }
  }

  void sortAppsByName() {
    displayedApps.sort((a, b) => a.appName
        .toString()
        .toLowerCase()
        .compareTo(b.appName.toString().toLowerCase()));
  }

  static const MethodChannel _channel = MethodChannel('main_channel');
}

class ApplicationInfo {
  String appName;
  String packageName;
  String iconPath;

  ApplicationInfo({
    required this.appName,
    required this.packageName,
    required this.iconPath,
  });
}
