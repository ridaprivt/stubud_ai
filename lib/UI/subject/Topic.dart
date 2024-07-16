import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learnai/Google%20Ads/BannerAd.dart';
import 'package:learnai/Google%20Ads/InterstitialAd.dart';
import 'package:learnai/UI/subject/TopicDetails.dart';
import 'package:learnai/Widgets/AppBar.dart';
import 'package:learnai/main.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Topic extends StatefulWidget {
  final String topic;
  final String topicIntro;
  final List<String> subTopics;

  Topic(
      {required this.topic, required this.topicIntro, required this.subTopics});

  @override
  State<Topic> createState() => _TopicState();
}

class _TopicState extends State<Topic> {
  List<bool> _isLoading = [];
  bool subscription = true;

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

  @override
  void initState() {
    super.initState();
    _initializeData();
    _isLoading = List<bool>.filled(widget.subTopics.length, false);
  }

  Future<void> fetchSubTopicDetails(String subTopic, int index) async {
    setState(() {
      _isLoading[index] = true;
    });
    final String apiUrl =
        "https://us-central1-chatbot-b81d7.cloudfunctions.net/afnan-gpt-2";
    Map<String, String> headers = {"Content-Type": "application/json"};

    List<Map<String, dynamic>> messages = [
      {
        'role': 'user',
        'content':
            'Explain the topic $subTopic. Include examples and exercises.'
      }
    ];

    Map<String, dynamic> payload = {
      "data": {"conversation": messages}
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData.containsKey("result") &&
            responseData["result"].containsKey("response")) {
          final String responseText =
              responseData["result"]["response"].toString();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TopicDetails(subTopic: subTopic, details: responseText),
            ),
          );
        } else {
          print('Unexpected response format.');
        }
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
    setState(() {
      _isLoading[index] = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: MyAppBar(),
        body: ListView(
          padding: EdgeInsets.all(16.0),
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
            Container(
              padding: EdgeInsets.all(17.sp),
              margin: EdgeInsets.symmetric(vertical: 10.sp),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17.sp),
                color: globalController.primaryColor.value.withOpacity(0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.topic,
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    widget.topicIntro,
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Topics',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.subTopics.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 10.sp, horizontal: 3.sp),
                  child: subTopic(index),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget subTopic(int index) {
    return InkWell(
      onTap: () {
        fetchSubTopicDetails(widget.subTopics[index], index);
      },
      child: Container(
        padding: EdgeInsets.all(13.sp),
        decoration: BoxDecoration(
          color: Color(0xffEDEDED),
          borderRadius: BorderRadius.circular(10.sp),
        ),
        child: _isLoading[index]
            ? Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            : Text(
                widget.subTopics[index],
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 16.sp,
                ),
              ),
      ),
    );
  }
}
