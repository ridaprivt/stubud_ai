import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class InternetNotAvailable extends StatelessWidget {
  const InternetNotAvailable({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100.w,
      padding: EdgeInsets.symmetric(vertical: 10.sp),
      color: Colors.red,
      child: Center(
        child: Text(
          'No Internet Connection',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14.sp),
        ),
      ),
    );
  }
}
