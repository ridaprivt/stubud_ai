import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:learnai/UI/authentication/Login.dart';
import 'package:learnai/UI/authentication/SetUp.dart';
import 'package:learnai/UI/authentication/UserInfo.dart';
import 'package:learnai/UI/splash_screen/SplashScreen.dart';
import 'package:learnai/firebase_options.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  MobileAds.instance.initialize();
  Get.put(GlobalController()); // Initialize GlobalController
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(builder: (context, orientation, screenType) {
      return GetMaterialApp(
        theme: ThemeData(
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

  void togglePrimaryColor() {
    if (primaryColor.value == Color(0xff1ED760)) {
      primaryColor.value = Color(0xff800080);
    } else {
      primaryColor.value = Color(0xff1ED760);
    }
    _savePrimaryColor(primaryColor.value);
  }
}

final GlobalController globalController = Get.put(GlobalController());
