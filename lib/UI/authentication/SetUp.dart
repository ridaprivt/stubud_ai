import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learnai/UI/home/Home.dart';
import 'package:learnai/Widgets/CustomColumn.dart';
import 'package:learnai/main.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetUp extends StatefulWidget {
  const SetUp({super.key});

  @override
  State<SetUp> createState() => _SetUpState();
}

class _SetUpState extends State<SetUp> {
  List<String> items = [];
  TextEditingController textEditingController = TextEditingController();
  TextEditingController grade = TextEditingController();
  bool post = false;

  @override
  Future<void> proceed() async {
    if (grade == null || grade.text.isEmpty || items.isEmpty) {
      Get.snackbar(
        'Error',
        'Please add subjects and grade.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    setState(() {
      post = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userID') ?? 'unknown';

      CollectionReference users =
          FirebaseFirestore.instance.collection('users');

      await users.doc(userId).set({
        'subjects': FieldValue.arrayUnion(items),
        'grade': grade.text,
      }, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data saved successfully!')),
      );
      Get.offAll(Home());
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save data: $e')),
      );
    } finally {
      setState(() {
        post = false;
      });
    }
  }

  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            height: 100.h,
            width: 100.w,
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('assets/gg.png'), fit: BoxFit.cover)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomColumnWidget(
                    heading: 'Set up subjects you want to study',
                    items: items,
                    textEditingController: textEditingController,
                    hintText: 'Enter Subject',
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Set up grade',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 18.sp,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Container(
                    width: 80.w,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(20.sp),
                    ),
                    child: TextField(
                      controller: grade,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w400,
                        fontSize: 15.sp,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      decoration: InputDecoration(
                        hintText: 'e.g 8th',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 15.sp, vertical: 13.sp),
                        hintStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w400,
                          fontSize: 15.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Center(
                    child: ElevatedButton(
                      onPressed: proceed,
                      child: post
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Save and Continue',
                              style: GoogleFonts.poppins(fontSize: 16.sp)),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: globalController.primaryColor.value,
                        padding: EdgeInsets.symmetric(
                            horizontal: 30.sp, vertical: 15.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
