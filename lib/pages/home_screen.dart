import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:battery_info/battery_info_plugin.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_alarm_clock/flutter_alarm_clock.dart';
import 'package:mysticlaunch/helpers/grid_view.dart';
import 'package:mysticlaunch/variables/colors.dart';
import 'package:mysticlaunch/variables/strings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:weather/weather.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _batteryLevel = 0;
  String _temperature = "--";
  WeatherFactory wf = WeatherFactory(WEATHERMAP_API_KEY);

  late Timer _timerOneMinute;

  @override
  void initState() {
    _initSharedPreferences();

    _getBatteryPercentage();

    _timerOneMinute = Timer.periodic(
      const Duration(minutes: 1),
      (Timer timer) {
        // these methods are called every minute
        _getBatteryPercentage();
      },
    );

    super.initState();
  }

  late SharedPreferences _prefs;

  void _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();

    if (!_prefs.containsKey(prefsHomeScreenApps)) {
      _prefs.setStringList(prefsHomeScreenApps, []);
    }

    // methods getting shared prefs
    _getTotalHomeScreenApps();
    _getHomeScreenAppsAlignment();

    if (_prefs.containsKey(prefsWeather)) {
      setState(() {
        _temperature = _prefs.getString(prefsWeather) ?? "--";
      });
    } else {
      _getWeather();
    }
  }

  @override
  void dispose() {
    // cancel the timer when the widget is disposed
    _timerOneMinute.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          children: [
            Container(height: 75),
            const ClockWidget(),
            Container(height: 20),
            widgets(),
            Container(height: 25),
            Expanded(child: homeScreenApps()),
            bottomIcons(),
            Container(height: 20),
          ],
        ),
      ),
    );
  }

  // home screen icons-----------------------------------------------------------------------------------------------------------------------
  int _totalHomeScreenApps = 0;

  Widget homeScreenApps() {
    return Expanded(
      child: Center(
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _totalHomeScreenApps,
          itemBuilder: (BuildContext context, int index) {
            if (_prefs.containsKey(prefsHomeScreenApps)) {
              String appItem =
                  _prefs.getStringList(prefsHomeScreenApps)![index];

              return homeScreenApp(
                appItem.substring(appItem.indexOf(',') + 1),
                appItem.substring(0, appItem.indexOf(',')),
                index,
                context,
              );
            }
            return Container();
          },
        ),
      ),
    );
  }

  final TextEditingController _homeScreenNameEditController =
      TextEditingController();
  final TextEditingController _homeScreenIndexEditController =
      TextEditingController();
  Alignment homeScreenAppsAlignment = Alignment.center;

  // home screen app template
  Widget homeScreenApp(
    String appName,
    String packageName,
    int index,
    BuildContext buildContext,
  ) {
    double screenWidth = MediaQuery.of(buildContext).size.width;

    return Container(
      alignment: homeScreenAppsAlignment,
      child: GestureDetector(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 8,
          ),
          child: Text(
            appName.toLowerCase(),
            style: TextStyle(
              fontSize: 26,
              color: darkTextColor,
              fontFamily: 'Rubik',
              fontWeight: FontWeight.w400,
              height: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        onTap: () {
          // open app
          HapticFeedback.mediumImpact();
          openAppByPackageName(packageName);
        },
        onLongPress: () {
          HapticFeedback.heavyImpact();

          _homeScreenNameEditController.text = appName;
          _homeScreenIndexEditController.text = index.toString();

          // show options to edit the app name / delete the app from home screen
          showModalBottomSheet(
            context: buildContext,
            backgroundColor: backgroundColor,
            builder: (context) {
              return Container(
                width: screenWidth,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(40),
                  ),
                  color: backgroundColor,
                ),
                child: Column(
                  children: [
                    // edit the app name
                    Container(height: 20),
                    Text(
                      "enter the app name: ",
                      style: TextStyle(
                        color: darkTextColor,
                        fontFamily: 'Rubik',
                        fontSize: 20,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: TextField(
                        controller: _homeScreenNameEditController,
                        maxLines: 1,
                        textInputAction: TextInputAction.done,
                        cursorColor: darkTextColor,
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          color: lightTextColor,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          alignLabelWithHint: true,
                          labelText: "name",
                          labelStyle: TextStyle(
                            fontFamily: 'Rubik',
                            color: darkTextColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    // edit the app index
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: TextField(
                        controller: _homeScreenIndexEditController,
                        maxLines: 1,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        cursorColor: darkTextColor,
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          color: lightTextColor,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          alignLabelWithHint: true,
                          labelText: "position (starting at 0)",
                          labelStyle: TextStyle(
                            fontFamily: 'Rubik',
                            color: darkTextColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    Expanded(flex: 3, child: Container()),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // set home screen alignment
                        GestureDetector(
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: opaqueBackgroundColor,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Icon(
                              Icons.format_align_center_rounded,
                              color: lightTextColor,
                              size: 28,
                            ),
                          ),
                          onTap: () {
                            int currAlignment = _prefs
                                    .containsKey(prefsHomeScreenAppsAlignment)
                                ? _prefs.getInt(prefsHomeScreenAppsAlignment)!
                                : 0;

                            if (currAlignment == 2) {
                              currAlignment = 0;
                            } else {
                              currAlignment++;
                            }

                            _prefs.setInt(
                                prefsHomeScreenAppsAlignment, currAlignment);

                            setState(() {
                              switch (currAlignment) {
                                case 0:
                                  homeScreenAppsAlignment = Alignment.center;
                                  break;
                                case 1:
                                  homeScreenAppsAlignment =
                                      Alignment.centerLeft;
                                  break;
                                case 2:
                                  homeScreenAppsAlignment =
                                      Alignment.centerRight;
                                  break;
                                default:
                                  homeScreenAppsAlignment = Alignment.center;
                              }
                            });

                            if (Navigator.canPop(buildContext)) {
                              Navigator.pop(buildContext);
                            }
                          },
                        ),

                        Container(width: 16),

                        // delete button----------------------------------
                        GestureDetector(
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: opaqueBackgroundColor,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Icon(
                              Icons.delete_forever_rounded,
                              color: lightTextColor,
                              size: 28,
                            ),
                          ),
                          onTap: () {
                            // delete button
                            List<String> updatedList =
                                _prefs.getStringList(prefsHomeScreenApps)!;
                            updatedList.removeAt(index);

                            _prefs.setStringList(
                              prefsHomeScreenApps,
                              updatedList,
                            );

                            if (Navigator.canPop(buildContext)) {
                              Navigator.pop(buildContext);
                            }
                            setState(() {
                              _totalHomeScreenApps--;
                            });
                          },
                        ),

                        Container(width: 16),

                        // save button----------------------------------
                        GestureDetector(
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: opaqueBackgroundColor,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Icon(
                              Icons.done_all_rounded,
                              color: lightTextColor,
                              size: 28,
                            ),
                          ),
                          onTap: () {
                            // save button
                            List<String> updatedList =
                                _prefs.getStringList(prefsHomeScreenApps)!;

                            updatedList[index] =
                                "$packageName,${_homeScreenNameEditController.text}";

                            int newIndex =
                                int.parse(_homeScreenIndexEditController.text);
                            if (index != newIndex) {
                              if (newIndex < updatedList.length &&
                                  newIndex >= 0) {
                                String temp = updatedList[index];
                                updatedList[index] = updatedList[newIndex];
                                updatedList[newIndex] = temp;
                              }
                            }

                            _prefs.setStringList(
                              prefsHomeScreenApps,
                              updatedList,
                            );

                            if (Navigator.canPop(buildContext)) {
                              Navigator.pop(buildContext);
                            }
                            setState(() {});
                          },
                        ),
                      ],
                    ),

                    Expanded(child: Container()),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _getTotalHomeScreenApps() {
    int totalApps = 0;
    try {
      if (_prefs.containsKey(prefsHomeScreenApps)) {
        totalApps = _prefs.getStringList(prefsHomeScreenApps)?.length ?? 0;
      }
      // ignore: empty_catches
    } catch (e) {}

    setState(() {
      _totalHomeScreenApps = totalApps;
    });
  }

  void _getHomeScreenAppsAlignment() {
    Alignment alignment = Alignment.center;
    if (_prefs.containsKey(prefsHomeScreenAppsAlignment)) {
      switch (_prefs.getInt(prefsHomeScreenAppsAlignment)) {
        case 1:
          alignment = Alignment.centerLeft;
          break;
        case 2:
          alignment = Alignment.centerRight;
          break;
        default:
          break;
      }
    }

    setState(() {
      homeScreenAppsAlignment = alignment;
    });
  }

  Future<void> addHomeScreenApp(BuildContext buildContext) async {
    // add a new home screen app
    HapticFeedback.mediumImpact();

    try {
      ApplicationInfo? applicationInfo =
          await AppsGridView().showGridView(context, true);

      String packageName = applicationInfo!.packageName;
      String appName = applicationInfo.appName;

      List<String> updatedList = _prefs.getStringList(prefsHomeScreenApps)!;
      updatedList.add("$packageName,$appName");

      _prefs.setStringList(
        prefsHomeScreenApps,
        updatedList,
      );

      // ignore: use_build_context_synchronously
      if (Navigator.canPop(buildContext)) Navigator.pop(buildContext);

      setState(() {
        _totalHomeScreenApps++;
      });
    } catch (e) {
      // print("$e");
    }
  }

  // bottom icons-----------------------------------------------------------------------------------------------------------------------

  Widget bottomIcons() {
    return SizedBox(
      height: 75,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Row(
          children: [
            // OPEN PHONE APP________________________________
            GestureDetector(
              child: Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: opaqueBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.phone_rounded,
                  size: 34.0,
                  color: lightTextColor,
                ),
              ),
              onTap: () async {
                const phoneNumber = 'tel:';
                if (await canLaunchUrlString(phoneNumber)) {
                  await launchUrlString(phoneNumber);
                } else {
                  // print('Could not launch phone app');
                }
              },
            ),

            Expanded(child: Container()),

            // ADD HOME SCREEN APP__________________________
            GestureDetector(
              child: Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: opaqueBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.app_shortcut_rounded,
                  size: 34.0,
                  color: lightTextColor,
                ),
              ),
              onTap: () async {
                try {
                  await addHomeScreenApp(context);
                } catch (e) {
                  // error in adding home screen app
                  setState(() {});
                }
              },
            ),

            Expanded(child: Container()),

            // GMAIL_________________________________________
            GestureDetector(
              child: Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: opaqueBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.mail_rounded,
                  size: 36.0,
                  color: lightTextColor,
                ),
              ),
              onTap: () async {
                try {
                  openAppByPackageName(gmailPackageName);
                } catch (e) {
                  // error in opening gmail
                }
              },
            ),

            Expanded(child: Container()),

            // SETTINGS________________________________________
            GestureDetector(
              child: Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: opaqueBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.settings_rounded,
                  size: 34.0,
                  color: lightTextColor,
                ),
              ),
              onLongPress: () {
                searchGoogle("");
              },
              onTap: () async {
                const intent = AndroidIntent(
                  action: 'android.settings.SETTINGS',
                );

                try {
                  await intent.launch();
                } catch (e) {
                  // print('Could not open system settings: $e');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget widgets() {
    return SizedBox(
      height: 75,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Container(
          decoration: const BoxDecoration(
            color: opaqueBackgroundColor,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "icons/battery.png",
                    height: 18,
                    color: lightTextColor,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _batteryLevel.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          color: lightTextColor,
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.w400,
                          height: 1.25,
                        ),
                      ),
                      Text(
                        "%",
                        style: TextStyle(
                          fontSize: 10,
                          color: darkTextColor,
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(width: 70),
              GestureDetector(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(height: 6),
                    Text(
                      "${DateTime.now().day.toString()} ${DateFormat.MMM().format(DateTime.now())}",
                      style: TextStyle(
                        fontSize: 20,
                        color: lightTextColor,
                        fontFamily: 'Rubik',
                        fontWeight: FontWeight.w400,
                        height: 1,
                      ),
                    ),
                    Text(
                      DateFormat.EEEE().format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 15,
                        color: darkTextColor,
                        fontFamily: 'Rubik',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  const String url = 'content://com.android.calendar/time/';

                  if (await canLaunchUrlString(url)) {
                    await launchUrlString(url);
                  } else {
                    // print('Could not launch $url');
                  }
                },
              ),
              Container(width: 70),
              GestureDetector(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_rounded,
                      size: 16,
                      color: lightTextColor,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _temperature,
                          style: TextStyle(
                            fontSize: 18,
                            color: lightTextColor,
                            fontFamily: 'Rubik',
                            fontWeight: FontWeight.w400,
                            height: 1.15,
                          ),
                        ),
                        Text(
                          "°C",
                          style: TextStyle(
                            fontSize: 10,
                            color: darkTextColor,
                            fontFamily: 'Rubik',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () {
                  setState(() {
                    _temperature = "--";
                    _getWeather();
                  });
                },
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  searchGoogle("weather");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // helper methods
  Future<void> _getBatteryPercentage() async {
    var battery = await BatteryInfoPlugin().androidBatteryInfo;
    int? batteryLevel = battery!.batteryLevel;

    setState(() {
      _batteryLevel = batteryLevel!;
    });
  }

  Future<void> _getWeather() async {
    if (!await Permission.location.isGranted) {
      await Permission.location.request();
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low);
    Weather weather = await wf.currentWeatherByLocation(
      position.latitude,
      position.longitude,
    );

    _prefs.setString(
        prefsWeather, weather.temperature!.celsius!.toInt().toString());

    setState(() {
      _temperature = weather.temperature!.celsius!.toInt().toString();
    });
  }

  // native methods
  Future<void> searchGoogle(String query) async {
    try {
      await _channel.invokeMethod(methodSearchGoogle, {'query': query});
    } catch (e) {
      // print('Error invoking searchGoogle method: $e');
    }
  }

  Future<void> openAppByPackageName(String packageName) async {
    try {
      await _channel.invokeMethod(methodOpenApp, {'packageName': packageName});
    } catch (e) {
      // print('error in launching app $e');
    }
  }

  static const MethodChannel _channel = MethodChannel('main_channel');
}

class ClockWidget extends StatelessWidget {
  const ClockWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (context, snapshot) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              child: Text(
                formattedTime(DateTime.now()),
                style: TextStyle(
                  fontSize: 72,
                  color: lightTextColor,
                  fontFamily: 'Rubik',
                  fontWeight: FontWeight.w500,
                  height: .9,
                ),
              ),

              // date clicked
              onTap: () {
                FlutterAlarmClock.showAlarms();
              },
            ),
            Container(
              width: 5,
            ),
            Text(
              getTimeAbbr(DateTime.now()),
              style: TextStyle(
                fontSize: 22,
                color: darkTextColor,
                fontFamily: 'Rubik',
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        );
      },
    );
  }

  String formattedTime(DateTime dateTime) {
    int hour = dateTime.hour;
    int minute = dateTime.minute;
    return '${hour > 12 ? hour - 12 : hour}:${minute > 9 ? minute : '0$minute'}';
  }

  String getTimeAbbr(DateTime dateTime) {
    int hour = dateTime.hour;
    return hour > 12 ? 'PM' : 'AM';
  }
}
