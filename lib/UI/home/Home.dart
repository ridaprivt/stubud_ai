import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:learnai/Google%20Ads/BannerAd.dart';
import 'package:learnai/Google%20Ads/InterstitialAd.dart';
import 'package:learnai/UI/ai_tutor/AiTutor.dart';
import 'package:learnai/UI/chat_screen/Chat.dart';
import 'package:learnai/UI/quiz/Quiz.dart';
import 'package:learnai/UI/subject/Subject.dart';
import 'package:learnai/Widgets/AppBar.dart';
import 'package:learnai/Widgets/QuizWidget.dart';
import 'package:learnai/main.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool fact = false;
  String result = '';
  Map<String, String> subjectFacts = {};
  List<String> mysubjects = [];
  PageController _pageController = PageController();
  bool load = false;
  late Timer _adTimer;
  bool subscription = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    loadCachedFacts();
  }

  void dispose() {
    super.dispose();
    if (!subscription) {
      AdsServices().disposeAds();
      GoogleAds().dispose();
      _adTimer.cancel();
    }
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
      _startAdTimer();
    }
  }

  void _startAdTimer() {
    _adTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      GoogleAds().showInterstitialAd();
    });
  }

  Future<void> loadCachedFacts() async {
    setState(() {
      load = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userID') ?? 'unknown';

    // Fetch user document from Firestore
    try {
      DocumentSnapshot userDocSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      var userDoc = userDocSnapshot.data() as Map<String, dynamic>;

      if (userDoc != null && userDoc.containsKey('subjects')) {
        mysubjects = List<String>.from(userDoc['subjects']);
      }
    } catch (e) {
      print("Error fetching user document: $e");
    }

    final currentTime = DateTime.now().millisecondsSinceEpoch;

    for (String subject in mysubjects) {
      final cachedFact = prefs.getString('fact_$subject');
      final lastFetchTime = prefs.getInt('lastFetchTime_$subject');

      if (cachedFact != null && lastFetchTime != null) {
        final durationSinceLastFetch = currentTime - lastFetchTime;
        if (durationSinceLastFetch < 24 * 60 * 60 * 1000) {
          setState(() {
            subjectFacts[subject] = cachedFact;
          });
          continue;
        }
      }
      await fetchInterestingFact(subject);
    }
    setState(() {
      load = false;
    });
  }

  Future<void> fetchInterestingFact(String subject) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fact = true;
    });

    List<Map<String, dynamic>> messages = [
      {
        'role': 'user',
        'content': 'Give an short interesting fact about $subject.',
      },
    ];

    final String apiUrl =
        "https://us-central1-chatbot-b81d7.cloudfunctions.net/afnan-gpt-2";

    Map<String, String> headers = {
      "Content-Type": "application/json",
    };

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
          final fact = responseData["result"]["response"].toString();

          // Cache the fact and timestamp
          prefs.setString('fact_$subject', fact);
          prefs.setInt(
              'lastFetchTime_$subject', DateTime.now().millisecondsSinceEpoch);

          setState(() {
            subjectFacts[subject] = fact;
          });
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
      fact = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: MyAppBar(),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h),
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
              Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(19.sp),
                    margin: EdgeInsets.symmetric(horizontal: 15.sp),
                    height: 20.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.sp),
                        color: const Color.fromARGB(255, 59, 59, 59)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Spacer(),
                        Text(
                          'Bring School\nto One Screen',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20.sp),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Why buy loads of stationary\nand books when you have LearnAi',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 13.sp),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.sp),
                      child: Image.asset(
                        'assets/bag.png',
                        width: 58.w,
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(height: 2.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 17.sp),
                child: Text(
                  'Subject Trouble?',
                  style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 19.sp),
                ),
              ),
              SizedBox(height: 2.h),
              load
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.grey,
                      ),
                    )
                  : Container(
                      height: 47.sp,
                      child: ListView.builder(
                        padding: EdgeInsets.only(right: 3.w),
                        scrollDirection: Axis.horizontal,
                        itemCount: mysubjects.length,
                        itemBuilder: (context, index) {
                          return subjectWidget(
                            mysubjects[index],
                          );
                        },
                      ),
                    ),
              SizedBox(height: 2.h),
              InkWell(
                onTap: () {
                  Get.to(AiTutor());
                },
                child: Container(
                  padding: EdgeInsets.all(17.sp),
                  margin: EdgeInsets.symmetric(horizontal: 15.sp),
                  width: double.infinity,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17.sp),
                      color: Colors.black),
                  child: Row(
                    children: [
                      Text(
                        'AI Tutor  ',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18.sp),
                      ),
                      Image.asset(
                        'assets/ai.png',
                        height: 21.sp,
                      ),
                      Spacer(),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Container(
                height: 23.h,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: mysubjects.length,
                  itemBuilder: (context, index) {
                    final subject = mysubjects[index];
                    final factText = subjectFacts[subject] ?? 'Loading...';
                    return InterestingFactCard(
                      subject: subject,
                      factText: factText,
                      fact: fact,
                    );
                  },
                ),
              ),
              SizedBox(height: 1.h),
              load
                  ? Container()
                  : Center(
                      child: SmoothPageIndicator(
                        controller: _pageController, // PageController
                        count: mysubjects.length,
                        effect: WormEffect(
                          dotHeight: 10.sp,
                          dotWidth: 10.sp,
                          spacing: 16.sp,
                          dotColor: Colors.grey,
                          activeDotColor: Colors.black,
                        ),
                      ),
                    ),
              SizedBox(height: 2.h),
              InkWell(
                onTap: () {
                  Get.to(ChatPage());
                },
                child: Container(
                  padding: EdgeInsets.all(19.sp),
                  margin: EdgeInsets.symmetric(horizontal: 15.sp),
                  width: double.infinity,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.sp),
                      color: globalController.primaryColor.value),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What’s bothering you?',
                        style: GoogleFonts.poppins(
                            color: Colors.black,
                            height: 3.sp,
                            fontWeight: FontWeight.w600,
                            fontSize: 18.sp),
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Image.asset(
                            'assets/search.png',
                            height: 5.h,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 15.sp, vertical: 12.sp),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20.sp),
                                  border: Border.all(
                                      color: Colors.black, width: 5.sp)),
                              child: InkWell(
                                onTap: () {
                                  Get.to(ChatPage());
                                },
                                child: Text(
                                  'Enter your prompt...',
                                  style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontSize: 15.5.sp,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  subjectWidget(String name) {
    return InkWell(
      onTap: () {
        Get.to(() => Subject(subjectName: name));
      },
      child: Container(
        padding: EdgeInsets.all(10.sp),
        margin: EdgeInsets.only(left: 15.sp),
        width: 47.sp,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 3.sp),
          borderRadius: BorderRadius.circular(20.sp),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/sub.jpg',
              width: 37.sp,
              height: 37.sp,
            ),
            Text(
              name,
              style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 15.sp),
            ),
          ],
        ),
      ),
    );
  }
}

class InterestingFactCard extends StatelessWidget {
  final String subject;
  final String factText;
  final bool fact;

  InterestingFactCard({
    required this.subject,
    required this.factText,
    required this.fact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(17.sp),
      margin: EdgeInsets.symmetric(horizontal: 15.sp),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17.sp),
          color: Color.fromARGB(255, 54, 6, 84)),
      child: Row(
        children: [
          Container(
            width: 50.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interesting Facts',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18.sp),
                ),
                SizedBox(height: 1.7.h),
                fact
                    ? Center(
                        child: Transform.scale(
                          scale: 3.sp,
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      )
                    : Center(
                        child: Text(
                          factText,
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 14.sp),
                        ),
                      ),
              ],
            ),
          ),
          Spacer(),
          Image.asset(
            'assets/if.png',
            width: 30.w,
          ),
        ],
      ),
    );
  }
}
