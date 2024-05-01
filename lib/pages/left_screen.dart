import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_alarm_clock/flutter_alarm_clock.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:mysticlaunch/helpers/grid_view.dart';
import 'package:mysticlaunch/variables/colors.dart';
import 'package:mysticlaunch/variables/strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeftScreen extends StatefulWidget {
  const LeftScreen({super.key});

  @override
  State<LeftScreen> createState() => _LeftScreenState();
}

class _LeftScreenState extends State<LeftScreen> {
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();

    _initSharedPreferences();
  }

  void _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    getLeftScreenApps();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    _getYearProgress();
    _getTimes();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          children: [
            Container(height: 12),
            getQuickSettings(screenWidth),
            timer(screenWidth),
            progresses(screenWidth),
            Expanded(child: Container()),
            leftScreenApps(screenWidth),
            Container(height: 12),
          ],
        ),
      ),
    );
  }

  // timer--------------------------------------------------------------------------------------------------------------------

  double _timerSliderLabel = 0.0;

  Widget timer(double screenWidth) {
    return Container(
      height: 70,
      margin: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
      child: GestureDetector(
        child: Container(
          height: 70,
          width: screenWidth - 32,
          decoration: BoxDecoration(
            color: opaqueBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(trackHeight: 10.0),
            child: Slider(
              min: 0.0,
              max: 120.0,
              value: _timerSliderLabel,
              divisions: 12,
              label: '${_timerSliderLabel.round()}',
              thumbColor: lightTextColor,
              activeColor: darkTextColor,
              inactiveColor: opaqueBackgroundColor,
              onChanged: (value) {
                setState(() {
                  _timerSliderLabel = value;
                  HapticFeedback.mediumImpact();
                });
              },
              onChangeEnd: (value) async {
                if (value == 0) {
                  return;
                }

                FlutterAlarmClock.createTimer(
                  length: value.toInt() * 60,
                  skipUi: false,
                );

                await HapticFeedback.heavyImpact();
                sleep(const Duration(milliseconds: 200));
                await HapticFeedback.heavyImpact();
                await HapticFeedback.mediumImpact();

                setState(() {
                  _timerSliderLabel = 0;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  // left screen apps-------------------------------------------------------------------------------------------------------

  List<String> leftScreenAppsPackageNames = List.generate(5, (index) => '');

  Widget leftScreenApps(double screenWidth) {
    return SizedBox(
      height: 100,
      width: screenWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 16.0,
        ),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 12.0,
            childAspectRatio: 1,
          ),
          itemCount: leftScreenAppsPackageNames.length,
          itemBuilder: (context, index) {
            String appPackageName = leftScreenAppsPackageNames[index];
            if (appPackageName != '') {
              return leftScreenApp(
                appPackageName,
                index,
                context,
              );
            }

            return leftScreenAppPlaceHolder(index, context);
          },
        ),
      ),
    );
  }

  void getLeftScreenApps() async {
    if (!_prefs.containsKey(prefsLeftScreenApps)) {
      _prefs.setStringList(prefsLeftScreenApps, ['', '', '', '', '']);
    }

    List<String> packageNames = _prefs.getStringList(prefsLeftScreenApps)!;

    setState(() {
      leftScreenAppsPackageNames = packageNames;
    });
  }

  Widget leftScreenApp(
    String packageName,
    int index,
    BuildContext buildContext,
  ) {
    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
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
                    colorFilter: const ColorFilter.mode(
                      backgroundColor,
                      BlendMode.saturation,
                    ),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.matrix(
                        <double>[
                          0.75, 0, 0, 0, 0, // Red channel
                          0, 0.75, 0, 0, 0, // Green channel
                          0, 0, 0.75, 0, 0, // Blue channel
                          0, 0, 0, 1, 0, // Alpha channel
                        ],
                      ),
                      child: Image.file(
                        File(snapshot.data!),
                        width: 50,
                        height: 50,
                      ),
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
          leftScreenAppsPackageNames[index] = '';
          _prefs.setStringList(prefsLeftScreenApps, leftScreenAppsPackageNames);
        });
      },
    );
  }

  Widget leftScreenAppPlaceHolder(int index, BuildContext buildContext) {
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
          leftScreenAppsPackageNames[index] = applicationInfo!.packageName;
          _prefs.setStringList(prefsLeftScreenApps, leftScreenAppsPackageNames);
        });
      },
    );
  }

  // progresses------------------------------------------------------------------------------------------------------------

  final TextEditingController _dayStartEditControllerHour =
      TextEditingController();
  final TextEditingController _dayStartEditControllerMin =
      TextEditingController();
  final TextEditingController _dayEndEditControllerHour =
      TextEditingController();
  final TextEditingController _dayEndEditControllerMin =
      TextEditingController();

  String _startTime = '4:00'; // 4 am
  String _endTime = '22:00'; // 10 pm
  int _dayPassed = 0;
  int _yearPassed = 0;

  Widget progresses(double screenWidth) {
    return Container(
      height: 70,
      margin: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
      child: Row(
        children: [
          GestureDetector(
            child: Container(
              height: 70,
              width: (screenWidth - 32 - 16) / 2,
              decoration: BoxDecoration(
                color: opaqueBackgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Background Container (representing the day progress)
                    Container(
                      width: (_dayPassed / 100) * ((screenWidth - 32 - 16) / 2),
                      height: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(50, 255, 255, 255),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                    // Content inside the container
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            "day\nprogress",
                            style: TextStyle(
                              fontFamily: 'Rubik',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              // color: Color.fromARGB(136, 255, 255, 255),
                              color: lightTextColor,
                              height: 1,
                            ),
                          ),
                        ),
                        Expanded(child: Container()),
                        Column(
                          children: [
                            Expanded(child: Container()),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _dayPassed.toString(),
                                    style: TextStyle(
                                      fontFamily: 'Rubik',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      // color: Color.fromARGB(136, 255, 255, 255),
                                      color: lightTextColor,
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    "%",
                                    style: TextStyle(
                                      fontFamily: 'Rubik',
                                      fontSize: 8,
                                      fontWeight: FontWeight.w400,
                                      // color: Color.fromARGB(136, 255, 255, 255),
                                      color: lightTextColor,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            onTap: () {
              _showChangeDayTimesSheet(context);
            },
          ),
          Expanded(child: Container()),
          GestureDetector(
            child: Container(
              height: 70,
              width: (screenWidth - 32 - 16) / 2,
              decoration: BoxDecoration(
                color: opaqueBackgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Background Container (representing the day progress)
                  Container(
                    width: (_yearPassed / 100) * ((screenWidth - 32 - 16) / 2),
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(50, 255, 255, 255),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                  ),
                  // Content inside the container
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          "year\nprogress",
                          style: TextStyle(
                            fontFamily: 'Rubik',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            // color: Color.fromARGB(136, 255, 255, 255),
                            color: lightTextColor,
                            height: 1,
                          ),
                        ),
                      ),
                      Expanded(child: Container()),
                      Column(
                        children: [
                          Expanded(child: Container()),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _yearPassed.toString(),
                                  style: TextStyle(
                                    fontFamily: 'Rubik',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    // color: Color.fromARGB(136, 255, 255, 255),
                                    color: lightTextColor,
                                    height: 1,
                                  ),
                                ),
                                Text(
                                  "%",
                                  style: TextStyle(
                                    fontFamily: 'Rubik',
                                    fontSize: 8,
                                    fontWeight: FontWeight.w400,
                                    // color: Color.fromARGB(136, 255, 255, 255),
                                    color: lightTextColor,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeDayTimesSheet(BuildContext buildContext) {
    double screenWidth = MediaQuery.of(buildContext).size.width;
    showModalBottomSheet(
      context: buildContext,
      builder: (context) {
        return Container(
          width: screenWidth,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            color: Colors.grey[100],
          ),
          child: Column(
            children: [
              Container(height: 25),
              Text(
                "enter the day start and end time:",
                style: TextStyle(
                  color: Colors.grey[500],
                  fontFamily: 'Rubik',
                  fontSize: 16,
                ),
              ),

              // day start textfields-----------------------------
              Row(
                children: [
                  Container(
                    width: 20,
                  ),

                  // day start edit hour-------------------------------------------
                  Expanded(
                    child: TextField(
                      controller: _dayStartEditControllerHour,
                      maxLines: 1,
                      maxLength: 2,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      cursorColor: Colors.grey[500],
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        counterText: "",
                        alignLabelWithHint: true,
                        labelText: "HH",
                        labelStyle: TextStyle(
                          fontFamily: 'Rubik',
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 20,
                  ),

                  // day start edit minute--------------------------------------------
                  Expanded(
                    child: TextField(
                      controller: _dayStartEditControllerMin,
                      maxLines: 1,
                      maxLength: 2,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      cursorColor: Colors.grey[500],
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        counterText: "",
                        alignLabelWithHint: true,
                        labelText: "MM",
                        labelStyle: TextStyle(
                          fontFamily: 'Rubik',
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 20,
                  ),
                ],
              ),

              // day end textfields----------------------------------
              Row(
                children: [
                  Container(
                    width: 20,
                  ),

                  // day end edit hour-------------------------------------------
                  Expanded(
                    child: TextField(
                      controller: _dayEndEditControllerHour,
                      maxLines: 1,
                      maxLength: 2,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      cursorColor: Colors.grey[500],
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        counterText: "",
                        alignLabelWithHint: true,
                        labelText: "HH",
                        labelStyle: TextStyle(
                          fontFamily: 'Rubik',
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 20,
                  ),

                  // day end edit minute--------------------------------------------
                  Expanded(
                    child: TextField(
                      controller: _dayEndEditControllerMin,
                      maxLines: 1,
                      maxLength: 2,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      cursorColor: Colors.grey[500],
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        counterText: "",
                        alignLabelWithHint: true,
                        labelText: "MM",
                        labelStyle: TextStyle(
                          fontFamily: 'Rubik',
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 20,
                  ),
                ],
              ),

              Container(
                height: 20,
              ),

              ElevatedButton(
                onPressed: () {
                  _saveDayTimes(context);
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.grey[100]),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "save",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontFamily: 'Rubik',
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (_prefs.containsKey(prefsDayEnd) && _prefs.containsKey(prefsDayEnd)) {
      String tempStartTime = _prefs.getString(prefsDayStart)!;
      String tempEndTime = _prefs.getString(prefsDayEnd)!;

      _dayStartEditControllerHour.text =
          tempStartTime.substring(0, tempStartTime.indexOf(":"));
      _dayStartEditControllerMin.text =
          tempStartTime.substring(tempStartTime.indexOf(":") + 1);

      _dayEndEditControllerHour.text =
          tempEndTime.substring(0, tempEndTime.indexOf(":"));
      _dayEndEditControllerMin.text =
          tempEndTime.substring(tempEndTime.indexOf(":") + 1);
    }
  }

  void _saveDayTimes(BuildContext buildContext) {
    Navigator.pop(buildContext);
    HapticFeedback.heavyImpact();

    if (_dayStartEditControllerHour.text == '' ||
        _dayStartEditControllerMin.text == '' ||
        _dayEndEditControllerHour.text == '' ||
        _dayEndEditControllerMin.text == '') {
      return;
    }

    String newDayStartTime =
        "${_dayStartEditControllerHour.text}:${_dayStartEditControllerMin.text}";

    String newDayEndTime =
        "${_dayEndEditControllerHour.text}:${_dayEndEditControllerMin.text}";

    _prefs.setString(
      prefsDayStart,
      newDayStartTime,
    );
    _prefs.setString(
      prefsDayEnd,
      newDayEndTime,
    );

    setState(() {
      _startTime = newDayStartTime;
      _endTime = newDayEndTime;
    });
  }

  void _getYearProgress() {
    double yearPassed = DateTime.now()
            .difference(
              DateTime(
                DateTime.now().year,
                1,
                1,
              ),
            )
            .inDays +
        1;
    yearPassed = yearPassed / 365.0 * 100.0;
    _yearPassed = yearPassed.toInt();
  }

  void _getTimes() {
    DateTime now = DateTime.now();

    DateTime startTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(_startTime.substring(0, _startTime.indexOf(":"))),
      int.parse(_startTime.substring(_startTime.indexOf(":") + 1)),
    );
    DateTime endTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(_endTime.substring(0, _endTime.indexOf(":"))),
      int.parse(_endTime.substring(_endTime.indexOf(":") + 1)),
    );

    Duration totalDayDuration = endTime.difference(startTime);
    Duration timeElapsed = now.difference(startTime);

    double percentage =
        (timeElapsed.inSeconds / totalDayDuration.inSeconds) * 100.0;
    percentage = percentage.clamp(0.0, 100.0);

    setState(() {
      _dayPassed = percentage.toInt();
    });
  }

  // quick settings--------------------------------------------------------------------------------------------------------
  Widget getQuickSettings(double screenWidth) {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
      child: Row(
        children: [
          GestureDetector(
            child: Container(
              width: (screenWidth - 32 - 16) / 2,
              decoration: BoxDecoration(
                color: opaqueBackgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wallpaper_rounded,
                    color: lightTextColor,
                    size: 36,
                  ),
                  Container(width: 10),
                  Text(
                    "change\nwallpaper",
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: lightTextColor,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              HapticFeedback.mediumImpact();
              _changeWallpaper();
            },
          ),
          Expanded(child: Container()),
          GestureDetector(
            child: Container(
              width: (screenWidth - 32 - 16) / 2,
              decoration: BoxDecoration(
                color: opaqueBackgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rocket_launch_outlined,
                    color: lightTextColor,
                    size: 36,
                  ),
                  Container(width: 10),
                  Text(
                    "change\nlauncher",
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: lightTextColor,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              HapticFeedback.mediumImpact();
              openSettingsActivity();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _changeWallpaper() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    File file;

    if (result != null) {
      file = File(result.files.single.path!);
    } else {
      // User canceled the picker
      return;
    }

    int location = WallpaperManager.BOTH_SCREEN;
    await WallpaperManager.setWallpaperFromFile(
      file.path,
      location,
    );
  }

  // helper methods--------------------------------------------------------------------------------------------------------

  bool doesIconFileExist(String packageName) {
    String iconFileName = 'icon_$packageName.png';
    String iconFilePath =
        '/data/user/0/$mysticlaunchPackageName/cache/$iconFileName';

    File iconFile = File(iconFilePath);
    return iconFile.existsSync();
  }

  Future<String?> getAppIcon(String packageName) async {
    try {
      // Check if the icon file already exists
      if (doesIconFileExist(packageName)) {
        return '/data/user/0/$mysticlaunchPackageName/cache/icon_$packageName.png';
      }

      String? appIconPath = await _channel
          .invokeMethod(methodGetAppIcon, {'packageName': packageName});
      return appIconPath;
    } catch (e) {
      return null;
    }
  }

  Future<void> openAppByPackageName(String packageName) async {
    try {
      await _channel.invokeMethod(methodOpenApp, {'packageName': packageName});
    } catch (e) {
      // print('error in launching app $e');
    }
  }

  Future<void> openSettingsActivity() async {
    try {
      await _channel.invokeMethod('openSettingsActivity');
    } catch (e) {
      // print('Error invoking openSettingsActivity method: $e');
    }
  }

  static const MethodChannel _channel = MethodChannel('main_channel');
}
