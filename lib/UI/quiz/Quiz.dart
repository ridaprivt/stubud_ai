import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:learnai/Widgets/AppBar.dart';
import 'package:learnai/main.dart';
import 'package:learnai/res/assets/Images.dart';
import 'package:learnai/res/methods/QuizMethods.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:learnai/res/colors/Colors.dart';
import 'package:learnai/res/spaces/Spaces.dart';
import 'package:learnai/res/styles/TextStyles.dart';

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
  bool calculate = false;

  @override
  void initState() {
    super.initState();
    QuizMethods.fetchQuizData(setState, widget.subject, setLoad,
        setNoQuizAvailable, quizData!, load, _noQuizAvailable, context);
    QuizMethods.startCountdown(
        setState,
        remainingTime,
        countdownTimer,
        (option) => QuizMethods.submitAnswer(
            option,
            currentIndex,
            quizData!,
            setState,
            countdownTimer,
            widget.subject,
            context,
            remainingTime,
            selectedOption));
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  void setLoad(bool value) {
    setState(() {
      load = value;
    });
  }

  void setNoQuizAvailable(bool value) {
    setState(() {
      _noQuizAvailable = value;
    });
  }

  void setCalculate(bool value) {
    setState(() {
      calculate = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: MyAppBar(),
        body: load
            ? Center(
                child: SpinKitCircle(
                  size: 35.sp,
                  itemBuilder: (BuildContext context, int index) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index.isEven
                            ? globalController.primaryColor.value
                            : AppColors.white,
                      ),
                    );
                  },
                ),
              )
            : _noQuizAvailable
                ? Center(
                    child: Text(
                      'No Quiz Available',
                      style: TextStyles.header1(AppColors.black),
                    ),
                  )
                : Column(
                    children: [
                      Spaces.height(2),
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
                              selectedColor:
                                  globalController.primaryColor.value,
                              unselectedColor: AppColors.secondary,
                            ),
                          ),
                          Spaces.width(3),
                          Icon(
                            Icons.timer_outlined,
                            color: AppColors.black,
                          ),
                          Spaces.width(0.5),
                          Text(
                            remainingTime.toString(),
                            style: TextStyles.header2(AppColors.black),
                          ),
                        ],
                      ),
                      Spaces.height(3),
                      Part1(),
                      Spaces.height(5),
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
              backgroundColor: AppColors.red,
              content: Text('Select one possible answer',
                  style: TextStyles.body(AppColors.white, 16, FontWeight.w500)),
            ),
          );
          return;
        }

        countdownTimer?.cancel();
        QuizMethods.submitAnswer(
            selectedOption,
            currentIndex,
            quizData!,
            setState,
            countdownTimer,
            widget.subject,
            context,
            remainingTime,
            selectedOption);
      },
      child: Container(
        height: 9.h,
        width: 87.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.sp),
          color: AppColors.primary,
        ),
        child: Text(
          'CONTINUE',
          style: TextStyles.header1(AppColors.white),
        ),
      ),
    );
  }

  MyResult() {
    return InkWell(
      onTap: () async {
        QuizMethods.calculateResults(
            setState, widget.subject, setCalculate, context, calculate);
      },
      child: Container(
        height: 9.h,
        width: 87.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.sp),
          color: globalController.primaryColor.value,
        ),
        child: calculate
            ? Center(
                child: SpinKitCircle(
                    size: 35.sp,
                    itemBuilder: (BuildContext context, int index) {
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index.isEven
                              ? globalController.primaryColor.value
                              : AppColors.white,
                        ),
                      );
                    }))
            : Text(
                'View Results',
                style: TextStyles.header1(AppColors.white),
              ),
      ),
    );
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
          Spaces.height(1),
          Container(
            width: 85.w,
            child: Text(
              question,
              textAlign: TextAlign.center,
              style: TextStyles.subtitle(AppColors.black),
            ),
          ),
          Spaces.height(3),
          box(selectedOption),
          Spaces.height(2),
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
            AppImages.my,
            width: 47.w,
          ),
          Spaces.height(3),
          Center(
            child: Container(
              width: 80.w,
              child: Text(
                'Quiz Completed',
                textAlign: TextAlign.center,
                style: TextStyles.header2(AppColors.black),
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
        color: AppColors.secondary,
        border: Border.all(color: AppColors.black, width: 5.sp),
      ),
      child: selectedOption != null
          ? Wrap(
              children: [
                Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 15.sp, vertical: 13.sp),
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(15.sp),
                    ),
                    child: Text(
                      selectedOption,
                      style:
                          TextStyles.body(AppColors.white, 16, FontWeight.w500),
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
            color: AppColors.black,
            borderRadius: BorderRadius.circular(15.sp),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyles.body(AppColors.white, 15, FontWeight.w500),
          )),
    );
  }

  void showSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
