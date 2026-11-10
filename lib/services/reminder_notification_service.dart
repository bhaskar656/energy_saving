import 'package:energy_saving/models/reminder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

abstract interface class ReminderNotificationService {
  bool get isSupported;
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> schedule(Reminder reminder);
  Future<void> cancel(int reminderId);
  Future<void> cancelAll();
}

class LocalReminderNotificationService implements ReminderNotificationService {
  LocalReminderNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'energy_reminders';
  static const _channelName = 'Energy reminders';
  static const _channelDescription = 'Daily appliance energy reminders';

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initialization;

  @override
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (!isSupported) return;

    timezone_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    timezone.setLocalLocation(timezone.getLocation(localTimezone.identifier));

    final initialized = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    if (initialized == false) {
      throw StateError('Local notifications could not be initialized.');
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    await initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return result ?? true;
    }

    final result = await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return result ?? false;
  }

  @override
  Future<void> schedule(Reminder reminder) async {
    final id = reminder.id;
    if (id == null) throw ArgumentError.value(id, 'reminder.id');
    if (!isSupported || !reminder.isEnabled) return;
    await initialize();

    final now = timezone.TZDateTime.now(timezone.local);
    var scheduledDate = timezone.TZDateTime(
      timezone.local,
      now.year,
      now.month,
      now.day,
      reminder.reminderTime.hour,
      reminder.reminderTime.minute,
    );
    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: reminder.title,
      body: reminder.description.isEmpty
          ? 'Remember to check your ${reminder.appliance}.'
          : reminder.description,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'reminder:$id',
    );
  }

  @override
  Future<void> cancel(int reminderId) async {
    if (!isSupported) return;
    await initialize();
    await _plugin.cancel(id: reminderId);
  }

  @override
  Future<void> cancelAll() async {
    if (!isSupported) return;
    await initialize();
    await _plugin.cancelAll();
  }
}