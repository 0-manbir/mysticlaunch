import 'dart:io';
import 'dart:ui';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mysticlaunch/helpers/grid_view.dart';
import 'package:mysticlaunch/variables/colors.dart';
import 'package:mysticlaunch/variables/strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RightScreen extends StatefulWidget {
  const RightScreen({super.key});

  @override
  State<RightScreen> createState() => _RightScreenState();
}

class _RightScreenState extends State<RightScreen> {
  late SharedPreferences _prefs;

  late List<String> thisDayTasksList = [];
  late List<String> repetitiveTasksList = [];

  @override
  void initState() {
    _initSharedPreferences();
    super.initState();
  }

  void _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    getRightScreenApps();
    getTasksList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          children: [
            Container(height: 12),
            quickWidgets(context),
            Container(height: 18),
            tasksListView(context),
            Expanded(child: Container()),
            rightScreenAppsWidget(context),
          ],
        ),
      ),
    );
  }

  // right screen apps -------------------------------------------------------------------------------------------------
  List<String> rightScreenAppsPackageNames = List.generate(10, (index) => '');

  Widget rightScreenAppsWidget(BuildContext buildContext) {
    double screenWidth = MediaQuery.of(buildContext).size.width;
    return SizedBox(
      height: 200,
      width: screenWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 20.0,
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
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

  // task view-----------------------------------------------------------------------------------------------

  Widget tasksListView(BuildContext buildContext) {
    double screenWidth = MediaQuery.of(buildContext).size.width;

    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.only(bottom: 16.0),
        width: screenWidth - 32,
        decoration: BoxDecoration(
          color: opaqueBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              height: 10,
            ),
            Text(
              "tasks - ${DateFormat.MMM().format(DateTime.now()).toLowerCase()} ${DateTime.now().day}",
              style: TextStyle(
                color: darkTextColor,
                fontFamily: 'Rubik',
                fontSize: 16,
              ),
            ),
            Container(
              height: 5,
            ),

            // todo list---------------
            SizedBox(
              height: 200,
              child: Center(
                child: getTasksListView(),
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        HapticFeedback.mediumImpact();
        addThisDayTask(buildContext);
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();

        // update tasks
        setState(() async {
          await _prefs.setInt(prefsTasksDate, DateTime.now().day - 1);
          getTasksList();
        });
      },
    );
  }

  Widget getTasksListView() {
    if (thisDayTasksList.isEmpty) {
      return Text(
        "all tasks\ncompleted!",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: lightTextColor,
          fontFamily: 'Rubik',
          fontSize: 24,
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: thisDayTasksList.length,
      itemBuilder: (BuildContext context, int index) {
        if (_prefs.containsKey(prefsTasksThisDay)) {
          return taskWidget(
            thisDayTasksList[index],
            index,
            context,
          );
        } else {
          _prefs.setStringList(prefsTasksRepetitive, []);
          _prefs.setStringList(prefsTasksThisDay, []);
          _prefs.setInt(prefsTasksDate, DateTime.now().day - 1);
        }
        return Container();
      },
    );
  }

  void getTasksList() {
    if (!_prefs.containsKey(prefsTasksThisDay)) {
      _prefs.setStringList(prefsTasksThisDay, []);
    }
    if (!_prefs.containsKey(prefsTasksRepetitive)) {
      _prefs.setStringList(prefsTasksRepetitive, []);
    }
    if (!_prefs.containsKey(prefsTasksDate)) {
      _prefs.setInt(prefsTasksDate, DateTime.now().day - 1);
    }

    List<String> thisDayTasksListTemp =
        _prefs.getStringList(prefsTasksThisDay)!;
    List<String> repetitiveTasksListTemp =
        _prefs.getStringList(prefsTasksRepetitive)!;
    int tempPrevDay = _prefs.getInt(prefsTasksDate)!;

    if (tempPrevDay == DateTime.now().day) {
      // same day
      setState(() {
        thisDayTasksList = thisDayTasksListTemp;
        repetitiveTasksList = repetitiveTasksListTemp;
      });
    } else {
      // different day
      _prefs.setInt(prefsTasksDate, DateTime.now().day);
      List<String> remainingTasks = [];

      for (int i = 0; i < thisDayTasksListTemp.length; i++) {
        String task = thisDayTasksListTemp[i];
        if (task.replaceAll(' ', '') == '') continue;
        remainingTasks.add(task.trim());
      }

      // not needed, but does not display the empty elements
      for (int i = 0; i < repetitiveTasksListTemp.length; i++) {
        String task = repetitiveTasksListTemp[i].trim();
        if (task != '' && !remainingTasks.contains(task)) {
          remainingTasks.add(task);
        }
      }

      _prefs.setStringList(prefsTasksThisDay, remainingTasks);

      setState(() {
        thisDayTasksList = remainingTasks;
        repetitiveTasksList = repetitiveTasksListTemp;
      });
    }
  }

  final TextEditingController _thisDayTaskNameController =
      TextEditingController();
  final TextEditingController _repetitiveTaskController =
      TextEditingController();

  void addThisDayTask(BuildContext buildContext) {
    double screenWidth = MediaQuery.of(buildContext).size.width;
    showModalBottomSheet(
      context: buildContext,
      builder: (context) {
        return Container(
          width: screenWidth,
          decoration: BoxDecoration(
            color: lightBackgroundColor,
          ),
          child: Column(
            children: [
              Container(height: 25),
              Text(
                "name of the task:",
                style: TextStyle(
                  color: lightTextColor,
                  fontFamily: 'Rubik',
                  fontSize: 16,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _thisDayTaskNameController,
                  maxLines: 1,
                  textInputAction: TextInputAction.done,
                  cursorColor: lightTextColor,
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    color: lightTextColor,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    alignLabelWithHint: true,
                    labelText: "task...",
                    labelStyle: TextStyle(
                      fontFamily: 'Rubik',
                      color: lightTextColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Container(height: 12),
              ElevatedButton(
                onPressed: () async {
                  thisDayTasksList.add(_thisDayTaskNameController.text);
                  await _prefs.setStringList(
                      prefsTasksThisDay, thisDayTasksList);
                  setState(() {
                    getTasksList();
                    _thisDayTaskNameController.text = "";
                    Navigator.pop(buildContext);
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(lightTextColor),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "save",
                    style: TextStyle(
                      color: backgroundColor,
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
  }

  void editRepetitiveTasks(BuildContext buildContext) {
    double screenWidth = MediaQuery.of(buildContext).size.width;
    _repetitiveTaskController.text =
        _prefs.getStringList(prefsTasksRepetitive)!.join(",");

    showModalBottomSheet(
      context: buildContext,
      builder: (context) {
        return Container(
          width: screenWidth,
          color: lightBackgroundColor,
          child: Column(
            children: [
              Container(height: 25),
              Text(
                "daily tasks (seperate with a comma):",
                style: TextStyle(
                  color: lightTextColor,
                  fontFamily: 'Rubik',
                  fontSize: 16,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _repetitiveTaskController,
                  textInputAction: TextInputAction.newline,
                  cursorColor: lightTextColor,
                  minLines: 3,
                  maxLines: 3,
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    color: lightTextColor,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    alignLabelWithHint: true,
                    labelText: "daily tasks",
                    labelStyle: TextStyle(
                      fontFamily: 'Rubik',
                      color: lightTextColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Container(height: 20),
              ElevatedButton(
                onPressed: () {
                  List<String> list = _repetitiveTaskController.text == ""
                      ? []
                      : _repetitiveTaskController.text.split(",");
                  _prefs.setStringList(prefsTasksRepetitive, list);

                  if (Navigator.canPop(buildContext)) {
                    Navigator.pop(buildContext);
                  }

                  setState(() {
                    getTasksList();
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(lightTextColor),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "save",
                    style: TextStyle(
                      color: backgroundColor,
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
  }

  Widget taskWidget(String task, int index, BuildContext buildContext) {
    double screenWidth = MediaQuery.of(buildContext).size.width;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(width: 10),
          Expanded(
            child: GestureDetector(
              child: Text(
                task,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 16,
                  color: lightTextColor,
                ),
              ),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Container(
                      padding: const EdgeInsets.all(32.0),
                      width: screenWidth,
                      color: lightBackgroundColor,
                      child: Center(
                        child: Text(
                          task,
                          style: TextStyle(
                            fontFamily: 'Rubik',
                            fontSize: 20,
                            color: lightTextColor,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(width: 10),
          GestureDetector(
            child: Icon(
              Icons.delete_rounded,
              color: darkTextColor,
            ),
            onTap: () {
              HapticFeedback.heavyImpact();

              thisDayTasksList.removeAt(index);
              _prefs.setStringList(prefsTasksThisDay, thisDayTasksList);
              setState(() {
                getTasksList();
              });
            },
          ),
          Container(width: 10),
        ],
      ),
    );
  }

  // quick widgets----------------------------------------------------------------------------------------------------------
  Widget quickWidgets(BuildContext buildContext) {
    double screenWidth = MediaQuery.of(buildContext).size.width;

    return Container(
      height: 70,
      margin: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
      child: Row(
        children: [
          // add a todo item-----------------------------------------------------
          GestureDetector(
            child: Container(
              width: (screenWidth - 32 - 16) / 2,
              decoration: BoxDecoration(
                color: opaqueBackgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(width: 15),
                  Icon(
                    Icons.note_add_rounded,
                    color: darkTextColor,
                    size: 36,
                  ),
                  Container(width: 10),
                  Text(
                    "add a\ntask",
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: lightTextColor,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              HapticFeedback.mediumImpact();
              addThisDayTask(context);
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              editRepetitiveTasks(context);
            },
          ),

          Expanded(child: Container()),

          // add a new snap-----------------------------------------------------
          GestureDetector(
            child: Container(
              width: (screenWidth - 32 - 16) / 2,
              decoration: BoxDecoration(
                color: opaqueBackgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(width: 15),
                  Icon(
                    Icons.image_rounded,
                    color: darkTextColor,
                    size: 36,
                  ),
                  Container(width: 10),
                  Text(
                    "click a\nnew snap",
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: lightTextColor,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              HapticFeedback.mediumImpact();
              DeviceApps.openApp(snapbookPackageName);
            },
          ),
        ],
      ),
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
}
