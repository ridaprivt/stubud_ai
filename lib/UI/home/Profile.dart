import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnai/UI/home/Badges.dart';
import 'package:learnai/UI/home/EditProfile.dart';
import 'package:learnai/UI/home/Home.dart';
import 'package:learnai/UI/home/Settings.dart';
import 'package:learnai/UI/subject/Subject.dart';
import 'package:learnai/UI/subscription/Subscription.dart';
import 'package:learnai/main.dart';
import 'package:learnai/res/assets/Images.dart';
import 'package:learnai/res/colors/Colors.dart';
import 'package:learnai/res/methods/ProfileMethods.dart';
import 'package:learnai/res/spaces/Spaces.dart';
import 'package:learnai/res/styles/TextStyles.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  List<String> items = [];
  TextEditingController textEditingController = TextEditingController();
  TextEditingController gradeController = TextEditingController();
  bool post = false;
  bool isGreen = true;
  String badge = '';

  @override
  void initState() {
    super.initState();
    ProfileMethods.calculateAndAssignBadges();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ProfileMethods.getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SafeArea(
              child: Scaffold(
                  body: SpinKitCircle(
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
          )));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text('No user data found'));
        }

        Map<String, dynamic> userData = snapshot.data!;
        List<String> subjects = List<String>.from(userData['subjects'] ?? []);
        String badge = userData['badge'] ?? '';

        return SafeArea(
            child: Scaffold(
          backgroundColor: globalController.primaryColor.value,
          body: SingleChildScrollView(
            child: Container(
              height: 100.h,
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Image.asset(
                        AppImages.cable,
                        width: 100.w,
                      ),
                      const Spacer(),
                      Container(
                        height: 80.h,
                        width: 100.w,
                        decoration: BoxDecoration(
                            color: AppColors.white,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.grey.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            borderRadius: BorderRadius.only(
                                topRight: Radius.circular(25.sp),
                                topLeft: Radius.circular(25.sp))),
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(15.sp),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Get.to(EditProfile());
                                    },
                                    child: CircleAvatar(
                                      backgroundColor:
                                          globalController.primaryColor.value,
                                      radius: 19.sp,
                                      child: Image.asset(
                                        AppImages.avatar1,
                                        height: 19.sp,
                                      ),
                                    ),
                                  ),
                                  Spacer(),
                                  InkWell(
                                    onTap: () {
                                      Get.to(MySettings());
                                    },
                                    child: CircleAvatar(
                                      backgroundColor:
                                          globalController.primaryColor.value,
                                      radius: 19.sp,
                                      child: Image.asset(
                                        AppImages.avatar2,
                                        height: 19.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Spaces.height(3),
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    userData['userName'],
                                    textAlign: TextAlign.center,
                                    style: TextStyles.header1(AppColors.black),
                                  ),
                                  Spaces.height(1),
                                  Text(
                                    userData['email'] ?? '',
                                    textAlign: TextAlign.center,
                                    style: TextStyles.body(
                                        AppColors.grey, 15, FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Spaces.height(1),
                            InkWell(
                              onTap: () {
                                Get.to(Subscription());
                              },
                              child: Padding(
                                padding: EdgeInsets.all(15.sp),
                                child: Row(
                                  children: [
                                    Text(
                                      'Upgrade to Premium ',
                                      style: TextStyles.body(
                                          AppColors.black, 18, FontWeight.bold),
                                    ),
                                    Icon(
                                      Icons.star,
                                      color: AppColors.amber,
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Spaces.height(1),
                            InkWell(
                              onTap: () {
                                Get.to(Badges(
                                  unlockedBadgeName: badge,
                                ));
                              },
                              child: Container(
                                padding: EdgeInsets.all(15.sp),
                                margin: EdgeInsets.symmetric(horizontal: 15.sp),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.sp),
                                    color: globalController.primaryColor.value),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text('BADGES',
                                            textAlign: TextAlign.center,
                                            style: TextStyles.header2(
                                                AppColors.black)),
                                        const Spacer(),
                                        const Icon(Icons.arrow_forward)
                                      ],
                                    ),
                                    Spaces.height(2),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (badge == 'Quick Learner')
                                          badgeWidget('a', 'Quick Learner'),
                                        if (badge == 'Night Owl')
                                          badgeWidget('b', 'Night Owl'),
                                        if (badge == 'High Achiever')
                                          badgeWidget('c', 'High Achiever'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Spaces.height(1),
                            Padding(
                              padding: EdgeInsets.all(15.sp),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Subject Trouble?',
                                    style: TextStyles.body(
                                        AppColors.black, 18, FontWeight.bold),
                                  ),
                                  Spacer(),
                                  InkWell(
                                    onTap: () =>
                                        ProfileMethods.showAddSubjectDialog(
                                            context, items),
                                    child: Icon(
                                      Icons.add,
                                      color: AppColors.black,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 47.sp,
                              child: ListView.builder(
                                padding: EdgeInsets.only(right: 3.w),
                                scrollDirection: Axis.horizontal,
                                shrinkWrap: true,
                                itemCount: subjects.length,
                                itemBuilder: (context, index) {
                                  return subjectWidget(subjects[index]);
                                },
                              ),
                            ),
                            Spaces.height(7),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: CircleAvatar(
                        backgroundColor: AppColors.white,
                        radius: 35.sp,
                        backgroundImage: NetworkImage(
                          userData['userPhotoUrl'] ??
                              'https://via.placeholder.com/150',
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                      onPressed: () {
                        Get.offAll(Home());
                      },
                      icon: Container(
                        padding: EdgeInsets.all(10.sp),
                        decoration: BoxDecoration(
                            color: AppColors.black, shape: BoxShape.circle),
                        child: Icon(
                          Icons.arrow_back,
                          color: AppColors.white,
                        ),
                      ))
                ],
              ),
            ),
          ),
        ));
      },
    );
  }

  subjectWidget(String name) {
    return Stack(
      children: [
        InkWell(
          onTap: () {
            Get.to(() => Subject(subjectName: name));
          },
          child: Container(
            padding: EdgeInsets.all(10.sp),
            margin: EdgeInsets.only(left: 15.sp),
            width: 47.sp,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey, width: 3.sp),
              borderRadius: BorderRadius.circular(20.sp),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  AppImages.sub,
                  width: 37.sp,
                  height: 37.sp,
                ),
                Text(
                  name,
                  style: TextStyles.body(AppColors.black, 15, FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 0,
          child: InkWell(
            onTap: () => ProfileMethods.removeSubject(context, items, name),
            child: CircleAvatar(
              backgroundColor: AppColors.red,
              radius: 13.sp,
              child: Icon(
                Icons.close,
                color: AppColors.white,
                size: 15.sp,
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget badgeWidget(String img, String text) {
    return Column(
      children: [
        Image.asset(
          'assets/$img.png',
          width: 23.w,
        ),
        Spaces.height(1),
        Text(text,
            textAlign: TextAlign.center,
            style: TextStyles.body(
              AppColors.black,
              15,
              FontWeight.w500,
            ))
      ],
    );
  }
}
