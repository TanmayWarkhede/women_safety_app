import 'dart:async';
import 'dart:ui';

import 'package:background_location/background_location.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shake/shake.dart';
import 'package:telephony/telephony.dart';
import 'package:vibration/vibration.dart';
import 'package:women_safety_app/db/db_services.dart';
import 'package:women_safety_app/model/contactsm.dart';

/// Send SOS SMS to all saved contacts
Future<void> sendMessage(String messageBody) async {
  List<TContact> contactList = await DatabaseHelper().getContactList();
  if (contactList.isEmpty) {
    Fluttertoast.showToast(msg: "No emergency contacts found");
    return;
  }

  for (var contact in contactList) {
    try {
      await Telephony.backgroundInstance.sendSms(
        to: contact.number,
        message: messageBody,
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to send to ${contact.number}");
    }
  }
  Fluttertoast.showToast(msg: "SOS sent successfully");
}

/// Initialize background service
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  AndroidNotificationChannel channel = const AndroidNotificationChannel(
    "script_academy",
    "Foreground Service",
    description: "Used for important background tasks",
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    iosConfiguration: IosConfiguration(),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: "script_academy",
      initialNotificationTitle: "Women Safety App",
      initialNotificationContent: "Background service initializing",
      foregroundServiceNotificationId: 888,
    ),
  );

  service.startService();
}

ShakeDetector? _detector;
Location? _currentLocation;
DateTime? _lastNotificationTime;

/// Background service entry point
@pragma('vm-entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Setup location updates
  await BackgroundLocation.setAndroidNotification(
    title: "Location tracking enabled",
    message: "Tracking in background",
    icon: '@mipmap/ic_logo',
  );

  BackgroundLocation.startLocationService(distanceFilter: 20);

  BackgroundLocation.getLocationUpdates((location) {
    _currentLocation = location;
    _updateNotification(flutterLocalNotificationsPlugin);
  });

  // Setup shake detector only once
  if (_detector == null) {
    _detector = ShakeDetector.autoStart(
      shakeThresholdGravity: 7,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
      minimumShakeCount: 1,
      onPhoneShake: () async {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 1000);
        }

        // Fallback if background location not ready
        if (_currentLocation == null) {
          Position pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          _currentLocation = Location(
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
        }

        if (_currentLocation != null) {
          String messageBody =
              "🚨 I need help! My location: https://www.google.com/maps/search/?api=1&query=${_currentLocation!.latitude},${_currentLocation!.longitude}";
          await sendMessage(messageBody);
        } else {
          Fluttertoast.showToast(msg: "Unable to fetch location");
        }
      },
    );
  }
}

/// Update foreground notification at most once every 30s
void _updateNotification(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  if (_lastNotificationTime != null &&
      DateTime.now().difference(_lastNotificationTime!).inSeconds < 30) {
    return; // prevent too frequent updates
  }
  _lastNotificationTime = DateTime.now();

  await flutterLocalNotificationsPlugin.show(
    888,
    "Women Safety App",
    _currentLocation == null
        ? "Please enable location"
        : "Shake enabled | Last location: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}",
    const NotificationDetails(
      android: AndroidNotificationDetails(
        "script_academy",
        "Foreground Service",
        channelDescription: "Used for important background tasks",
        icon: 'ic_bg_service_small',
        ongoing: true,
      ),
    ),
  );
}
