// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learnai/UI/authentication/Login.dart';
import 'package:learnai/UI/home/Home.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      checkFirstLaunch();
    });
  }

  @override
  Future<void> checkFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userID');
    Get.offAll(Login());
    if (userId != null) {
      Get.offAll(Home());
    } else {
      Get.offAll(Login());
    }
  }

  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      backgroundColor: Color(0xff1ED760),
      body: Center(
        child: Image.asset(
          'assets/LOGO.png',
          width: 60.w,
        ),
      ),
    ));
  }
}
