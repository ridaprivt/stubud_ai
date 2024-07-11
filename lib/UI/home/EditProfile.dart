import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:learnai/UI/home/Home.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final TextEditingController _usernameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isLoading = false;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        _usernameController.text = userData['userName'] ?? '';
        _profileImageUrl = userData['userPhotoUrl'];
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? photoUrl;
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('/profile_images')
            .child('${user.uid}.jpg');
        await storageRef.putFile(_imageFile!);
        photoUrl = await storageRef.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'userName': _usernameController.text,
        if (photoUrl != null) 'userPhotoUrl': photoUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
    }

    setState(() {
      _isLoading = false;
    });
    Get.offAll(Home());
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
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
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
                padding: EdgeInsets.all(20.sp),
                child: Column(
                  children: [
                    SizedBox(height: 23.h),
                    InkWell(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 40.sp,
                        backgroundColor: Colors.green,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (_profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : AssetImage('assets/gg.png')) as ImageProvider,
                      ),
                    ),
                    SizedBox(height: 20.sp),
                    TextField(
                      style: GoogleFonts.poppins(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.w500,
                          fontSize: 17.sp),
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                        labelStyle: GoogleFonts.poppins(
                            color: Color(0xff1ED760),
                            fontWeight: FontWeight.w500,
                            fontSize: 17.sp),
                      ),
                    ),
                    SizedBox(height: 20.sp),
                    Center(
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Save',
                                style: GoogleFonts.poppins(fontSize: 18.sp)),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(
                              horizontal: 30.sp, vertical: 14.sp),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    )));
  }
}
