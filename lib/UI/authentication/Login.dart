import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:learnai/UI/authentication/SetUp.dart';
import 'package:learnai/UI/authentication/SignUp.dart';
import 'package:learnai/UI/authentication/UserInfo.dart';
import 'package:learnai/UI/home/Home.dart';
import 'package:learnai/main.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = true;
  bool isLoggingIn = false;
  bool isGoogle = false;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      backgroundColor: globalController.primaryColor.value,
      body: ListView(
        children: [
          Image.asset('assets/bg.png'),
          FadeInUp(
            duration: Duration(milliseconds: 600),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25.sp),
                      topRight: Radius.circular(25.sp))),
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 23.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 6.h),
                    FadeInUp(
                      duration: Duration(milliseconds: 1200),
                      child: Text(
                        'Login',
                        style: GoogleFonts.poppins(
                            fontSize: 25.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    FadeInUp(
                        duration: Duration(milliseconds: 1200),
                        child: Text("Login to your account",
                            style: GoogleFonts.poppins(
                                fontSize: 15.sp, color: Colors.grey[700]))),
                    SizedBox(height: 3.h),
                    makeInput(label: "Email", controller: emailController),
                    makeInput(
                        label: "Password",
                        obscureText: true,
                        controller: passwordController),
                    SizedBox(height: 1.h),
                    FadeInUp(
                      duration: Duration(milliseconds: 1400),
                      child: MaterialButton(
                        minWidth: double.infinity,
                        height: 6.h,
                        onPressed: () => LoginWithEmail(),
                        color: globalController.primaryColor.value,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.sp)),
                        child: isLoggingIn
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text("Login",
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17.sp)),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    FadeInUp(
                      duration: Duration(milliseconds: 1400),
                      child: MaterialButton(
                        minWidth: double.infinity,
                        height: 6.h,
                        onPressed: () => LoginWithGoogle(),
                        color: Color.fromARGB(255, 17, 17, 17),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.sp)),
                        child: isGoogle
                            ? CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/google.png',
                                    height: 4.h,
                                  ),
                                  Text(" Login with Google",
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 17.sp)),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Center(
                      child: FadeInUp(
                        duration: Duration(milliseconds: 1500),
                        child: GestureDetector(
                          onTap: () {
                            Get.off(SignUp());
                          },
                          child: Text("Don't have an account? Sign up",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.sp)),
                        ),
                      ),
                    ),
                    SizedBox(height: 7.h),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    ));
  }

  Future<void> LoginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        setState(() {
          isGoogle = true;
        });
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        final user = userCredential.user;

        if (user != null) {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          bool userExists = userDoc.exists;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userID', user.uid);
          await prefs.setString('userName', user.displayName ?? '');
          await prefs.setString('userEmail', user.email ?? '');
          await prefs.setString('userPhotoUrl', user.photoURL ?? '');

          if (!userExists) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
              'userID': user.uid,
              'email': user.email,
              'subscription': false,
              'userName': user.displayName,
              'userPhotoUrl': user.photoURL,
            });
            Get.offAll(SetUp()); // Redirect to setup screen
          } else {
            Get.offAll(Home()); // Redirect to home screen
          }

          Get.snackbar(
            'Success',
            'Sign In with Google Successful',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Failed',
            'Sign In with Google Failed',
            backgroundColor: const Color.fromARGB(255, 252, 39, 24),
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          'Failed',
          'Sign In with Google Failed',
          backgroundColor: const Color.fromARGB(255, 252, 39, 24),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error: $e');
      Get.snackbar(
        'Failed',
        'Sign In with Google Failed: $e',
        backgroundColor: const Color.fromARGB(255, 252, 39, 24),
        colorText: Colors.white,
      );
    }
    setState(() {
      isGoogle = false;
    });
  }

  Future<void> LoginWithEmail() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please fill out all fields',
        backgroundColor: const Color.fromARGB(255, 252, 39, 24),
        colorText: Colors.white,
      );
      return;
    }
    final emailPattern = RegExp(
      r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$',
    );
    if (!emailPattern.hasMatch(emailController.text)) {
      Get.snackbar(
        'Validation Error',
        'Please enter a valid email address',
        backgroundColor: const Color.fromARGB(255, 252, 39, 24),
        colorText: Colors.white,
      );
      return; // Exit the function if email format is invalid
    }
    if (passwordController.text.length < 8) {
      Get.snackbar(
        'Validation Error',
        'Password must be at least 8 characters long',
        backgroundColor: const Color.fromARGB(255, 252, 39, 24),
        colorText: Colors.white,
      );
      return;
    }
    try {
      setState(() {
        isLoggingIn = true; // Show progress indicator
      });

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      User? user = userCredential.user;

      if (user != null && !user.emailVerified) {
        Get.snackbar(
          'Success',
          'Please check your email to verify your account',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
      } else if (user != null && user.emailVerified) {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        bool userExists = userDoc.exists;
        if (!userExists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'subscription': false,
            'email': emailController.text,
            'userID': user.uid,
            'userName': '',
            'userPhotoUrl': '',
            'grade': '',
          });
          Get.offAll(MyUserInfo());
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userID', user.uid);
          await prefs.setString('userEmail', user.email ?? '');
          Get.snackbar(
            'Success',
            'Sign In Successful',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          if (userDoc['userName'] == null ||
              userDoc['userName'].isEmpty ||
              userDoc['userPhotoUrl'] == null ||
              userDoc['userPhotoUrl'].isEmpty) {
            Get.offAll(MyUserInfo());
          } else if (userDoc['grade'] == null ||
              userDoc['grade'].isEmpty ||
              userDoc['subjects'] == null ||
              userDoc['subjects'].isEmpty) {
            Get.offAll(SetUp());
          } else {
            Get.offAll(Home());
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userID', user.uid);
          await prefs.setString('userEmail', user.email ?? '');

          Get.snackbar(
            'Success',
            'Sign In Successful',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == 'invalid-email' || e.code == 'wrong-password') {
          Get.snackbar(
            'Login Failed',
            'Invalid credentials or User account does not exist',
            backgroundColor: const Color.fromARGB(255, 252, 39, 24),
            colorText: Colors.white,
          );
        }
      }
    } finally {
      setState(() {
        isLoggingIn = false;
      });
    }
  }

  makeInput({label, obscureText = false, TextEditingController? controller}) {
    return FadeInUp(
        duration: Duration(milliseconds: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87)),
            SizedBox(height: 1.h),
            TextField(
              controller: controller,
              obscureText: obscureText,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(vertical: 16.sp, horizontal: 10.sp),
                focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: globalController.primaryColor.value)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400)),
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade400)),
              ),
            ),
            SizedBox(height: 3.h),
          ],
        ));
  }
}
