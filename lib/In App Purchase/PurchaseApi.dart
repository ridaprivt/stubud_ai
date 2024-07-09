// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:learnai/UI/authentication/Login.dart';
import 'package:learnai/UI/home/Home.dart';
import 'package:learnai/UI/subscription/Subscription.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PurchaseApi {
  static const _apiKey = 'goog_eEfECMOmztnUtcygdxFrfCUbbxF';

  static Future init() async {
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(_apiKey));
  }

  static checkCustomerInfo(String uid) async {
    if (uid != null) {
      try {
        final DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final bool subscription = userDoc['subscription'];
        if (subscription) {
          Get.offAll(Home());
        }
        if (!subscription) {
          Get.offAll(Subscription());
        }
      } catch (e) {
        print('Error checking subscription status: $e');
      }
    }
  }

  static Future<dynamic> ErrorDialog(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Ooops!",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500, color: Colors.red),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "You haven't subscribed yet.",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                    fontSize: 16.sp),
              ),
              SizedBox(height: 1.h),
              Text(
                "Ensure that the Play Store account you sign in with matches the account that is signed on.",
                textAlign: TextAlign.justify,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w400),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await GoogleSignIn().signOut();
                await prefs.setBool('firstLaunch', true);
                Get.offAll(Login());
              },
              child: Text(
                "OK",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<bool> restoreSubscription() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      final entitlements = customerInfo.entitlements.active;
      if (entitlements.isEmpty) {
        return false;
      } else {
        return true;
      }
    } on Exception catch (e) {
      return false;
    }
  }

  static Future<List<Package>> fetchOffers() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current!.availablePackages;
      return current;
    } on Exception catch (e) {
      return [];
    }
  }

  static purchasePackage(Package package) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      await Purchases.purchasePackage(package);
      prefs.setBool('isPremium', true);
      subscribed();
    } on Exception catch (e) {
      prefs.setBool('isPremium', false);
    }
  }
}

Future<void> subscribed() async {
  final prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userID');

  if (userId != null) {
    DateTime now = await fetchServerTime();
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'subscription': true,
      'subscriptionStartDate': Timestamp.fromDate(now),
    });
    Get.snackbar(
      'Success',
      'You have successfully subscribed to Premium.',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    Get.offAll(Home());
  }
}

Future<DateTime> fetchServerTime() async {
  final url = Uri.parse('http://worldtimeapi.org/api/timezone/Europe/London');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);
    final dateTimeString = jsonResponse['datetime'];
    return DateTime.parse(dateTimeString);
  } else {
    throw Exception('Failed to load server time');
  }
}
