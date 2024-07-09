import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learnai/UI/authentication/Login.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:animate_do/animate_do.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  void _toggleVisibility(bool isPassword) {
    setState(() {
      if (isPassword) {
        isPasswordVisible = !isPasswordVisible;
      } else {
        isConfirmPasswordVisible = !isConfirmPasswordVisible;
      }
    });
  }

  bool isSigningUp = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      backgroundColor: Color(0xff1ED760),
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
                    SizedBox(height: 5.h),
                    FadeInUp(
                      duration: Duration(milliseconds: 1200),
                      child: Text(
                        'Sign Up',
                        style: GoogleFonts.poppins(
                            fontSize: 25.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    FadeInUp(
                        duration: Duration(milliseconds: 1200),
                        child: Text("Create an account, It's free",
                            style: GoogleFonts.poppins(
                                fontSize: 15.sp, color: Colors.grey[700]))),
                    SizedBox(height: 3.h),
                    makeInput(
                        label: "Email",
                        controller: emailController,
                        obscureText: false),
                    makeInput(
                        label: "Password",
                        controller: passwordController,
                        obscureText: isPasswordVisible,
                        toggleVisibility: () => _toggleVisibility(true)),
                    makeInput(
                        label: "Confirm Password",
                        controller: confirmPasswordController,
                        obscureText: isConfirmPasswordVisible,
                        toggleVisibility: () => _toggleVisibility(false)),
                    SizedBox(height: 2.h),
                    FadeInUp(
                      duration: Duration(milliseconds: 1400),
                      child: MaterialButton(
                        minWidth: double.infinity,
                        height: 7.h,
                        onPressed: signUpWithFirebase,
                        color: Color(0xff1ED760),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.sp)),
                        child: isSigningUp
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text("Sign Up",
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 19.sp)),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Center(
                      child: FadeInUp(
                        duration: Duration(milliseconds: 1500),
                        child: GestureDetector(
                          onTap: () {
                            Get.off(Login());
                          },
                          child: Text("Already have an account? Login",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.sp)),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    ));
  }

  Widget makeInput(
      {required String label,
      required TextEditingController controller,
      required bool obscureText,
      Function? toggleVisibility}) {
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
            style: GoogleFonts.poppins(),
            obscureText: obscureText,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xff1ED760))),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: const Color.fromARGB(255, 221, 221, 221))),
              border: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: const Color.fromARGB(255, 224, 224, 224))),
              suffixIcon: toggleVisibility != null
                  ? IconButton(
                      icon: Icon(obscureText
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: toggleVisibility as void Function()?,
                    )
                  : null,
            ),
          ),
          SizedBox(height: 1.5.h),
        ],
      ),
    );
  }

  Future<void> signUpWithFirebase() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please fill out all fields',
        backgroundColor: const Color.fromARGB(255, 252, 39, 24),
        colorText: Colors.white,
      );
      return; // Exit the function if any field is empty
    }

    // Validate the email format
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

    // Validate the password length
    if (passwordController.text.length < 8) {
      Get.snackbar(
        'Validation Error',
        'Password must be at least 8 characters long',
        backgroundColor: const Color.fromARGB(255, 252, 39, 24),
        colorText: Colors.white,
      );
      return;
    }
    if (confirmPasswordController.text.length < 8) {
      Get.snackbar(
        'Validation Error',
        'Password must be at least 8 characters long',
        backgroundColor: const Color.fromARGB(255, 252, 39, 24),
        colorText: Colors.white,
      );
      return;
    }
    if (confirmPasswordController.text != passwordController.text) {
      Get.snackbar(
        'Passwords not matched',
        'please enter same passwords',
        backgroundColor: const Color.fromARGB(255, 252, 39, 24),
        colorText: Colors.white,
      );
      return; // Exit the function if any field is empty
    }

    setState(() {
      isSigningUp = true;
    });
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      final user = userCredential.user;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        Get.snackbar(
          'Success',
          'Please check your email to verify your account',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }

      emailController.clear();
      passwordController.clear();
      Get.off(Login());
    } catch (e) {
      print('Error: $e');
      Get.snackbar(
        'Failed',
        'Failed to verify account: $e',
        backgroundColor: const Color.fromARGB(255, 252, 39, 24),
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        isSigningUp = false;
      });
    }
  }
}
