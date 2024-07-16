import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:learnai/UI/authentication/Login.dart';
import 'package:learnai/UI/authentication/SetUp.dart';
import 'package:learnai/UI/home/Home.dart';
import 'package:learnai/main.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyUserInfo extends StatefulWidget {
  const MyUserInfo({super.key});

  @override
  State<MyUserInfo> createState() => _UserInfoState();
}

class _UserInfoState extends State<MyUserInfo> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  File? _image;
  bool post = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String> uploadImage(File image) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    String extension = image.path.split('.').last;
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('$fileName.$extension');
    final result = await ref.putFile(image);
    return await result.ref.getDownloadURL();
  }

  Future<void> saveUserData(String name, String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userID') ?? 'unknown';
    final usersRef = FirebaseFirestore.instance.collection('users').doc(userId);
    await usersRef.update({
      'userName': name,
      'userPhotoUrl': imageUrl,
    });
    await prefs.setString('userName', name ?? ''); // Storing user name
    await prefs.setString('userPhotoUrl', imageUrl ?? '');
  }

  Future<void> proceed() async {
    if (_image == null || _nameController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select a picture and enter your full name.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      post = true;
    });
    final prefs = await SharedPreferences.getInstance();
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      if (_image != null) {
        final imageUrl = await uploadImage(_image!);
        await saveUserData(name, imageUrl);
        await prefs.setString('userPhotoUrl', imageUrl);
        await prefs.setString('userName', name);
        setState(() {
          post = false;
        });
        Get.off(SetUp());
      }
    }
    setState(() {
      post = false;
    });
  }

  @override
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
            child: Form(
              key: _formKey,
              child: Padding(
                padding: EdgeInsets.all(17.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () async {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            await prefs.clear();
                            await FirebaseAuth.instance.signOut();
                            Get.offAll(Login());
                          },
                          child: Container(
                              color: Colors.white,
                              child: Icon(
                                Icons.arrow_back,
                                color: globalController.primaryColor.value,
                                size: 23.sp,
                              )),
                        ),
                      ],
                    ),
                    SizedBox(height: 17.h),
                    InkWell(
                      onTap: pickImage,
                      child: Center(
                        child: _image != null
                            ? CircleAvatar(
                                radius:
                                    45.sp, // This will give a diameter of 55.sp
                                backgroundImage: FileImage(_image!),
                              )
                            : Container(
                                width: 65.sp,
                                height: 65.sp,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.camera_alt,
                                    size: 35.sp, color: Colors.grey[500]),
                              ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Center(
                      child: Container(
                        width: 80.w,
                        child: TextFormField(
                          controller: _nameController,
                          style: GoogleFonts.poppins(
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontWeight: FontWeight.w500,
                              fontSize: 17.sp),
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(
                              Icons.person,
                              color: globalController.primaryColor.value,
                            ),
                            labelStyle: GoogleFonts.poppins(
                                color: globalController.primaryColor.value,
                                fontWeight: FontWeight.w500,
                                fontSize: 17.sp),
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
                                style: GoogleFonts.poppins(fontSize: 17.sp)),
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
      ),
    );
  }
}
