import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:learnai/UI/home/Profile.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final UserController userController = Get.put(UserController());

  @override
  Size get preferredSize => Size.fromHeight(15.h);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (userController.isLoading.value) {
        return AppBar(
          backgroundColor: Color(0xff1ED760),
          toolbarHeight: 15.h,
          title: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      Map<String, dynamic> userData = userController.userData.value;

      return AppBar(
        backgroundColor: Color(0xff1ED760),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData['userName']?.split(' ')?.first ?? '',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 18.sp,
                  ),
                ),
                Text(
                  userData['userName']?.split(' ')?.last ?? '',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 19.sp,
                  ),
                ),
              ],
            ),
            Spacer(),
            Image.asset(
              'assets/bell.png',
              height: 6.h,
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
