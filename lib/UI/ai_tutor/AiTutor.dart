import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learnai/Google%20Ads/BannerAd.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';

class AiTutor extends StatefulWidget {
  const AiTutor({super.key});

  @override
  State<AiTutor> createState() => _AiTutorState();
}

class _AiTutorState extends State<AiTutor> {
  TextEditingController prompt = TextEditingController();
  FlutterTts _flutterTts = FlutterTts();
  stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isPaused = false;
  String _speechText = '';
  String bot = '';

  @override
  void initState() {
    super.initState();
    initTTS();
    _initializeData();
  }

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

        setState(() {
          subscription = userDoc['subscription'];
        });
      } catch (e) {
        print('Error checking subscription status: $e');
      }
    }
  }

  void initTTS() {
    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });
    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
    _flutterTts.setPauseHandler(() {
      setState(() => _isSpeaking = false);
    });
    _flutterTts.setContinueHandler(() {
      setState(() => _isSpeaking = true);
    });
  }

  Future<void> _toggleSpeaking() async {
    if (_isSpeaking && !_isPaused) {
      await _flutterTts.pause();
      setState(() {
        _isPaused = true;
      });
    } else {
      await _flutterTts.speak(bot);
      setState(() {
        _isPaused = false;
      });
    }
  }

  Future<void> _startListening() async {
    bool available = await _speechToText.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speechToText.listen(onResult: (result) {
        setState(() {
          _speechText = result.recognizedWords;
          prompt.text = _speechText;
        });
      });
    }
  }

  void _stopListening() {
    _speechToText.stop();
    setState(() => _isListening = false);
    _sendToApiAndSpeak(_speechText);
  }

  Future<void> _sendToApiAndSpeak(String text) async {
    final String apiUrl =
        "https://us-central1-chatbot-b81d7.cloudfunctions.net/afnan-gpt-2";
    Map<String, String> headers = {
      "Content-Type": "application/json",
    };

    Map<String, dynamic> payload = {
      "data": {
        "conversation": [
          {"role": "user", "content": text}
        ]
      }
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        String botResponse = responseData["result"]["response"] ?? "";
        setState(() {
          bot = botResponse;
        });
        await _flutterTts.speak(bot);
      } else {
        print("API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(),
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 25.sp),
          children: [
            SizedBox(height: 12.h),
            if (!subscription)
              Column(
                children: [
                  AdsServices().MyAd(context),
                  SizedBox(height: 3.h),
                ],
              ),
            Center(
              child: Text(
                'AI TUTOR',
                style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 25.sp),
              ),
            ),
            SizedBox(height: 3.h),
            Center(
              child: Image.asset(
                'assets/ai.png',
                height: 27.h,
              ),
            ),
            // SizedBox(height: 5.h),
            // Container(
            //   width: 80.w,
            //   padding: EdgeInsets.symmetric(horizontal: 15.sp),
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(20.sp),
            //       border: Border.all(color: Colors.black, width: 5.sp)),
            //   child: TextField(
            //       maxLines: 6,
            //       controller: prompt,
            //       style: GoogleFonts.poppins(
            //           color: Colors.black,
            //           fontSize: 16.sp,
            //           fontWeight: FontWeight.w500),
            //       decoration: InputDecoration(
            //         isDense: true,
            //         hintText: 'Enter your text',
            //         hintStyle: GoogleFonts.poppins(
            //             color: Colors.black,
            //             fontSize: 16.sp,
            //             fontWeight: FontWeight.w500),
            //         border: InputBorder.none,
            //       )),
            // ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: _isListening ? _stopListening : _startListening,
                  child: Container(
                    height: 8.h,
                    width: 35.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.sp),
                      color: _isListening
                          ? const Color.fromARGB(255, 196, 54, 43)
                          : const Color.fromARGB(255, 76, 76, 76),
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                ),
                InkWell(
                  onTap: _toggleSpeaking,
                  child: Container(
                    height: 8.h,
                    width: 35.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.sp),
                      color: _isPaused
                          ? const Color.fromARGB(255, 196, 54, 43)
                          : const Color.fromARGB(255, 76, 76, 76),
                    ),
                    child: _isSpeaking
                        ? Icon(
                            Icons.pause,
                            color: Color(0xff1ED760),
                            size: 24.sp,
                          )
                        : Icon(
                            _isPaused ? Icons.play_arrow : Icons.volume_up,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
