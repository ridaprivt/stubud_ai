import 'package:flutter/widgets.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class Spaces {
  static SizedBox height(double value) {
    return SizedBox(height: value.h);
  }

  static SizedBox width(double value) {
    return SizedBox(width: value.w);
  }
}
