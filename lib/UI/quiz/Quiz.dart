import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnai/UI/home/Home.dart';
import 'package:learnai/UI/quiz/Result.dart';
import 'package:learnai/Widgets/AppBar.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

class Quiz extends StatefulWidget {
  final String? subject;

  const Quiz({Key? key, this.subject}) : super(key: key);

  @override
  State<Quiz> createState() => _QuizState();
}

class _QuizState extends State<Quiz> {
  String? selectedOption;
  List<Map<String, dynamic>>? quizData;
  bool load = false;
  bool _noQuizAvailable = false;
  int currentIndex = 0;
  Timer? countdownTimer;
  int remainingTime = 15;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchQuizData();
    startCountdown();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  void startCountdown() {
    remainingTime = 15;
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setState(() {
          remainingTime--;
        });
      } else {
        timer.cancel();
        submitAnswer(null);
        print('Times Up');
      }
    });
  }

  void submitAnswer(String? option) {
    saveSubmittedQuiz(currentIndex, option);
    if (currentIndex < quizData!.length - 1) {
      setState(() {
        currentIndex++;
        selectedOption = null;
      });
      startCountdown();
    } else {
      print('All questions answered');
      setState(() {
        currentIndex++;
        selectedOption = null;
      });
    }
  }

  void fetchQuizData() async {
    setState(() {
      load = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('userID');

    if (userID == null) {
      showSnackBar("No userID found in SharedPreferences.");
      setState(() {
        load = false;
        _noQuizAvailable = true;
      });
      return;
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(userID);
    final subjectDoc = userDoc.collection('quizzes').doc(widget.subject);

    // Fetch the latest quiz number
    int latestQuizNumber = await determineNextQuizNumber(userID);

    if (latestQuizNumber == 1) {
      // No quizzes found
      setState(() {
        load = false;
        _noQuizAvailable = true;
      });
      return;
    }

    // Fetch the latest quiz data
    final quizDataDoc = await subjectDoc
        .collection('quiz${latestQuizNumber - 1}')
        .doc('quizData')
        .get();

    if (!quizDataDoc.exists) {
      setState(() {
        load = false;
        _noQuizAvailable = true;
      });
      return;
    }

    try {
      final data = quizDataDoc.data();
      if (data == null || data['quiz'] == null) {
        setState(() {
          load = false;
          _noQuizAvailable = true;
        });
        return;
      }

      setState(() {
        quizData = List<Map<String, dynamic>>.from(data['quiz']);
        load = false;
        _noQuizAvailable = false;
      });
    } catch (e) {
      print("Error parsing quiz data: $e");
      setState(() {
        load = false;
        _noQuizAvailable = true;
      });
    }
  }

  Future<void> saveSubmittedQuiz(
      int currentIndex, String? selectedOption) async {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('userID');

    if (userID == null) {
      showSnackBar("No userID found in SharedPreferences.");
      return;
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(userID);
    final subjectDoc = userDoc.collection('quizzes').doc(widget.subject);

    // Fetch the latest quiz number
    int latestQuizNumber = await determineNextQuizNumber(userID);

    if (latestQuizNumber == 1) {
      // No quizzes found, can't submit
      showSnackBar("No quiz found to submit.");
      return;
    }

    // Fetch the latest quiz data
    final quizDataDoc = await subjectDoc
        .collection('quiz${latestQuizNumber - 1}')
        .doc('quizData')
        .get();

    if (!quizDataDoc.exists) {
      showSnackBar("Failed to fetch quiz data.");
      return;
    }

    final Map<String, dynamic> quizData = quizDataDoc.data()!;
    List submittedQuiz = quizData['submitted_quiz'] ?? [];

    if (currentIndex < quizData['quiz'].length) {
      Map<String, dynamic> currentQuestion = quizData['quiz'][currentIndex];
      String question = currentQuestion['question'] ?? "Unknown question";

      submittedQuiz.add({
        'question': question,
        'selected_option': selectedOption,
      });
    }

    // Calculate total marks
    int totalMarks = quizData['quiz'].length;

    await subjectDoc
        .collection('quiz${latestQuizNumber - 1}')
        .doc('quizData')
        .update({
      'submitted_quiz': submittedQuiz,
      'total_marks': totalMarks.toString(),
    });
  }

  Future<int> determineNextQuizNumber(String userID) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userID);
    final subjectDoc = userDoc.collection('quizzes').doc(widget.subject);

    int nextQuizNumber = 1;
    while (true) {
      final quizCollection = await subjectDoc
          .collection('quiz$nextQuizNumber')
          .doc('quizData')
          .get();
      if (quizCollection.exists) {
        nextQuizNumber++;
      } else {
        break;
      }
    }
    return nextQuizNumber;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: MyAppBar(),
        body: load
            ? Center(
                child: SpinKitCircle(
                  size: 35.sp,
                  itemBuilder: (BuildContext context, int index) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index.isEven ? Colors.green : Colors.white,
                      ),
                    );
                  },
                ),
              )
            : _noQuizAvailable
                ? Center(
                    child: Text(
                      'No Quiz Available',
                      style: GoogleFonts.poppins(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 75.w,
                            child: StepProgressIndicator(
                              totalSteps: quizData!.length,
                              currentStep: currentIndex,
                              size: 15,
                              padding: 0,
                              selectedColor: const Color(0xff1ED760),
                              unselectedColor:
                                  const Color.fromARGB(255, 232, 232, 232),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Icon(
                            Icons.timer_outlined,
                            color: Colors.black,
                          ),
                          SizedBox(width: 0.5.w),
                          Text(
                            remainingTime.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3.h),
                      Part1(),
                      SizedBox(height: 5.h),
                      if (currentIndex != quizData!.length) Submit(),
                      if (currentIndex == quizData!.length) MyResult(),
                    ],
                  ),
      ),
    );
  }

  Submit() {
    return InkWell(
      onTap: () {
        if (selectedOption == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: Duration(seconds: 1),
              backgroundColor: Colors.red,
              content: Text('Select one possible answer',
                  style: GoogleFonts.poppins()),
            ),
          );
          return;
        }

        countdownTimer?.cancel();
        submitAnswer(selectedOption);
      },
      child: Container(
        height: 9.h,
        width: 87.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.sp),
          color: const Color.fromARGB(255, 76, 76, 76),
        ),
        child: Text(
          'CONTINUE',
          style: GoogleFonts.poppins(
            color: Colors.white,
            height: 3.sp,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
      ),
    );
  }

  MyResult() {
    return InkWell(
      onTap: () async {
        calculateResults();
      },
      child: Container(
        height: 9.h,
        width: 87.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.sp),
          color: Color.fromARGB(255, 25, 180, 79),
        ),
        child: isLoading
            ? CircularProgressIndicator(
                color: Colors.white,
              )
            : Text(
                'View Results',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  height: 3.sp,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
              ),
      ),
    );
  }

  void calculateResults() async {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('userID');

    if (userID == null) {
      showSnackBar("No userID found in SharedPreferences.");
      return;
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(userID);
    final subjectDoc = userDoc.collection('quizzes').doc(widget.subject);

    // Fetch the latest quiz number
    int latestQuizNumber = await determineNextQuizNumber(userID);

    if (latestQuizNumber == 1) {
      // No quizzes found
      showSnackBar("No quiz found to calculate results.");
      return;
    }

    // Fetch the latest quiz data
    final quizDataDoc = await subjectDoc
        .collection('quiz${latestQuizNumber - 1}')
        .doc('quizData')
        .get();

    if (!quizDataDoc.exists) {
      showSnackBar("Failed to fetch quiz data.");
      return;
    }

    final Map<String, dynamic> quizData = quizDataDoc.data()!;
    List submittedQuiz = quizData['submitted_quiz'] ?? [];

    int obtainedMarks = 0;

    for (var submitted in submittedQuiz) {
      String question = submitted['question'];
      String selectedOption = submitted['selected_option'];

      var quizQuestion =
          quizData['quiz'].firstWhere((q) => q['question'] == question);
      if (quizQuestion != null && quizQuestion['answer'] == selectedOption) {
        obtainedMarks++;
      }
    }

    int totalMarks = quizData['quiz'].length;

    // Save the results to Firebase
    await subjectDoc
        .collection('quiz${latestQuizNumber - 1}')
        .doc('quizData')
        .update({
      'obtained_marks': obtainedMarks.toString(),
      'total_marks': totalMarks.toString(),
    });

    Get.to(Result(
      obtainedMarks: obtainedMarks.toString(),
      totalMarks: totalMarks.toString(),
    ));
  }

  Part1() {
    if (quizData != null &&
        quizData!.isNotEmpty &&
        currentIndex < quizData!.length) {
      Map<String, dynamic> currentQuestion = quizData![currentIndex];
      String question = currentQuestion['question'] ?? "No question text";
      String? img = currentQuestion['img'];
      List<String> options =
          List<String>.from(currentQuestion['options'] ?? []);

      return Column(
        children: [
          SizedBox(height: 1.h),
          Container(
            width: 85.w,
            child: Text(
              question,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 3.h),
          box(selectedOption),
          SizedBox(height: 2.h),
          Container(
            width: 87.w,
            child: Wrap(
              alignment: WrapAlignment.center,
              runSpacing: 10.sp,
              spacing: 10.sp,
              children:
                  options.map<Widget>((option) => buildOption(option)).toList(),
            ),
          ),
        ],
      );
    } else {
      return NoQuiz();
    }
  }

  NoQuiz() {
    return Container(
      height: 50.h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/my.png',
            width: 47.w,
          ),
          SizedBox(height: 3.h),
          Center(
            child: Container(
              width: 80.w,
              child: Text(
                'Quiz Completed',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  box(String? selectedOption) {
    return Container(
      height: 15.h,
      width: 87.w,
      padding: EdgeInsets.all(15.sp),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.sp),
        color: const Color.fromARGB(255, 220, 220, 220),
        border: Border.all(color: Colors.black, width: 5.sp),
      ),
      child: selectedOption != null
          ? Wrap(
              children: [
                Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 15.sp, vertical: 13.sp),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(15.sp),
                    ),
                    child: Text(
                      selectedOption,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16.sp),
                    )),
              ],
            )
          : null,
    );
  }

  buildOption(String text) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedOption = text;
        });
      },
      child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(15.sp),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 15.sp),
          )),
    );
  }

  void showSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
