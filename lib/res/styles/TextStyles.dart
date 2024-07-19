import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class TextStyles {
  static TextStyle header1(Color color) {
    return GoogleFonts.poppins(
      color: color,
      fontWeight: FontWeight.bold,
      fontSize: 20.sp,
    );
  }

  static TextStyle header2(Color color) {
    return GoogleFonts.poppins(
      color: color,
      fontWeight: FontWeight.bold,
      fontSize: 19.sp,
    );
  }

  static TextStyle subtitle(Color color) {
    return GoogleFonts.poppins(
      color: color,
      fontWeight: FontWeight.w500,
      fontSize: 13.sp,
    );
  }

  static TextStyle body(Color color, double fontSize, FontWeight fontWeight) {
    return GoogleFonts.poppins(
      color: color,
      fontSize: fontSize.sp,
      fontWeight: fontWeight,
    );
  }
}
