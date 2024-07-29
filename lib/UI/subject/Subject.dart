// ignore_for_file: prefer_const_constructors
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learnai/Google%20Ads/BannerAd.dart';
import 'package:learnai/Google%20Ads/InterstitialAd.dart';
import 'package:learnai/UI/subject/Scores.dart';
import 'package:learnai/UI/subject/Topic.dart';
import 'package:learnai/Widgets/AppBar.dart';
import 'package:learnai/Widgets/QuizWidget.dart';
import 'package:learnai/main.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Subject extends StatefulWidget {
  final String subjectName;

  Subject({required this.subjectName});

  @override
  State<Subject> createState() => _SubjectState();
}

class _SubjectState extends State<Subject> {
  TextEditingController _topicController = TextEditingController();
  bool _isLoading = false;
  List<String> _subTopics = [];
  String _topicIntro = "";
  List<Map<String, dynamic>> _cachedTopics = [];
  List<String> _suggestedTopics = [];
  bool suggested = false;
  bool subscription = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadCachedTopics();
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: MyAppBar(),
            body: ListView(
                padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 15.sp),
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
                    alignment: Alignment.topCenter,
                    padding: EdgeInsets.all(17.sp),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17.sp),
                      color:
                          globalController.primaryColor.value.withOpacity(0.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50.w,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.subjectName,
                                style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18.sp),
                              ),
                              SizedBox(height: 1.5.h),
                              Text(
                                'Any specific chapter that you are troubled to understand?',
                                style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 15.sp),
                              ),
                              SizedBox(height: 1.5.h),
                              TextField(
                                controller: _topicController,
                                style: GoogleFonts.poppins(
                                    color: Colors.black, fontSize: 16.sp),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 10.sp, horizontal: 10.sp),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Color.fromARGB(255, 0, 0, 0))),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Color.fromARGB(255, 0, 0, 0))),
                                  border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Color.fromARGB(255, 0, 0, 0))),
                                ),
                              ),
                              SizedBox(height: 1.h),
                              MaterialButton(
                                height: 5.5.h,
                                onPressed: () {
                                  fetchData(_topicController.text);
                                },
                                color: Color.fromARGB(255, 0, 0, 0),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.sp)),
                                child: _isLoading
                                    ? CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : Text("Search",
                                        style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 17.sp)),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        Image.asset(
                          'assets/book.png',
                          width: 30.w,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 1.h),
                  MaterialButton(
                    height: 6.h,
                    onPressed: () {
                      Get.to(Scores(
                        subjectName: widget.subjectName,
                      ));
                    },
                    color: Color.fromARGB(255, 154, 8, 25),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.sp)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Check Progress ",
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 17.sp)),
                        Icon(
                          Icons.arrow_forward,
                          color: const Color.fromARGB(255, 255, 255, 255),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  buildCachedTopics(),
                  SizedBox(height: 2.h),
                  _suggestedTopics.isNotEmpty
                      ? buildSuggestions()
                      : Container(),
                  SizedBox(height: 2.h),
                  QuizWidget(
                    subjectName: widget.subjectName,
                    lastCachedTopic: _cachedTopics.isNotEmpty
                        ? _cachedTopics.last['topic']
                        : '',
                  )
                ])));
  }

  Future<void> fetchSuggestedTopics() async {
    setState(() {
      suggested = true;
    });
    List<String> recentTopics =
        _cachedTopics.map((topic) => topic['topic'] as String).toList();

    String prompt;
    if (recentTopics.isNotEmpty) {
      prompt =
          '''Suggest some new topics(short topic name and no inverted commas)  similar to the following: ${recentTopics.join(', ')}.''';
    } else {
      prompt =
          'Suggest some new topics(short topic name and no inverted commas) to learn for ${widget.subjectName}';
    }

    List<Map<String, dynamic>> messages = [
      {
        'role': 'user',
        'content': prompt,
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
          final String responseText =
              responseData["result"]["response"].toString();

          List<String> suggestedTopics = responseText
              .split(RegExp(r'\d+\.\s*'))
              .where((item) => item.isNotEmpty)
              .map((item) => item.trim())
              .toList();

          setState(() {
            _suggestedTopics = suggestedTopics;
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
      suggested = false;
    });
  }

  Widget buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How about you learn something new?',
          style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 18.sp),
        ),
        SizedBox(height: 1.5.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _suggestedTopics.map((topic) {
              return GestureDetector(
                onTap: () {
                  fetchData(topic);
                },
                child: Container(
                  height: 17.h,
                  padding: EdgeInsets.all(13.sp),
                  margin: EdgeInsets.only(right: 2.w),
                  width: 50.sp,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        globalController.primaryColor.value.withOpacity(0.34),
                        Color.fromARGB(97, 155, 39, 176)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.grey, width: 3.sp),
                    borderRadius: BorderRadius.circular(20.sp),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        topic,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 15.sp),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(), // Convert iterable to list
          ),
        ),
      ],
    );
  }

  Future<void> _loadCachedTopics() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cachedTopics')
          .where('subjectName', isEqualTo: widget.subjectName)
          .get();

      setState(() {
        _cachedTopics = snapshot.docs
            .map((doc) => {
                  'topic': doc['topic'],
                  'intro': doc['intro'],
                  'subTopics': doc['subTopics']
                })
            .toList();
      });

      await fetchSuggestedTopics();
    }
  }

  Future<void> _cacheTopic(
      String topic, String intro, List<String> subTopics) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      final topicData = {
        'topic': topic,
        'intro': intro,
        'subTopics': subTopics,
        'subjectName': widget.subjectName
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cachedTopics')
          .add(topicData);

      setState(() {
        _cachedTopics.add(topicData);
      });
    }
  }

  Future<void> fetchData(String topic) async {
    setState(() {
      _isLoading = true;
    });
    await fetchTopicIntro(topic);
    await fetchSubTopics(topic);

    if (_topicIntro.isNotEmpty && _subTopics.isNotEmpty) {
      await _cacheTopic(topic, _topicIntro, _subTopics);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Topic(
            topic: topic,
            topicIntro: _topicIntro,
            subTopics: _subTopics,
          ),
        ),
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  Widget buildCachedTopics() {
    return _cachedTopics.isEmpty
        ? Container()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You don’t wanna forget about what you started',
                style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 17.sp),
              ),
              SizedBox(height: 1.5.h),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _cachedTopics.map((topicData) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Topic(
                              topic: topicData['topic'],
                              topicIntro: topicData['intro'],
                              subTopics: (json.decode(topicData['subTopics'])
                                      as List<dynamic>)
                                  .map((e) => e.toString())
                                  .toList(),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 17.h,
                        padding: EdgeInsets.all(13.sp),
                        margin: EdgeInsets.only(right: 2.w),
                        width: 50.sp,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              globalController.primaryColor.value
                                  .withOpacity(0.34),
                              Color.fromARGB(97, 155, 39, 176)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: Colors.grey, width: 3.sp),
                          borderRadius: BorderRadius.circular(20.sp),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              topicData['topic']!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15.sp),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(), // Convert iterable to list
                ),
              ),
            ],
          );
  }

  Future<void> fetchSubTopics(String topic) async {
    List<Map<String, dynamic>> messages = [
      {
        'role': 'user',
        'content': '''Give me subtopics for the topic $topic. Format should be

        1.
        2.
        3.
        4.
        
       ''',
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
          final String responseText =
              responseData["result"]["response"].toString();

          // Parse the response to remove numbers and full stops
          List<String> subTopics = responseText
              .split(RegExp(r'\d+\.\s*'))
              .where((item) => item.isNotEmpty)
              .map((item) => item.trim())
              .toList();
          setState(() {
            _subTopics = subTopics;
          });
          print(subTopics);
        } else {
          print('Unexpected response format.');
        }
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> fetchTopicIntro(String topic) async {
    List<Map<String, dynamic>> messages = [
      {
        'role': 'user',
        'content': 'Give me a short introduction about the topic $topic.',
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
          final String responseText =
              responseData["result"]["response"].toString();

          setState(() {
            _topicIntro = responseText.trim();
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
  }
}
