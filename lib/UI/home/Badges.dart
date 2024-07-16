import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learnai/Widgets/AppBar.dart';
import 'package:learnai/main.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class Badges extends StatefulWidget {
  final String unlockedBadgeName;

  const Badges({super.key, required this.unlockedBadgeName});

  @override
  State<Badges> createState() => _BadgesState();
}

class _BadgesState extends State<Badges> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: MyAppBar(),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h),
              Text('BADGES',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    height: 5.sp,
                    fontSize: 20.sp,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  )),
              SizedBox(height: 2.h),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  badgeWidget('b', 'Night Owl',
                      'This badge is assigned to students who score below 70% in their quizzes. It acknowledges your effort and persistence in studying, even if the scores are not as high, highlighting your dedication and hard work regardless of the time of day you study.'),
                  badgeWidget('a', 'Quick Learner',
                      'This badge is given to students who achieve an average score between 70% and 89% in their quizzes. It recognizes your ability to quickly understand and apply new concepts, demonstrating strong comprehension and learning abilities.'),
                  badgeWidget('c', 'High Achiever',
                      'This badge is awarded to students who achieve an average score of 90% or higher across all their quizzes. It signifies exceptional performance and mastery of the subject matter, marking you as a top performer in your studies.'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget badgeWidget(String img, String text, String detail) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              margin: EdgeInsets.all(1.h),
              padding: EdgeInsets.all(15.sp),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.sp),
                  color: globalController.primaryColor.value.withOpacity(0.3)),
              child: Column(
                children: [
                  Image.asset(
                    'assets/$img.png',
                    width: 27.w,
                  ),
                  SizedBox(height: 1.h),
                  Text(text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        height: 5.sp,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ))
                ],
              ),
            ),
            Positioned(
              right: 0,
              child: Icon(
                Icons.lock,
                color: widget.unlockedBadgeName == text
                    ? Colors.transparent
                    : Colors.amber,
              ),
            )
          ],
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(1.7.h),
            child: Text(detail,
                textAlign: TextAlign.justify,
                style: GoogleFonts.poppins(
                  fontSize: 13.5.sp,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                )),
          ),
        )
      ],
    );
  }
}
