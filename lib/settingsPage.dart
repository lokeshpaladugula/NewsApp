import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'common.dart';
import 'main.dart';
import 'post.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'strings.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:workmanager/workmanager.dart';

class SettingsHome extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _SettingsHome();
}

class _SettingsHome extends State<SettingsHome> {
  bool backGroundRun = false;
  bool notifyMe = false;
  bool isLoading = true;

  TimeOfDay notifyTime = TimeOfDay.now();
  TextEditingController _timeController = TextEditingController();

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  @override
  void initState() {
    super.initState();
    loadData();
  }

  void _onClickeBackGroundFetch(bool enable) {
    if (enable) {
      Workmanager.registerOneOffTask("1", "simpleTask",
          initialDelay: Duration(seconds: 10),
          backoffPolicy: BackoffPolicy.exponential,
          backoffPolicyDelay: Duration(seconds: 10),
          constraints: Constraints(
            networkType: NetworkType.connected,
            // requiresBatteryNotLow: true,
            requiresCharging: true,
            requiresDeviceIdle: true,
            // requiresStorageNotLow: true
          ));
    } else {
      print('cancelled');
      Workmanager.cancelByUniqueName("1");
    }
  }

  loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String tempTime;
    setState(() {
      backGroundRun = (prefs.getBool('backGroundRun') ?? false);
      notifyMe = (prefs.getBool('notifyMe') ?? false);
      tempTime = (prefs.getString('notifyTime'));
      print(tempTime);
      if (tempTime != null) {
        notifyTime = timeConvert(tempTime);
        _timeController.text = notifyTime.format(context).toString();
      } else {
        notifyTime = TimeOfDay.now();
        _timeController.text = notifyTime.format(context).toString();
      }
      isLoading = false;
    });
  }

  saveLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("backGroundRun", backGroundRun);
    prefs.setBool("notifyMe", notifyMe);
    prefs.setString("notifyTime", notifyTime.format(context).toString());

    print("saved");
  }

  Future<Null> cancleRemainder() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }

  Future<Null> _selectTime(BuildContext context) async {
    final TimeOfDay picked = await showTimePicker(
      context: context,
      initialTime: notifyTime,
    );
    if (picked != null)
      setState(() {
        notifyTime = picked;
        _timeController.text = picked.format(context).toString();
      });
    saveLocalData();
    // cancleRemainder();
    scheduleNotification(notifyTime: notifyTime);
  }

  @override
  Widget build(BuildContext context) => new Scaffold(
        appBar: new AppBar(
          title: new Text(
            'Settings',
            style: new TextStyle(fontSize: 16.0),
            overflow: TextOverflow.fade,
          ),
        ),
        body: new Scaffold(
          // key: _scaffoldKey,
          body: isLoading
              ? new Center(child: CircularProgressIndicator())
              : _listOfItems(),
        ),
      );

  Widget _listOfItems() {
    return new Container(
      margin: new EdgeInsets.all(10.0),
      child: new Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enable background fetch',
                style: new TextStyle(fontSize: 15.0),
              ),
              Switch(
                  value: backGroundRun,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (value) {
                    setState(() {
                      backGroundRun = value;
                      saveLocalData();
                      // _onClickEnable(backGroundRun);
                      _onClickeBackGroundFetch(backGroundRun);
                    });
                  }),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reminder',
                style: new TextStyle(fontSize: 15.0),
              ),
              Switch(
                  value: notifyMe,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (value) {
                    setState(() {
                      notifyMe = value;
                      if (notifyMe == true) {
                        scheduleNotification(notifyTime: notifyTime);
                      } else {
                        cancleRemainder();
                      }
                      saveLocalData();
                    });
                  }),
            ],
          ),
          Visibility(
              visible: notifyMe,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remind Time',
                    style: new TextStyle(fontSize: 15.0),
                  ),
                  GestureDetector(
                    onTap: () {
                      _selectTime(context);
                    },
                    child: Container(
                      width: 150,
                      alignment: Alignment.center,
                      child: TextFormField(
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.end,
                        enabled: false,
                        keyboardType: TextInputType.text,
                        controller: _timeController,
                        decoration: InputDecoration(
                            // border: OutlineInputBorder(),
                            disabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide.none),
                            // labelText: 'Time',
                            contentPadding: EdgeInsets.all(5)),
                      ),
                    ),
                  ),
                ],
              ))
        ],
      ),
    );
  }
}
