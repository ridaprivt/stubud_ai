import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomeMethods {
  static Future<void> initializeData(Function setSubscriptionCallback) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userID');

    if (userId != null) {
      try {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        setSubscriptionCallback(userDoc['subscription']);
      } catch (e) {
        print('Error checking subscription status: $e');
      }
    }
  }

  static Future<void> loadCachedFacts(
      Function setStateCallback,
      List<String> mysubjects,
      Map<String, String> subjectFacts,
      Function(bool) setLoadCallback) async {
    setLoadCallback(true);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userID') ?? 'unknown';

    try {
      DocumentSnapshot userDocSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      var userDoc = userDocSnapshot.data() as Map<String, dynamic>;

      if (userDoc != null && userDoc.containsKey('subjects')) {
        mysubjects.clear();
        mysubjects.addAll(List<String>.from(userDoc['subjects']));
      }
    } catch (e) {
      print("Error fetching user document: $e");
    }

    final currentTime = DateTime.now().millisecondsSinceEpoch;

    for (String subject in mysubjects) {
      final cachedFact = prefs.getString('fact_$subject');
      final lastFetchTime = prefs.getInt('lastFetchTime_$subject');

      if (cachedFact != null && lastFetchTime != null) {
        final durationSinceLastFetch = currentTime - lastFetchTime;
        if (durationSinceLastFetch < 24 * 60 * 60 * 1000) {
          subjectFacts[subject] = cachedFact;
          continue;
        }
      }
      await fetchInterestingFact(
          subject, subjectFacts, setStateCallback, setLoadCallback);
    }
    setLoadCallback(false);
  }

  static Future<void> fetchInterestingFact(
      String subject,
      Map<String, String> subjectFacts,
      Function setStateCallback,
      Function(bool) setFactCallback) async {
    final prefs = await SharedPreferences.getInstance();
    setFactCallback(true);

    List<Map<String, dynamic>> messages = [
      {
        'role': 'user',
        'content': 'Give an short interesting fact about $subject.',
      },
    ];

    final String apiUrl =
        "https://us-central1-chatbot-b81d7.cloudfunctions.net/afnan-gpt-2";

    Map<String, String> headers = {
      "Content-Type": "application/json",
    };

    Map<String, dynamic> payload = {
      "data": {"conversation": messages}
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData.containsKey("result") &&
            responseData["result"].containsKey("response")) {
          final fact = responseData["result"]["response"].toString();

          prefs.setString('fact_$subject', fact);
          prefs.setInt(
              'lastFetchTime_$subject', DateTime.now().millisecondsSinceEpoch);

          subjectFacts[subject] = fact;
        } else {
          print('Unexpected response format.');
        }
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }

    setFactCallback(false);
  }
}
