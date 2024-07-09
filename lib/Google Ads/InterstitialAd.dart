import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class GoogleAds {
  InterstitialAd? interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  final String UnitId = Platform.isAndroid
      ? 'ca-app-pub-2847115867110365/4456421923'
      : 'ca-app-pub-5003568726507075/2606739586';

  void dispose() {
    interstitialAd?.dispose();
  }

  void initialize() async {
    await loadAd();
    Timer.periodic(Duration(seconds: 100), (timer) {
      if (interstitialAd != null) {
        interstitialAd!.show();
      } else {
        loadAd();
      }
    });
  }

  void showInterstitialAd() async {
    Timer.periodic(Duration(seconds: 100), (timer) {
      if (interstitialAd != null) {
        interstitialAd!.show();
      } else {
        loadAd();
      }
    });
  }

  Future<void> loadAd() async {
    InterstitialAd.load(
      adUnitId: UnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {},
            onAdImpression: (ad) {},
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
            },
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdClicked: (ad) {},
          );

          interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('InterstitialAd failed to load: $error');
        },
      ),
    );
  }
}
