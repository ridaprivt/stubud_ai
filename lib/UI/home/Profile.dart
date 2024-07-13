import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learnai/UI/authentication/Login.dart';
import 'package:learnai/UI/home/EditProfile.dart';
import 'package:learnai/UI/home/Home.dart';
import 'package:learnai/UI/home/Settings.dart';
import 'package:learnai/UI/subject/Subject.dart';
import 'package:learnai/UI/subscription/Subscription.dart';
import 'package:learnai/main.dart';
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

  @override
  void initState() {
    super.initState();
    _calculateAndAssignBadges();
  }

  Future<Map<String, dynamic>> _getUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return userDoc.data() as Map<String, dynamic>;
    }
    return {};
  }

  Future<void> _calculateAndAssignBadges() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      CollectionReference quizzesCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('quizzes');

      QuerySnapshot subjectSnapshots = await quizzesCollection.get();

      int totalScore = 0;
      int totalMarks = 0;
      int quizCount = 0;

      for (var subjectDoc in subjectSnapshots.docs) {
        print('Processing subject: ${subjectDoc.id}');

        // Get all quiz collections (quiz1, quiz2, etc.) under each subject
        QuerySnapshot quizzesSnapshot = await quizzesCollection
            .doc(subjectDoc.id)
            .collection('quizzes')
            .get();

        for (var quizDoc in quizzesSnapshot.docs) {
          print('Processing quiz: ${quizDoc.id}');

          // Get the quizData document within each quiz collection
          DocumentSnapshot quizDataDoc = await quizzesCollection
              .doc(subjectDoc.id)
              .collection(quizDoc.id)
              .doc('quizData')
              .get();

          if (quizDataDoc.exists) {
            var quizData = quizDataDoc.data() as Map<String, dynamic>;
            print('Quiz data found: $quizData');
            if (quizData.containsKey('obtained_marks') &&
                quizData.containsKey('total_marks')) {
              totalScore += int.parse(quizData['obtained_marks']);
              totalMarks += int.parse(quizData['total_marks']);
              quizCount++;
            } else {
              print('Quiz data missing required fields.');
            }
          } else {
            print('Quiz data does not exist for ${quizDoc.id}');
          }
        }
      }

      print('Total quizzes processed: $quizCount');
      print('Total score: $totalScore');
      print('Total marks: $totalMarks');

      String badge = '';

      double averageScore = (totalScore / totalMarks) * 100;
      if (averageScore >= 90) {
        badge = 'High Achiever';
      } else if (averageScore >= 70) {
        badge = 'Quick Learner';
      } else {
        badge = 'Night Owl';
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'badge': badge});
    }
  }

  Future<void> proceed() async {
    if (gradeController.text.isEmpty || items.isEmpty) {
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
        'grade': gradeController.text,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data saved successfully!')),
      );
      Get.offAll(Home());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save data: $e')),
      );
    } finally {
      setState(() {
        post = false;
      });
    }
  }

  Future<void> _showAddSubjectDialog() async {
    TextEditingController subjectController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Add Subject',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
          content: TextField(
            controller: subjectController,
            decoration: InputDecoration(
              hintText: 'Enter Subject',
              hintStyle: GoogleFonts.poppins(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Add',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                if (subjectController.text.isNotEmpty) {
                  setState(() {
                    items.add(subjectController.text);
                  });

                  final prefs = await SharedPreferences.getInstance();
                  final userId = prefs.getString('userID') ?? 'unknown';

                  CollectionReference users =
                      FirebaseFirestore.instance.collection('users');

                  try {
                    await users.doc(userId).set({
                      'subjects':
                          FieldValue.arrayUnion([subjectController.text]),
                    }, SetOptions(merge: true));

                    // Display Snackbar after successfully saving the data
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Subject added successfully!')),
                    );
                    Get.offAll(Home());
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add subject: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
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
                        'assets/cable.png',
                        width: 100.w,
                      ),
                      const Spacer(),
                      Container(
                        height: 80.h,
                        width: 100.w,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
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
                                        'assets/1.png',
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
                                        'assets/2.png',
                                        height: 19.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    userData['userName'],
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                        height: 4.sp,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20.sp),
                                  ),
                                  SizedBox(height: 1.h),
                                  Text(
                                    userData['email'] ?? '',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                        height: 5.sp,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15.sp),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 1.h),
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
                                      style: GoogleFonts.poppins(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18.sp),
                                    ),
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    )
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Container(
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
                                          style: GoogleFonts.poppins(
                                            height: 5.sp,
                                            fontSize: 20.sp,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          )),
                                      const Spacer(),
                                      const Icon(Icons.arrow_forward)
                                    ],
                                  ),
                                  SizedBox(height: 2.h),
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
                            SizedBox(height: 1.h),
                            Padding(
                              padding: EdgeInsets.all(15.sp),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Subject Trouble?',
                                    style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.sp),
                                  ),
                                  Spacer(),
                                  InkWell(
                                    onTap: _showAddSubjectDialog,
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.black,
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
                            SizedBox(height: 7.h),
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
                        backgroundColor:
                            const Color.fromARGB(255, 255, 255, 255),
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
                            color: Colors.black, shape: BoxShape.circle),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
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
              border: Border.all(color: Colors.grey, width: 3.sp),
              borderRadius: BorderRadius.circular(20.sp),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/sub.jpg',
                  width: 37.sp,
                  height: 37.sp,
                ),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 15.sp),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 0,
          child: InkWell(
            onTap: () {
              removeSubject(name);
            },
            child: CircleAvatar(
              backgroundColor: Colors.red,
              radius: 13.sp,
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 15.sp,
              ),
            ),
          ),
        )
      ],
    );
  }

  Future<void> removeSubject(String subject) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userID') ?? 'unknown';

    CollectionReference users = FirebaseFirestore.instance.collection('users');

    try {
      await users.doc(userId).update({
        'subjects': FieldValue.arrayRemove([subject]),
      });

      setState(() {
        items.remove(subject);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subject removed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove subject: $e')),
      );
    }
  }

  Widget badgeWidget(String img, String text) {
    return Column(
      children: [
        Image.asset(
          'assets/$img.png',
          width: 23.w,
        ),
        SizedBox(height: 1.h),
        Text(text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              height: 5.sp,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ))
      ],
    );
  }
}
