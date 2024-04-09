import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:battery_info/battery_info_plugin.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_alarm_clock/flutter_alarm_clock.dart';
import 'package:mlauncher/variables/colors.dart';
import 'package:mlauncher/variables/strings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:weather/weather.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _batteryLevel = 0;
  int _temperature = 0;
  WeatherFactory wf = WeatherFactory(WEATHERMAP_API_KEY);

  late Timer _timerOneMinute;

  @override
  void initState() {
    _getWeather();
    _getBatteryPercentage();

    _timerOneMinute = Timer.periodic(
      const Duration(minutes: 1),
      (Timer timer) {
        // these methods are called every minute
        _getWeather();
        _getBatteryPercentage();
      },
    );

    super.initState();
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
            Container(height: 20),
            Expanded(child: Container()),
            // apps
            Expanded(child: Container()),
            bottomIcons(),
            Container(height: 20),
          ],
        ),
      ),
    );
  }

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

            // GALLERY_______________________________________
            GestureDetector(
              child: Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: opaqueBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.photo_rounded,
                  size: 34.0,
                  color: lightTextColor,
                ),
              ),
              onTap: () async {
                openGallery();
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
                  openAppByPackageName("com.google.android.gm");
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
                          color: lightTextColor,
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(width: 70),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "${DateTime.now().day.toString()} ${DateFormat.MMMM().format(DateTime.now())}",
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
                      color: lightTextColor,
                      fontFamily: 'Rubik',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Container(width: 70),
              Column(
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
                        _temperature.toString(),
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
                          color: lightTextColor,
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.w400,
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

    setState(() {
      _temperature = weather.temperature!.celsius!.toInt();
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

  Future<void> openGallery() async {
    try {
      await _channel.invokeMethod(methodOpenGallery);
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
                color: lightTextColor,
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
