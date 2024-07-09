// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class CustomColumnWidget extends StatefulWidget {
  final String heading;
  final List<String> items;
  final String hintText;
  final TextEditingController textEditingController;

  CustomColumnWidget({
    required this.heading,
    required this.items,
    required this.hintText,
    required this.textEditingController,
  });

  @override
  _CustomColumnWidgetState createState() => _CustomColumnWidgetState();
}

class _CustomColumnWidgetState extends State<CustomColumnWidget> {
  int selectedIndex = -1;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.heading,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 18.sp,
            color: Colors.black,
          ),
        ),
        Wrap(
          children: widget.items
              .map((item) => Padding(
                    padding: EdgeInsets.only(top: 1.h),
                    child: Container(
                      margin: EdgeInsets.all(8.sp),
                      padding: EdgeInsets.symmetric(
                          horizontal: 15.sp, vertical: 12.sp),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey,
                        borderRadius: BorderRadius.circular(20.sp),
                      ),
                      child: Text(
                        item,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 16.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        SizedBox(height: 2.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 65.w,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(20.sp),
              ),
              child: TextField(
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w400,
                  fontSize: 15.sp,
                  color: Colors.black,
                ),
                maxLines: 1,
                controller: widget.textEditingController,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 15.sp, vertical: 13.sp),
                  hintStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w400,
                    fontSize: 15.sp,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            GestureDetector(
              onTap: () {
                String inputText = widget.textEditingController.text
                    .trim(); // Trim the text to remove leading and trailing white spaces
                if (inputText.isNotEmpty) {
                  // Check if the trimmed text is not empty
                  setState(() {
                    widget.items.insert(
                        0, inputText); // Add the trimmed text to the list
                    widget.textEditingController
                        .clear(); // Clear the textEditingController
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.all(11.sp),
                margin: EdgeInsets.only(right: 7.sp),
                decoration: BoxDecoration(
                  color: Colors.blueGrey,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 21.sp,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void swapItems(int i, int j) {
    String temp = widget.items[i];
    widget.items[i] = widget.items[j];
    widget.items[j] = temp;
  }
}
