import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:learnai/Notifications/FirebaseNotifications.dart';
import 'package:learnai/UI/authentication/Login.dart';
import 'package:learnai/UI/home/Home.dart';
import 'package:learnai/Widgets/AppBar.dart';
import 'package:learnai/main.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class MySettings extends StatefulWidget {
  @override
  State<MySettings> createState() => _MySettingsState();
}

class _MySettingsState extends State<MySettings> {
  late String userId;
  String accountStatus = 'Free'; // Default status
  bool areNotificationsEnabled = false;
  bool isDeleting = false;
  bool isReauthenticating = false;

  @override
  void initState() {
    super.initState();
    fetchSubscriptionStatus();
    _loadNotificationState();
  }

  Future<void> _loadNotificationState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      areNotificationsEnabled = prefs.getBool('notification_enabled') ?? false;
    });
  }

  Future<void> _toggleNotification() async {
    setState(() {
      areNotificationsEnabled = !areNotificationsEnabled;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('notification_enabled', areNotificationsEnabled);

    if (areNotificationsEnabled) {
      NotificationService.showLocalNotification(
        'Notifications Enabled',
        'You will now receive notifications.',
        'payload',
      );
    }
  }

  void fetchSubscriptionStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        setState(() {
          accountStatus = userDoc['subscription'] ? 'Premium' : 'Free';
        });
      }
    }
  }

  void delete() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: globalController.primaryColor.value),
                  borderRadius: BorderRadius.all(Radius.circular(15.sp))),
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              title: Text(
                'Delete Account'.tr,
                style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.w600),
              ),
              content: Text(
                'Are you sure you want to delete your account?'.tr,
                style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.w400),
              ),
              actions: <Widget>[
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.sp, vertical: 12.sp),
                  decoration: BoxDecoration(
                      color: globalController.primaryColor.value,
                      borderRadius: BorderRadius.circular(20.sp),
                      border: Border.all(
                          color: globalController.primaryColor.value)),
                  child: InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      await _showReauthenticationDialog();
                    },
                    child: isDeleting
                        ? CircularProgressIndicator()
                        : Text(
                            'Yes'.tr,
                            style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                color: const Color.fromARGB(255, 249, 249, 249),
                                fontWeight: FontWeight.w500),
                          ),
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.sp, vertical: 12.sp),
                  decoration: BoxDecoration(
                      color: globalController.primaryColor.value,
                      borderRadius: BorderRadius.circular(20.sp),
                      border: Border.all(
                          color: globalController.primaryColor.value)),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'No'.tr,
                      style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          color: const Color.fromARGB(255, 249, 249, 249),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showReauthenticationDialog() async {
    TextEditingController passwordController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              side: BorderSide(color: globalController.primaryColor.value),
              borderRadius: BorderRadius.all(Radius.circular(15.sp))),
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          title: Text(
            'Re-authenticate'.tr,
            style: GoogleFonts.poppins(
                fontSize: 18.sp,
                color: Color.fromARGB(255, 0, 0, 0),
                fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please enter your password to delete your account.'.tr,
                style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.w400),
              ),
              SizedBox(height: 15.sp),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password'.tr,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 12.sp),
              decoration: BoxDecoration(
                  color: globalController.primaryColor.value,
                  borderRadius: BorderRadius.circular(20.sp),
                  border:
                      Border.all(color: globalController.primaryColor.value)),
              child: InkWell(
                onTap: () async {
                  setState(() {
                    isReauthenticating = true;
                  });
                  String password = passwordController.text.trim();
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null && password.isNotEmpty) {
                    try {
                      AuthCredential credential = EmailAuthProvider.credential(
                        email: user.email!,
                        password: password,
                      );
                      await user.reauthenticateWithCredential(credential);

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .delete();

                      await user.delete();
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.clear();

                      Navigator.pop(context);
                      Get.offAll(Login());
                    } catch (e) {
                      print('Error re-authenticating: $e');
                      if (e is FirebaseAuthException &&
                          e.code == 'wrong-password') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Incorrect password. Please try again.')),
                        );
                      }
                    }
                  }
                  setState(() {
                    isReauthenticating = false;
                  });
                },
                child: isReauthenticating
                    ? CircularProgressIndicator()
                    : Text(
                        'Confirm'.tr,
                        style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            color: const Color.fromARGB(255, 249, 249, 249),
                            fontWeight: FontWeight.w500),
                      ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 12.sp),
              decoration: BoxDecoration(
                  color: globalController.primaryColor.value,
                  borderRadius: BorderRadius.circular(20.sp),
                  border:
                      Border.all(color: globalController.primaryColor.value)),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Cancel'.tr,
                  style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      color: const Color.fromARGB(255, 249, 249, 249),
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Theme Color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: globalController.primaryColor.value,
              onColorChanged: (color) {
                globalController.setPrimaryColor(color);
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
                Get.offAll(Home());
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: MyAppBar(),
        body: Column(
          children: [
            SizedBox(height: 1.5.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Theme'.tr,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                      Spacer(),
                      Obx(
                        () => TextButton(
                          style: ButtonStyle(
                            side: MaterialStateProperty.all(
                              BorderSide(
                                  color: globalController.primaryColor.value,
                                  width: 2.0),
                            ),
                            foregroundColor: MaterialStateProperty.all(
                                globalController.primaryColor.value),
                          ),
                          onPressed: () async {
                            _showColorPicker(context);
                          },
                          child: Text(
                            'Change',
                            style: TextStyle(
                                color: globalController.primaryColor.value),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.5.h),
                  InkWell(
                    child: Row(
                      children: [
                        Text(
                          'Account Status'.tr,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                        Spacer(),
                        Text(
                          accountStatus,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w400,
                            color: globalController.primaryColor.value,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 3.5.h),
                  Row(
                    children: [
                      Text(
                        'Enable Notifications'.tr,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                      Spacer(),
                      Switch(
                        value: areNotificationsEnabled,
                        onChanged: (value) {
                          _toggleNotification();
                        },
                        activeColor: globalController.primaryColor.value,
                      ),
                    ],
                  ),
                  SizedBox(height: 3.5.h),
                  InkWell(
                    onTap: () async {
                      try {
                        await FirebaseAuth.instance.signOut();
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.clear();
                        Get.offAll(Login());
                      } catch (e) {
                        print('Error logging out: $e');
                      }
                    },
                    child: Row(
                      children: [
                        Text(
                          'Logout'.tr,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                        Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: globalController.primaryColor.value,
                          size: 18.sp,
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  InkWell(
                    onTap: delete,
                    child: Row(
                      children: [
                        Text(
                          'Delete Account'.tr,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                        Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: globalController.primaryColor.value,
                          size: 18.sp,
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
