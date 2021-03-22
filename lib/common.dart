import 'package:flutter/material.dart';

TimeOfDay timeConvert(String normTime) {
  int hour;
  int minute;
  String ampm = normTime.substring(normTime.length - 2);
  String result = normTime.substring(0, normTime.indexOf(' '));
  if (ampm == 'AM' && int.parse(result.split(":")[1]) != 12) {
    hour = int.parse(result.split(':')[0]);
    if (hour == 12) hour = 0;
    minute = int.parse(result.split(":")[1]);
  } else {
    hour = int.parse(result.split(':')[0]) - 12;
    if (hour <= 0) {
      hour = 24 + hour;
    }
    minute = int.parse(result.split(":")[1]);
  }
  print("$hour : $minute");
  return TimeOfDay(hour: hour, minute: minute);
}
