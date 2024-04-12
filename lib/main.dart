import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // void _onPageChanged(index) {
  //   setState(() {});
  // }

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
                  // TODO open app drawer
                }
              },

              // pages-------------------------------------------------
              child: PageView(
                controller: _pageController,
                // onPageChanged: _onPageChanged,
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

  // native methods
  Future<void> expandNotification() async {
    try {
      await _channel.invokeMethod(methodExpandNotifications);
    } catch (e) {
      // print('Error invoking expand method: $e');
    }
  }

  static const MethodChannel _channel = MethodChannel('main_channel');
}
