import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learnai/In%20App%20Purchase/PurchaseApi.dart';
import 'package:learnai/main.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class Subscription extends StatefulWidget {
  const Subscription({super.key});

  @override
  State<Subscription> createState() => _SubscriptionState();
}

class _SubscriptionState extends State<Subscription> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: Container(
        height: 100.h,
        width: 100.w,
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/gg.png'), fit: BoxFit.cover)),
        child: Padding(
          padding: EdgeInsets.all(17.sp),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                InkWell(
                  onTap: () async {
                    Get.back();
                  },
                  child: Container(
                      color: Colors.white,
                      child: Icon(
                        Icons.arrow_back,
                        color: globalController.primaryColor.value,
                        size: 23.sp,
                      )),
                ),
              ],
            ),
            SizedBox(height: 17.h),
            InkWell(
              onTap: () {
                premiumPurchase();
              },
              child: PlanCard(
                title: 'Subscription Plan',
                price: '5\$ /- per month',
                features: [
                  'Pop Quiz of last topic you studied',
                  'Unlimited document scans',
                  'Interesting facts',
                  'AI tutor for advanced training',
                ],
                backgroundColor: globalController.primaryColor.value,
                textColor: Colors.black,
              ),
            ),
            SizedBox(height: 2.h),
            PlanCard(
              title: 'Free Plan',
              price: '\$00.00/- per month',
              features: [
                'All subjects and topics regarding school educational plan',
                'Limited document scans',
                'Progress tracking',
                'Online connectivity',
              ],
              backgroundColor:
                  globalController.primaryColor.value.withOpacity(0.2),
              textColor: Colors.black,
              icon: Icons.check_circle,
            ),
          ]),
        ),
      )),
    );
  }

  premiumPurchase() async {
    final offerings = await PurchaseApi.fetchOffers();
    if (offerings.isEmpty) {
      print('No Plans Found');
    } else {
      final packages = offerings;
      bool check = false;
      await PurchaseApi.purchasePackage(packages[0]);
    }
  }
}

class PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final List<String> features;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  const PlanCard({
    Key? key,
    required this.title,
    required this.price,
    required this.features,
    required this.backgroundColor,
    required this.textColor,
    this.icon = Icons.check,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 19.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            price,
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              color: textColor,
            ),
          ),
          SizedBox(height: 1.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: features.map((feature) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(icon, color: textColor, size: 20),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        feature,
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
