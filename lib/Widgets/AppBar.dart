import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:learnai/UI/home/Profile.dart';
import 'package:learnai/main.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final UserController userController = Get.put(UserController());
  final RxBool isNotificationEnabled = false.obs;

  MyAppBar() {
    _loadNotificationState();
  }

  Future<void> _loadNotificationState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isNotificationEnabled.value =
        prefs.getBool('notification_enabled') ?? false;
  }

  Future<void> _toggleNotification() async {
    isNotificationEnabled.value = !isNotificationEnabled.value;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('notification_enabled', isNotificationEnabled.value);
  }

  @override
  Size get preferredSize => Size.fromHeight(15.h);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (userController.isLoading.value) {
        return AppBar(
          backgroundColor: globalController.primaryColor.value,
          toolbarHeight: 15.h,
          title: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      Map<String, dynamic> userData = userController.userData.value;

      return AppBar(
        backgroundColor: globalController.primaryColor.value,
        toolbarHeight: 15.h,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(25.sp),
          ),
        ),
        elevation: 2,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
              onTap: () {
                Get.to(Profile());
              },
              child: CircleAvatar(
                backgroundColor: Color.fromARGB(255, 255, 255, 255),
                radius: 23.sp,
                backgroundImage: NetworkImage(
                  userData['userPhotoUrl'] ?? 'https://via.placeholder.com/150',
                ),
              ),
            ),
            SizedBox(width: 3.w),
            InkWell(
              onTap: () {
                Get.to(Profile());
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData['userName'] ?? '',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    userData['email'] ?? '',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            InkWell(
              onTap: () async {
                await _toggleNotification();
              },
              child: Obx(() {
                return Container(
                  height: 6.h,
                  width: 6.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isNotificationEnabled.value ? Colors.red : Colors.black,
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }
}

class UserController extends GetxController {
  var userData = <String, dynamic>{}.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.data() != null) {
        userData.value = userDoc.data() as Map<String, dynamic>;
      }
    }
    isLoading.value = false;
  }
}
