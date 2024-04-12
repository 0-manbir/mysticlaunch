import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mlauncher/helpers/grid_view.dart';
import 'package:mlauncher/variables/colors.dart';
import 'package:mlauncher/variables/strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RightScreen extends StatefulWidget {
  const RightScreen({super.key});

  @override
  State<RightScreen> createState() => _RightScreenState();
}

class _RightScreenState extends State<RightScreen> {
  late SharedPreferences _prefs;

  @override
  void initState() {
    _initSharedPreferences();
    super.initState();
  }

  void _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    getRightScreenApps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          children: [
            Container(height: 12),
            rightScreenAppsWidget(context),
          ],
        ),
      ),
    );
  }

  List<String> rightScreenAppsPackageNames = List.generate(10, (index) => '');

  Widget rightScreenAppsWidget(BuildContext buildContext) {
    double screenWidth = MediaQuery.of(buildContext).size.width;
    return SizedBox(
      height: 200,
      width: screenWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 32.0,
          vertical: 32.0,
        ),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: 1,
          ),
          itemCount: rightScreenAppsPackageNames.length,
          itemBuilder: (context, index) {
            String appPackageName = rightScreenAppsPackageNames[index];
            if (appPackageName != '') {
              return rightScreenApps(
                appPackageName,
                index,
                context,
              );
            }

            return rightScreenAppPlaceHolder(index, context);
          },
        ),
      ),
    );
  }

  void getRightScreenApps() async {
    List<String> packageNames = _prefs.getStringList(prefsRightScreenApps)!;

    setState(() {
      rightScreenAppsPackageNames = packageNames;
    });
  }

  Widget rightScreenApps(
    String packageName,
    int index,
    BuildContext buildContext,
  ) {
    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
        ),
        child: FutureBuilder<String?>(
          key: UniqueKey(),
          future: getAppIcon(packageName),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (snapshot.data != null) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.grey[100]!,
                      BlendMode.saturation,
                    ),
                    child: Image.file(
                      File(snapshot.data!),
                      width: 50,
                      height: 50,
                    ),
                  ),
                );
              } else {
                return const Text('App icon path is null.');
              }
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      ),
      onTap: () {
        openAppByPackageName(packageName);
      },
      onLongPress: () {
        HapticFeedback.heavyImpact();

        setState(() {
          rightScreenAppsPackageNames[index] = '';
          _prefs.setStringList(
              prefsRightScreenApps, rightScreenAppsPackageNames);
        });
      },
    );
  }

  bool doesIconFileExist(String packageName) {
    String iconFileName = 'icon_$packageName.png';
    String iconFilePath =
        '/data/user/0/com.example.mysticlaunch/cache/$iconFileName';

    File iconFile = File(iconFilePath);
    return iconFile.existsSync();
  }

  Future<String?> getAppIcon(String packageName) async {
    try {
      // Check if the icon file already exists
      if (doesIconFileExist(packageName)) {
        return '/data/user/0/com.example.mysticlaunch/cache/icon_$packageName.png';
      }

      String? appIconPath = await _channel
          .invokeMethod(methodGetAppIcon, {'packageName': packageName});
      return appIconPath;
    } catch (e) {
      return null;
    }
  }

  Widget rightScreenAppPlaceHolder(int index, BuildContext buildContext) {
    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
          color: opaqueBackgroundColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(
          Icons.add_circle_outline_rounded,
          color: Color.fromARGB(75, 255, 255, 255),
          size: 48,
        ),
      ),
      onTap: () async {
        HapticFeedback.mediumImpact();
        ApplicationInfo? applicationInfo =
            await AppsGridView().showGridView(buildContext, true);

        setState(() {
          rightScreenAppsPackageNames[index] = applicationInfo!.packageName;
          _prefs.setStringList(
              prefsRightScreenApps, rightScreenAppsPackageNames);
        });
      },
    );
  }

  // native methods
  Future<void> openAppByPackageName(String packageName) async {
    try {
      await _channel.invokeMethod(methodOpenApp, {'packageName': packageName});
    } catch (e) {
      // print('error in launching app $e');
    }
  }

  static const MethodChannel _channel = MethodChannel('main_channel');

  /*
  return SizedBox(
      height: 75,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Container(
          decoration: const BoxDecoration(
            color: opaqueBackgroundColor,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Row(),
        ),
      ),
  );
  */
}
