import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:learnai/Google%20Ads/BannerAd.dart';
import 'package:learnai/Google%20Ads/InterstitialAd.dart';
import 'package:learnai/UI/ai_tutor/AiTutor.dart';
import 'package:learnai/UI/chat_screen/Chat.dart';
import 'package:learnai/UI/subject/Subject.dart';
import 'package:learnai/Widgets/AppBar.dart';
import 'package:learnai/Widgets/InterestingFactCard.dart';
import 'package:learnai/main.dart';
import 'package:learnai/res/assets/Images.dart';
import 'package:learnai/res/colors/Colors.dart';
import 'package:learnai/res/methods/HomeMethods.dart';
import 'package:learnai/res/spaces/Spaces.dart';
import 'package:learnai/res/styles/TextStyles.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool fact = false;
  String result = '';
  Map<String, String> subjectFacts = {};
  List<String> mysubjects = [];
  PageController _pageController = PageController();
  bool load = false;
  bool subscription = true;

  @override
  void initState() {
    super.initState();
    HomeMethods.initializeData(setSubscription);
    HomeMethods.loadCachedFacts(setState, mysubjects, subjectFacts, setLoad);
  }

  @override
  void dispose() {
    super.dispose();
    if (!subscription) {
      AdsServices().disposeAds();
      GoogleAds().dispose();
    }
  }

  void setSubscription(bool value) {
    setState(() {
      subscription = value;
    });
  }

  void setLoad(bool value) {
    setState(() {
      load = value;
    });
  }

  void setFact(bool value) {
    setState(() {
      fact = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: MyAppBar(),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Spaces.height(2),
              if (!subscription)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.sp),
                  child: Column(
                    children: [
                      AdsServices().MyAd(context),
                      Spaces.height(3),
                    ],
                  ),
                ),
              Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(19.sp),
                    margin: EdgeInsets.symmetric(horizontal: 15.sp),
                    height: 20.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.sp),
                        color: AppColors.primary),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Spacer(),
                        Text(
                          'Bring School\nto One Screen',
                          style: TextStyles.header1(AppColors.white),
                        ),
                        Spaces.height(1),
                        Text(
                          'Why buy loads of stationary\nand books when you have Stubud AI',
                          style: TextStyles.subtitle(AppColors.white),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.sp),
                      child: Image.asset(
                        AppImages.bag,
                        width: 58.w,
                      ),
                    ),
                  )
                ],
              ),
              Spaces.height(2),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 17.sp),
                child: Text(
                  'Subject Trouble?',
                  style: TextStyles.header2(AppColors.black),
                ),
              ),
              Spaces.height(2),
              load
                  ? Center(
                      child: SpinKitCircle(
                      size: 35.sp,
                      itemBuilder: (BuildContext context, int index) {
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index.isEven
                                ? globalController.primaryColor.value
                                : AppColors.white,
                          ),
                        );
                      },
                    ))
                  : Container(
                      height: 47.sp,
                      child: ListView.builder(
                        padding: EdgeInsets.only(right: 3.w),
                        scrollDirection: Axis.horizontal,
                        itemCount: mysubjects.length,
                        itemBuilder: (context, index) {
                          return subjectWidget(
                            mysubjects[index],
                          );
                        },
                      ),
                    ),
              Spaces.height(2),
              InkWell(
                onTap: () {
                  Get.to(AiTutor());
                },
                child: Container(
                  padding: EdgeInsets.all(17.sp),
                  margin: EdgeInsets.symmetric(horizontal: 15.sp),
                  width: double.infinity,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17.sp),
                      color: AppColors.black),
                  child: Row(
                    children: [
                      Text(
                        'AI Tutor  ',
                        style: TextStyles.body(
                            AppColors.white, 18, FontWeight.w600),
                      ),
                      Image.asset(
                        AppImages.ai,
                        height: 21.sp,
                      ),
                      Spacer(),
                      Icon(
                        Icons.arrow_forward,
                        color: AppColors.white,
                      )
                    ],
                  ),
                ),
              ),
              Spaces.height(2),
              Container(
                height: 23.h,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: mysubjects.length,
                  itemBuilder: (context, index) {
                    final subject = mysubjects[index];
                    final factText = subjectFacts[subject] ?? 'Loading...';
                    return InterestingFactCard(
                      subject: subject,
                      factText: factText,
                      fact: fact,
                    );
                  },
                ),
              ),
              Spaces.height(1),
              load
                  ? Container()
                  : Center(
                      child: SmoothPageIndicator(
                        controller: _pageController,
                        count: mysubjects.length,
                        effect: WormEffect(
                          dotHeight: 10.sp,
                          dotWidth: 10.sp,
                          spacing: 16.sp,
                          dotColor: AppColors.grey,
                          activeDotColor: AppColors.black,
                        ),
                      ),
                    ),
              Spaces.height(2),
              InkWell(
                onTap: () {
                  Get.to(ChatPage());
                },
                child: Container(
                  padding: EdgeInsets.all(19.sp),
                  margin: EdgeInsets.symmetric(horizontal: 15.sp),
                  width: double.infinity,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.sp),
                      color: globalController.primaryColor.value),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What’s bothering you?',
                        style: TextStyles.body(
                            AppColors.black, 18, FontWeight.w600),
                      ),
                      Spaces.height(2),
                      Row(
                        children: [
                          Image.asset(
                            AppImages.search,
                            height: 5.h,
                          ),
                          Spaces.width(2),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 15.sp, vertical: 12.sp),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20.sp),
                                  border: Border.all(
                                      color: AppColors.black, width: 5.sp)),
                              child: InkWell(
                                onTap: () {
                                  Get.to(ChatPage());
                                },
                                child: Text(
                                  'Enter your prompt...',
                                  style: TextStyles.body(
                                      AppColors.black, 15.5, FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              Spaces.height(2),
            ],
          ),
        ),
      ),
    );
  }

  subjectWidget(String name) {
    return InkWell(
      onTap: () {
        Get.to(() => Subject(subjectName: name));
      },
      child: Container(
        padding: EdgeInsets.all(10.sp),
        margin: EdgeInsets.only(left: 15.sp),
        width: 47.sp,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey, width: 3.sp),
          borderRadius: BorderRadius.circular(20.sp),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppImages.sub,
              width: 37.sp,
              height: 37.sp,
            ),
            Text(
              name,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.body(AppColors.black, 15, FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
