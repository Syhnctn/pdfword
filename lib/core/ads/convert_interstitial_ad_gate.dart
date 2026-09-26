import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ConvertInterstitialAdGate {
  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  bool _isShowing = false;

  String get _adUnitId {
    if (kDebugMode) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? 'ca-app-pub-3940256099942544/4411468910'
          : 'ca-app-pub-3940256099942544/1033173712';
    }

    return defaultTargetPlatform == TargetPlatform.iOS
        ? 'ca-app-pub-3940256099942544/4411468910'
        : 'ca-app-pub-9839321331786355/9998668423';
  }

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  void preload() {
    if (!_isSupportedPlatform || _isLoading || _interstitialAd != null) return;

    _isLoading = true;
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(
        keywords: <String>['pdf', 'document', 'converter'],
      ),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _interstitialAd?.dispose();
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (_) {
          _isLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<void> showThenRun(Future<void> Function() action) async {
    if (!_isSupportedPlatform) {
      await action();
      return;
    }

    if (_isShowing) return;

    final ad = _interstitialAd;
    if (ad == null) {
      preload();
      await action();
      return;
    }

    _interstitialAd = null;
    _isShowing = true;

    final completer = Completer<void>();
    var actionStarted = false;

    Future<void> runActionOnce() async {
      if (actionStarted) return;
      actionStarted = true;
      try {
        await action();
      } finally {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowing = false;
        preload();
        unawaited(runActionOnce());
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _isShowing = false;
        preload();
        unawaited(runActionOnce());
      },
    );

    try {
      ad.show();
    } catch (_) {
      ad.dispose();
      _isShowing = false;
      preload();
      await runActionOnce();
    }

    await completer.future;
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
