import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learnai/Widgets/AppBar.dart';
import 'package:learnai/main.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false;
  int dotColorIndex = 0;
  late Timer dotTimer;

  @override
  void initState() {
    super.initState();
    dotTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        dotColorIndex = (dotColorIndex + 1) % 3;
      });
    });
  }

  @override
  void dispose() {
    dotTimer.cancel();
    super.dispose();
  }

  void _addMessage(String text, {String sender = 'user'}) {
    setState(() {
      _messages.add({'sender': sender, 'content': text});
    });
  }

  Future<void> _getResponse() async {
    setState(() {
      isLoading = true;
    });
    final String userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    _addMessage(userMessage, sender: 'user');
    _controller.clear();

    List<Map<String, dynamic>> messages = [
      {
        'role': 'user',
        'content': userMessage,
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
        String botResponse = responseData["result"]["response"] ?? "";
        print(botResponse);
        _addMessage(botResponse, sender: 'bot');

        setState(() {
          isLoading = false;
        });
      } else {
        print("API Error: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: MyAppBar(),
        backgroundColor: Colors.grey[900],
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: PromptBox(),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(
                    bottom: 13.h, right: 5.w, left: 5.w, top: 1.h),
                shrinkWrap: true,
                reverse: true,
                itemCount: _messages.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (isLoading && index == 0) {
                    return loadingButton();
                  }
                  return _buildMessage(
                      _messages[_messages.length -
                          1 -
                          (isLoading ? index - 1 : index)],
                      index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message, int index) {
    final isMe = message['sender'] == 'user';
    final messageAlign =
        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final messageColor =
        isMe ? globalController.primaryColor.value : Colors.grey[300];

    return Column(
      crossAxisAlignment: messageAlign,
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 13.sp),
          padding: EdgeInsets.symmetric(vertical: 10.sp, horizontal: 13.sp),
          decoration: BoxDecoration(
            color: messageColor,
            borderRadius: BorderRadius.circular(13.sp),
          ),
          child: Text(
            message['content'] as String,
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Row loadingButton() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 3; i++)
          AnimatedContainer(
            duration: Duration(microseconds: 1),
            margin: EdgeInsets.symmetric(horizontal: 2),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColorIndex == i
                  ? Colors.white
                  : const Color.fromARGB(255, 169, 169, 169),
            ),
          ),
      ],
    );
  }

  Widget PromptBox() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.sp, vertical: 10.sp),
      margin: EdgeInsets.only(bottom: 2.h),
      width: 90.w,
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 48, 48, 48),
        borderRadius: BorderRadius.circular(20.sp),
      ),
      child: Row(
        children: [
          Expanded(child: Textfield()),
        ],
      ),
    );
  }

  Widget Textfield() {
    return TextField(
      textAlignVertical: TextAlignVertical.center,
      onSubmitted: (value) {
        _getResponse();
      },
      controller: _controller,
      style: GoogleFonts.poppins(
          color: const Color.fromARGB(255, 255, 255, 255),
          fontSize: 16.sp,
          fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 15.sp, vertical: 0),
        hintText: 'Enter your prompt...',
        hintStyle: GoogleFonts.poppins(
            color: const Color.fromARGB(255, 255, 255, 255),
            fontSize: 16.sp,
            fontWeight: FontWeight.w500),
        border: InputBorder.none,
        suffixIcon: InkWell(
          onTap: () {
            _getResponse();
          },
          child: Container(
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: Colors.grey[900]),
            child: Icon(
              Icons.send,
              size: 22.sp,
              color: globalController.primaryColor.value,
            ),
          ),
        ),
      ),
    );
  }
}
