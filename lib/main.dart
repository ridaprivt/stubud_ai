import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:learnai/In%20App%20Purchase/PurchaseApi.dart';
import 'package:learnai/Notifications/FirebaseNotifications.dart';
import 'package:learnai/UI/splash_screen/SplashScreen.dart';
import 'package:learnai/firebase_options.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  MobileAds.instance.initialize();
  AwesomeNotifications().initialize(
    'resource://drawable/res_app_icon',
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
        defaultColor: Colors.green,
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      )
    ],
  );
  await PurchaseApi.init();

  NotificationService.initNotification();
  await FirebaseMessaging.instance.getInitialMessage();
  await FirebaseMessaging.instance.requestPermission();
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Handle foreground messages
    if (message.notification != null) {
      NotificationService.showLocalNotification(
          message.notification!.title ?? '',
          message.notification!.body ?? '',
          'payload');
    }
  });
  getToken();

  Get.put(GlobalController());
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    requestNotificationPermission();
  }

  void requestNotificationPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(builder: (context, orientation, screenType) {
      return Obx(() {
        return GetMaterialApp(
          theme: ThemeData(
            primaryColor: globalController.primaryColor.value,
            scaffoldBackgroundColor: Colors.white,
            pageTransitionsTheme: PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          debugShowCheckedModeBanner: false,
          home: SplashScreen(),
        );
      });
    });
  }
}

class GlobalController extends GetxController {
  Rx<Color> primaryColor = Color(0xff1ED760).obs;

  @override
  void onInit() {
    super.onInit();
    _loadPrimaryColor();
  }

  void _loadPrimaryColor() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? colorValue = prefs.getInt('primaryColor');
    if (colorValue != null) {
      primaryColor.value = Color(colorValue);
    }
  }

  void _savePrimaryColor(Color color) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primaryColor', color.value);
  }

  void setPrimaryColor(Color color) {
    primaryColor.value = color;
    _savePrimaryColor(color);
  }
}

final GlobalController globalController = Get.find();
void getToken() {
  FirebaseMessaging.instance.getToken().then((value) {
    print("TOKEN IS :: :: $value");
  });
}
