import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learnai/UI/home/Home.dart';
import 'package:learnai/Widgets/AppBar.dart';
import 'package:learnai/main.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class Result extends StatefulWidget {
  final String totalMarks;
  final String obtainedMarks;

  const Result(
      {Key? key, required this.totalMarks, required this.obtainedMarks})
      : super(key: key);

  @override
  State<Result> createState() => _ResultState();
}

class _ResultState extends State<Result> {
  late String feedbackMessage;
  late String feedbackTitle;

  @override
  void initState() {
    super.initState();
    _calculateFeedback();
  }

  void _calculateFeedback() {
    int total = int.parse(widget.totalMarks);
    int obtained = int.parse(widget.obtainedMarks);
    double percentage = (obtained / total) * 100;

    if (percentage >= 80) {
      feedbackTitle = 'Perfect Exercise';
      feedbackMessage = 'You did a great job';
    } else if (percentage >= 50) {
      feedbackTitle = 'Good Job';
      feedbackMessage = 'You did well, but there is room for improvement';
    } else {
      feedbackTitle = 'Needs Improvement';
      feedbackMessage = 'Keep practicing and you will get better';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: MyAppBar(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 9.h),
            Center(
              child: Image.asset(
                'assets/result.png',
                height: 27.h,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              feedbackTitle,
              style: GoogleFonts.poppins(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 21.sp,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              feedbackMessage,
              style: GoogleFonts.poppins(
                color: const Color.fromARGB(255, 0, 0, 0),
                fontWeight: FontWeight.w500,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 3.h),
            Container(
              height: 7.h,
              width: 50.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.sp),
                color: globalController.primaryColor.value,
              ),
              child: Text(
                '${widget.obtainedMarks}/${widget.totalMarks}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  height: 3.sp,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
              ),
            ),
            SizedBox(height: 6.h),
            InkWell(
              onTap: () {
                Get.offAll(Home());
              },
              child: Container(
                height: 9.h,
                width: 87.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.sp),
                  color: const Color.fromARGB(255, 44, 44, 44),
                ),
                child: Text(
                  'Back Home',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    height: 3.sp,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
