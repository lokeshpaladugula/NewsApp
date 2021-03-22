import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'home_page.dart';
import 'strings.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
Future<void> scheduleNotification({TimeOfDay notifyTime}) async {
  print("\n\n\n inside \n\n\n");

  String hour = notifyTime.hour < 10
      ? '0' + notifyTime.hour.toString()
      : notifyTime.hour.toString();
  String minute = notifyTime.minute < 10
      ? '0' + notifyTime.minute.toString()
      : notifyTime.minute.toString();
  String year = DateTime.now().year.toString();
  String month = DateTime.now().month < 10
      ? '0' + DateTime.now().month.toString()
      : DateTime.now().month.toString();
  String day = DateTime.now().day < 10
      ? '0' + DateTime.now().day.toString()
      : DateTime.now().day.toString();

  print(hour);
  print(minute);
  print('$year-$month-$day $hour:$minute:00');
  tz.TZDateTime time =
      tz.TZDateTime.parse(tz.local, '$year-$month-$day $hour:$minute:00');
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'channel id',
    'channel name',
    'channel description',
    icon: 'app_icon',
  );
  var iOSPlatformChannelSpecifics = IOSNotificationDetails();
  var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin
      .zonedSchedule(
          0,
          'News App',
          'Its time to explore news around the world.',
          time,
          platformChannelSpecifics,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time)
      .then((value) => print('done'));
}

Future onSelectNotification(String payload) {
  print("\n\nonSelect\n\n");
}

void callbackDispatcher() async {
  Workmanager.executeTask((task, inputData) async {
    print("Native called background task: backgroundTask");
    String url =
        "https://api.nytimes.com/svc/topstories/v2/technology.json?api-key=${Strings.apiKey}";
    try {
      http.Response response = await http.get(url);
      print(response.statusCode);

      if (response.statusCode == HttpStatus.OK) {
        Map decode = json.decode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString("lastUpdatedAt", formatTimeOfDay(TimeOfDay.now()));
        prefs.setString('NewsData', response.body);
        prefs.setBool('backGroundDataFetched', true);
        print(response.statusCode);
      } else {
        print('failed');
      }
    } catch (e) {
      print(e);
    }
    print("done");
    return Future.value(true);
  });
}

void sendRequest() async {
  String url =
      "https://api.nytimes.com/svc/topstories/v2/technology.json?api-key=${Strings.apiKey}";
  try {
    http.Response response = await http.get(url);
    print(response.statusCode);

    if (response.statusCode == HttpStatus.OK) {
      Map decode = json.decode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("lastUpdatedAt", formatTimeOfDay(TimeOfDay.now()));
      prefs.setString('NewsData', response.body);
      prefs.setBool('backGroundDataFetched', true);
      print(response.statusCode);
    } else {
      // failed
      print('failed');
    }
  } catch (e) {
    print(e);
  }
}

String formatTimeOfDay(TimeOfDay tod) {
  final now = new DateTime.now();
  final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
  final format = DateFormat.jm();
  return format.format(dt);
}

// void main() => runApp(new MyApp());
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  var initializationSettingsIOs = IOSInitializationSettings();
  var initSetttings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOs);

  flutterLocalNotificationsPlugin.initialize(initSetttings,
      onSelectNotification: onSelectNotification);

  Workmanager.initialize(
    callbackDispatcher,
  );

  return runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
        },
        child: new MaterialApp(
          title: Strings.appName,
          theme: new ThemeData(
              primarySwatch: Colors.deepOrange, accentColor: Colors.deepOrange),
          home: new MyHomePage(title: Strings.appName),
        ));
  }
}
