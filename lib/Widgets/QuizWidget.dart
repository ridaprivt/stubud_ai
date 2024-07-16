// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learnai/UI/quiz/Quiz.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizWidget extends StatefulWidget {
  final String? subjectName;

  const QuizWidget({
    super.key,
    this.subjectName,
  });

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget> {
  String grade = '';
  String resp = '';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 27.h,
      padding: EdgeInsets.all(15.sp),
      alignment: Alignment.center,
      width: double.infinity,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.sp), color: Color(0xffD9D9D9)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 50.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pop',
                      style: GoogleFonts.poppins(
                          color: Colors.black,
                          height: 3.sp,
                          fontWeight: FontWeight.bold,
                          fontSize: 25.sp),
                    ),
                    Text(
                      'Quiz',
                      style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 30.sp),
                    ),
                    Text(
                      'Wanna know how much you grasped from\nour lessons? I bet you’ll do great',
                      style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 11.5.sp),
                    ),
                  ],
                ),
              ),
              Image.asset(
                'assets/cartoon.png',
                width: 25.w,
              )
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: () async {
                  await handleQuizGeneration();
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20.sp)),
                  child: isLoading
                      ? Transform.scale(
                          scale: 0.4,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ))
                      : Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 13.sp, vertical: 13.sp),
                          child: Text(
                            'Accept Challenge',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                height: 3.sp,
                                fontWeight: FontWeight.w500,
                                fontSize: 12.sp),
                          ),
                        ),
                ),
              ),
              SizedBox(width: 1.w),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 13.sp, vertical: 13.sp),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(20.sp)),
                child: Text(
                  'Maybe a quick revision?',
                  style: GoogleFonts.poppins(
                      color: Colors.black,
                      height: 3.sp,
                      fontWeight: FontWeight.w500,
                      fontSize: 12.sp),
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                'Wuss Out :(',
                style: GoogleFonts.poppins(
                    color: Colors.black,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w500,
                    fontSize: 12.5.sp),
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<String?> fetchUserGrade(String userID) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userID).get();
    if (userDoc.exists) {
      return userDoc.data()?['grade'];
    } else {
      return null;
    }
  }

  List<String> fetchCachedTopics(SharedPreferences prefs) {
    final cachedTopics =
        prefs.getStringList('cachedTopics_${widget.subjectName}');
    List<String> topics = [];

    if (cachedTopics != null) {
      for (var topicJson in cachedTopics) {
        final topicMap = jsonDecode(topicJson);
        final topic = topicMap['topic'];
        topics.add(topic);
      }
    }
    return topics;
  }

  Future<void> handleQuizGeneration() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('userID');

    if (userID == null) {
      showSnackBar("No userID found in SharedPreferences.");
      setState(() {
        isLoading = false;
      });
      return;
    }

    final grade = await fetchUserGrade(userID);
    if (grade == null) {
      showSnackBar("Failed to fetch user grade.");
      setState(() {
        isLoading = false;
      });
      return;
    }

    final topics = fetchCachedTopics(prefs);

    final nextQuizNumber = await determineNextQuizNumber(userID);
    if (nextQuizNumber == -1) {
      Get.to(Quiz(
        subject: widget.subjectName,
      ));
      setState(() {
        isLoading = false;
      });
      return;
    }

    final quizData = await generateQuizData(grade, topics);
    if (quizData == null) {
      showSnackBar("Failed to generate quiz data.");
      setState(() {
        isLoading = false;
      });
      return;
    }

    final isSaved = await saveQuizData(quizData, userID, nextQuizNumber);
    if (isSaved) {
      Get.to(Quiz(
        subject: widget.subjectName,
      ));
    } else {
      showSnackBar("Failed to save quiz data.");
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<int> determineNextQuizNumber(String userID) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userID);
    final subjectDoc = userDoc.collection('quizzes').doc(widget.subjectName);

    int nextQuizNumber = 1;
    while (true) {
      final quizCollection = await subjectDoc
          .collection('quiz$nextQuizNumber')
          .doc('quizData')
          .get();
      if (quizCollection.exists) {
        final data = quizCollection.data();
        if (data != null &&
            (data['submitted_quiz'].isEmpty ||
                data['obtained_marks'].isEmpty)) {
          return -1; // Indicate that we should not generate a new quiz
        }
        nextQuizNumber++;
      } else {
        break;
      }
    }
    return nextQuizNumber;
  }

  Future<bool> saveQuizData(List<Map<String, dynamic>> quizzes, String userID,
      int nextQuizNumber) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userID);
    final subjectDoc = userDoc.collection('quizzes').doc(widget.subjectName);

    final quizData = {
      'quiz': quizzes,
      'submitted_quiz': [],
      'total_marks': '',
      'obtained_marks': ''
    };

    await subjectDoc
        .collection('quiz$nextQuizNumber')
        .doc('quizData')
        .set(quizData);
    return true;
  }

  Future<List<Map<String, dynamic>>?> generateQuizData(
      String grade, List<String> topics) async {
    String prompt = '''
Generate a quiz of 13 Questions (MCQS) and give 4 options out of which one is correct. 
Student's Grade is:  $grade. 
Subject name is:  ${widget.subjectName}
Topics for Quiz are:  ${topics.join(', ')}. 
Format (sample only) should be like this. Dont Change Format:
      
        Question: What is the capital of Sehan?,
        Options: 
        1. Astro
        2. Bistro
        3. Sastro
        4. Costro
        Answer: Astro,
      
        Question: What is the capital of Sehan?,
        Options: 
        1. Astro
        2. Bistro
        3. Sastro
        4. Costro
        Answer: Astro,
      
''';

    final String apiUrl =
        "https://us-central1-chatbot-b81d7.cloudfunctions.net/afnan-gpt-2";

    List<Map<String, dynamic>> messages = [
      {
        'role': 'user',
        'content': prompt,
      },
    ];

    Map<String, String> headers = {
      "Content-Type": "application/json",
    };

    Map<String, dynamic> payload = {
      "data": {"conversation": messages}
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData.containsKey("result") &&
          responseData["result"].containsKey("response")) {
        String resp = responseData["result"]["response"].toString();
        return parseQuizResponse(resp);
      }
    }
    return null;
  }

  List<Map<String, dynamic>>? parseQuizResponse(String response) {
    List<String> lines = response.split('\n');

    String? currentQuestion;
    List<String> currentOptions = [];
    String? currentAnswer;
    List<Map<String, dynamic>> quizzes = [];

    for (var line in lines) {
      line = line.trim();

      if (line.startsWith('Question:')) {
        if (currentQuestion != null &&
            currentOptions.isNotEmpty &&
            currentAnswer != null) {
          quizzes.add({
            'question': currentQuestion,
            'options': currentOptions,
            'answer': currentAnswer,
          });
        }
        currentQuestion =
            line.replaceFirst('Question: ', '').replaceFirst(',', '').trim();
        currentOptions = [];
        currentAnswer = null;
      } else if (line.startsWith(RegExp(r'\d+\.\s')) ||
          line.startsWith(RegExp(r'[a-dA-D]\.\s'))) {
        currentOptions
            .add(line.replaceFirst(RegExp(r'\d+\.\s|[a-dA-D]\.\s'), '').trim());
      } else if (line.startsWith('Answer:')) {
        currentAnswer =
            line.replaceFirst('Answer: ', '').replaceFirst(',', '').trim();
      }
    }

    if (currentQuestion != null &&
        currentOptions.isNotEmpty &&
        currentAnswer != null) {
      quizzes.add({
        'question': currentQuestion,
        'options': currentOptions,
        'answer': currentAnswer,
      });
    }

    return quizzes.isNotEmpty ? quizzes : null;
  }

  void showSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void printQuiz(String? question, List<String> options, String? answer) {
    print('-Question: $question');
    print('-Options: ${options.join(', ')}');
    print('-Answer: $answer');
    print('-----------------------------');
  }
}
