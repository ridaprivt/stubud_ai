import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learnai/UI/home/Home.dart';
import 'package:learnai/res/colors/Colors.dart';

class ProfileMethods {
  static Future<Map<String, dynamic>> getUserData() async {
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

  static Future<void> calculateAndAssignBadges() async {
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
        QuerySnapshot quizzesSnapshot = await quizzesCollection
            .doc(subjectDoc.id)
            .collection('quizzes')
            .get();

        for (var quizDoc in quizzesSnapshot.docs) {
          DocumentSnapshot quizDataDoc = await quizzesCollection
              .doc(subjectDoc.id)
              .collection(quizDoc.id)
              .doc('quizData')
              .get();

          if (quizDataDoc.exists) {
            var quizData = quizDataDoc.data() as Map<String, dynamic>;
            if (quizData.containsKey('obtained_marks') &&
                quizData.containsKey('total_marks')) {
              totalScore += int.parse(quizData['obtained_marks']);
              totalMarks += int.parse(quizData['total_marks']);
              quizCount++;
            }
          }
        }
      }

      double averageScore = (totalScore / totalMarks) * 100;
      String badge;
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

  static Future<void> proceed(BuildContext context, List<String> items,
      String grade, TextEditingController gradeController, bool post) async {
    if (gradeController.text.isEmpty || items.isEmpty) {
      Get.snackbar(
        'Error',
        'Please add subjects and grade.',
        backgroundColor: AppColors.red,
        colorText: AppColors.white,
      );
      return;
    }
    post = true;

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
      post = false;
    }
  }

  static Future<void> showAddSubjectDialog(
      BuildContext context, List<String> items) async {
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
                  items.add(subjectController.text);

                  final prefs = await SharedPreferences.getInstance();
                  final userId = prefs.getString('userID') ?? 'unknown';

                  CollectionReference users =
                      FirebaseFirestore.instance.collection('users');

                  try {
                    await users.doc(userId).set({
                      'subjects':
                          FieldValue.arrayUnion([subjectController.text]),
                    }, SetOptions(merge: true));

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

  static Future<void> removeSubject(
      BuildContext context, List<String> items, String subject) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userID') ?? 'unknown';

    CollectionReference users = FirebaseFirestore.instance.collection('users');

    try {
      await users.doc(userId).update({
        'subjects': FieldValue.arrayRemove([subject]),
      });

      items.remove(subject);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subject removed successfully!'),
          backgroundColor: AppColors.amber,
        ),
      );
      Get.offAll(Home());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove subject: $e')),
      );
    }
  }
}
