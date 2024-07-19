import 'package:flutter/material.dart';
import 'package:learnai/res/assets/Images.dart';
import 'package:learnai/res/colors/Colors.dart';
import 'package:learnai/res/spaces/Spaces.dart';
import 'package:learnai/res/styles/TextStyles.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class InterestingFactCard extends StatelessWidget {
  final String subject;
  final String factText;
  final bool fact;

  InterestingFactCard({
    required this.subject,
    required this.factText,
    required this.fact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(17.sp),
      margin: EdgeInsets.symmetric(horizontal: 15.sp),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17.sp),
          color: AppColors.secondary),
      child: Row(
        children: [
          Container(
            width: 50.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interesting Facts',
                  style: TextStyles.body(AppColors.white, 18, FontWeight.w600),
                ),
                Spaces.height(1.7),
                fact
                    ? Center(
                        child: Transform.scale(
                          scale: 3.sp,
                          child:
                              CircularProgressIndicator(color: AppColors.white),
                        ),
                      )
                    : Center(
                        child: Text(
                          factText,
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyles.body(
                              AppColors.white, 14, FontWeight.w400),
                        ),
                      ),
              ],
            ),
          ),
          Spacer(),
          Image.asset(
            AppImages.ifImage,
            width: 30.w,
          ),
        ],
      ),
    );
  }
}
