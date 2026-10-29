import 'package:adhan/adhan.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class PrayerService {
  static const _latKey = 'prayer_lat';
  static const _lngKey = 'prayer_lng';
  static const _enabledKey = 'prayer_notifications_enabled';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tzdata.initializeTimeZones();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }

  Future<void> requestPermission() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> saveLocation(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latKey, lat);
    await prefs.setDouble(_lngKey, lng);
  }

  Future<Map<String, double>?> getLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_latKey);
    final lng = prefs.getDouble(_lngKey);
    if (lat == null || lng == null) return null;
    return {'lat': lat, 'lng': lng};
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  PrayerTimes? todayTimes(double lat, double lng) {
    final coordinates = Coordinates(lat, lng);
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;
    return PrayerTimes.today(coordinates, params);
  }

  Future<void> scheduleTodayNotifications(double lat, double lng) async {
    await _notifications.cancelAll();
    final times = todayTimes(lat, lng);
    if (times == null) return;

    final prayers = {
      'Fajr': times.fajr,
      'Dhuhr': times.dhuhr,
      'Asr': times.asr,
      'Maghrib': times.maghrib,
      'Isha': times.isha,
    };

    var id = 0;
    for (final entry in prayers.entries) {
      final time = entry.value;
      if (time.isBefore(DateTime.now())) continue;
      final scheduled = tz.TZDateTime.from(time, tz.local);
      await _notifications.zonedSchedule(
        id++,
        '${entry.key} Prayer Time',
        'It is time for ${entry.key} prayer.',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_times_v3',
            'Prayer Times',
            channelDescription: 'Notifications for daily prayer times',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }
}
