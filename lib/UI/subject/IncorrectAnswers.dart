import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:learnai/Widgets/AppBar.dart';

class IncorrectAnswersScreen extends StatelessWidget {
  final int quizNumber;
  final List<Map<String, dynamic>> incorrectAnswers;

  const IncorrectAnswersScreen({
    Key? key,
    required this.quizNumber,
    required this.incorrectAnswers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filteredAnswers = incorrectAnswers
        .where((answer) => answer['quizNumber'] == quizNumber)
        .toList();

    return SafeArea(
      child: Scaffold(
        appBar: MyAppBar(),
        body: Padding(
          padding: EdgeInsets.all(1.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 1.h),
              Center(
                child: Text(
                  'Incorrect Answers',
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredAnswers.length,
                  itemBuilder: (context, index) {
                    final answer = filteredAnswers[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.sp),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(2.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Question: ${answer['question']}',
                              style: GoogleFonts.poppins(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Selected Option: ${answer['selectedOption']}',
                              style: GoogleFonts.poppins(
                                  fontSize: 15.sp, color: Colors.red),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              'Correct Answer: ${answer['correctAnswer']}',
                              style: GoogleFonts.poppins(fontSize: 15.sp),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
