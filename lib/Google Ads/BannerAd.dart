import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class AdsServices {
  InterstitialAd? interstitialAd;
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-2847115867110365/9210603894'
      : 'ca-app-pub-5003568726507075/2606739586';

  init() async {
    await MobileAds.instance.initialize();
    await loadAd();
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (interstitialAd != null) {
        interstitialAd!.show();
      } else {
        await loadAd();
      }
    });
  }

  Future<void> loadAd() async {
    InterstitialAd.load(
      adUnitId: _adUnitId,
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

  Future<Widget> getBannerWidget(BuildContext context, AdSize adSize) async {
    BannerAd? bannerAd;
    bannerAd = BannerAd(
        listener: BannerAdListener(
            onAdLoaded: (Ad ad) {},
            onAdFailedToLoad: (Ad ad, LoadAdError error) {
              try {
                bannerAd!.dispose();
              } catch (_) {}
            },
            onAdOpened: (Ad ad) {},
            onAdClosed: (Ad ad) {
              try {
                bannerAd!.dispose();
              } catch (_) {}
            }),
        size: adSize,
        adUnitId: _adUnitId,
        request: AdRequest());
    try {
      await bannerAd.load();
    } catch (_) {
      return const Center(child: Text("Failed to Load Ad"));
    }
    return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(child: AdWidget(ad: bannerAd)));
  }

  FutureBuilder<Widget> MyAd(BuildContext context) {
    return FutureBuilder<Widget>(
        future: AdsServices().getBannerWidget(context, AdSize.banner),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return Text(
              "Loading Ad...",
              style: GoogleFonts.poppins(color: Colors.red),
            );
          } else {
            return SizedBox(height: 7.h, child: snapshot.data);
          }
        });
  }

  void disposeAds() {
    interstitialAd?.dispose();
  }
}
