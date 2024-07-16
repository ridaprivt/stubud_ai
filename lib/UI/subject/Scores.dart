import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learnai/UI/subject/IncorrectAnswers.dart';
import 'package:learnai/main.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:learnai/Widgets/AppBar.dart';

class Scores extends StatefulWidget {
  final String subjectName;

  const Scores({Key? key, required this.subjectName}) : super(key: key);

  @override
  State<Scores> createState() => _ScoresState();
}

class _ScoresState extends State<Scores> {
  bool isLoading = false;
  List<Map<String, dynamic>> quizResults = [];
  List<Map<String, dynamic>> incorrectAnswers = [];

  @override
  void initState() {
    super.initState();
    fetchQuizResults();
  }

  Future<void> fetchQuizResults() async {
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

    final userDoc = FirebaseFirestore.instance.collection('users').doc(userID);
    final subjectDoc = userDoc.collection('quizzes').doc(widget.subjectName);

    int quizNumber = 1;
    bool quizzesFound = false;

    while (true) {
      final quizDataDoc =
          await subjectDoc.collection('quiz$quizNumber').doc('quizData').get();
      if (!quizDataDoc.exists) {
        break;
      }

      quizzesFound = true; // Mark that at least one quiz was found

      final data = quizDataDoc.data();
      if (data != null) {
        final totalMarks = data['total_marks'];
        final obtainedMarks = data['obtained_marks'];
        quizResults.add({
          'quizNumber': quizNumber,
          'totalMarks': totalMarks,
          'obtainedMarks': obtainedMarks,
        });

        // Check for incorrect answers
        List submittedQuiz = data['submitted_quiz'] ?? [];
        for (var questionData in submittedQuiz) {
          String question = questionData['question'];
          String selectedOption = questionData['selected_option'];
          String correctAnswer = (data['quiz'] as List)
              .firstWhere((q) => q['question'] == question)['answer'];

          if (selectedOption != correctAnswer) {
            incorrectAnswers.add({
              'quizNumber': quizNumber,
              'question': question,
              'selectedOption': selectedOption,
              'correctAnswer': correctAnswer,
            });
          }
        }
      }

      quizNumber++;
    }

    if (!quizzesFound) {
      showSnackBar("No quiz results yet.");
    }

    setState(() {
      isLoading = false;
    });
  }

  void showSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: MyAppBar(),
        body: isLoading
            ? Center(
                child: SpinKitCircle(
                  size: 35.sp,
                  itemBuilder: (BuildContext context, int index) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index.isEven
                            ? globalController.primaryColor.value
                            : Colors.white,
                      ),
                    );
                  },
                ),
              )
            : quizResults.isEmpty
                ? Center(
                    child: Text(
                      'No quiz results yet.',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        ListView.builder(
                          padding: EdgeInsets.fromLTRB(2.w, 2.h, 2.w, 0),
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: quizResults.length,
                          itemBuilder: (context, index) {
                            final quiz = quizResults[index];
                            return Card(
                              color: Color.fromARGB(255, 234, 234, 234),
                              child: ListTile(
                                title: Text(
                                  'Quiz ${quiz['quizNumber']}',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 19.sp),
                                ),
                                subtitle: Text(
                                  'Total Marks: ${quiz['totalMarks']}\nObtained Marks: ${quiz['obtainedMarks']}',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16.sp),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          IncorrectAnswersScreen(
                                        quizNumber: quiz['quizNumber'],
                                        incorrectAnswers: incorrectAnswers,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
