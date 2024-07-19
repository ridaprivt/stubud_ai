import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learnai/UI/quiz/Result.dart';

class QuizMethods {
  static Future<void> fetchQuizData(
    Function setStateCallback,
    String? subject,
    Function(bool) setLoadCallback,
    Function(bool) setNoQuizAvailableCallback,
    List<Map<String, dynamic>> quizData,
    bool load,
    bool noQuizAvailable,
    BuildContext context,
  ) async {
    setLoadCallback(true);

    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('userID');

    if (userID == null) {
      showSnackBar("No userID found in SharedPreferences.", context);
      setLoadCallback(false);
      setNoQuizAvailableCallback(true);
      return;
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(userID);
    final subjectDoc = userDoc.collection('quizzes').doc(subject);

    int latestQuizNumber = await determineNextQuizNumber(userID, subject);

    if (latestQuizNumber == 1) {
      setLoadCallback(false);
      setNoQuizAvailableCallback(true);
      return;
    }

    final quizDataDoc = await subjectDoc
        .collection('quiz${latestQuizNumber - 1}')
        .doc('quizData')
        .get();

    if (!quizDataDoc.exists) {
      setLoadCallback(false);
      setNoQuizAvailableCallback(true);
      return;
    }

    try {
      final data = quizDataDoc.data();
      if (data == null || data['quiz'] == null) {
        setLoadCallback(false);
        setNoQuizAvailableCallback(true);
        return;
      }

      setStateCallback(() {
        quizData = List<Map<String, dynamic>>.from(data['quiz']);
        load = false;
        noQuizAvailable = false;
      });
    } catch (e) {
      print("Error parsing quiz data: $e");
      setLoadCallback(false);
      setNoQuizAvailableCallback(true);
    }
  }

  static Future<int> determineNextQuizNumber(
      String userID, String? subject) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userID);
    final subjectDoc = userDoc.collection('quizzes').doc(subject);

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

  static Future<void> saveSubmittedQuiz(
    int currentIndex,
    String? selectedOption,
    String? subject,
    List<Map<String, dynamic>> quizData,
    BuildContext context,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('userID');

    if (userID == null) {
      showSnackBar("No userID found in SharedPreferences.", context);
      return;
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(userID);
    final subjectDoc = userDoc.collection('quizzes').doc(subject);

    int latestQuizNumber = await determineNextQuizNumber(userID, subject);

    if (latestQuizNumber == 1) {
      showSnackBar("No quiz found to submit.", context);
      return;
    }

    final quizDataDoc = await subjectDoc
        .collection('quiz${latestQuizNumber - 1}')
        .doc('quizData')
        .get();

    if (!quizDataDoc.exists) {
      showSnackBar("Failed to fetch quiz data.", context);
      return;
    }

    final Map<String, dynamic> quizDataMap = quizDataDoc.data()!;
    List submittedQuiz = quizDataMap['submitted_quiz'] ?? [];

    if (currentIndex < quizDataMap['quiz'].length) {
      Map<String, dynamic> currentQuestion = quizDataMap['quiz'][currentIndex];
      String question = currentQuestion['question'] ?? "Unknown question";

      submittedQuiz.add({
        'question': question,
        'selected_option': selectedOption,
      });
    }

    int totalMarks = quizDataMap['quiz'].length;

    await subjectDoc
        .collection('quiz${latestQuizNumber - 1}')
        .doc('quizData')
        .update({
      'submitted_quiz': submittedQuiz,
      'total_marks': totalMarks.toString(),
    });
  }

  static void showSnackBar(String message, BuildContext context) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void startCountdown(
    Function setStateCallback,
    int remainingTime,
    Timer? countdownTimer,
    Function submitAnswer,
  ) {
    remainingTime = 15;
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setStateCallback(() {
          remainingTime--;
        });
      } else {
        timer.cancel();
        submitAnswer(null);
        print('Times Up');
      }
    });
  }

  static void submitAnswer(
    String? option,
    int currentIndex,
    List<Map<String, dynamic>> quizData,
    Function setStateCallback,
    Timer? countdownTimer,
    String? subject,
    BuildContext context,
    int remainingTime,
    String? selectedOption,
  ) {
    saveSubmittedQuiz(currentIndex, option, subject, quizData, context);
    if (currentIndex < quizData.length - 1) {
      setStateCallback(() {
        currentIndex++;
        selectedOption = null;
      });
      startCountdown(setStateCallback, remainingTime, countdownTimer, () {
        submitAnswer(option, currentIndex, quizData, setStateCallback,
            countdownTimer, subject, context, remainingTime, selectedOption);
      });
    } else {
      print('All questions answered');
      setStateCallback(() {
        currentIndex++;
        selectedOption = null;
      });
    }
  }

  static void calculateResults(
    Function setStateCallback,
    String? subject,
    Function(bool) setCalculateCallback,
    BuildContext context,
    bool calculate,
  ) async {
    setStateCallback(() {
      calculate = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('userID');

    if (userID == null) {
      showSnackBar("No userID found in SharedPreferences.", context);
      setStateCallback(() {
        calculate = false;
      });
      return;
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(userID);
    final subjectDoc = userDoc.collection('quizzes').doc(subject);

    int latestQuizNumber = await determineNextQuizNumber(userID, subject);

    if (latestQuizNumber == 1) {
      showSnackBar("No quiz found to calculate results.", context);
      setStateCallback(() {
        calculate = false;
      });
      return;
    }

    final quizDataDoc = await subjectDoc
        .collection('quiz${latestQuizNumber - 1}')
        .doc('quizData')
        .get();

    if (!quizDataDoc.exists) {
      showSnackBar("Failed to fetch quiz data.", context);
      setStateCallback(() {
        calculate = false;
      });
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

    setStateCallback(() {
      calculate = false;
    });
  }
}
