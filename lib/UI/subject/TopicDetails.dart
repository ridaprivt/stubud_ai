import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learnai/Google%20Ads/BannerAd.dart';
import 'package:learnai/Google%20Ads/InterstitialAd.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:learnai/Widgets/AppBar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopicDetails extends StatefulWidget {
  final String subTopic;
  final String details;

  TopicDetails({required this.subTopic, required this.details});

  @override
  State<TopicDetails> createState() => _TopicDetailsState();
}

class _TopicDetailsState extends State<TopicDetails> {
  bool subscription = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userID');

    if (userId != null) {
      try {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        subscription = userDoc['subscription'];
      } catch (e) {
        print('Error checking subscription status: $e');
      }
    }
    if (!subscription) {
      AdsServices().init();
      GoogleAds().initialize();
      GoogleAds().showInterstitialAd();
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (!subscription)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.sp),
                child: Column(
                  children: [
                    AdsServices().MyAd(context),
                    SizedBox(height: 3.h),
                  ],
                ),
              ),
            Text(
              widget.subTopic,
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              widget.details,
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
