import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('tr'),
    Locale('en'),
  ];

  static const _values = <String, Map<String, String>>{
    'en': {
      'appName': 'Only PDF to WORD',
      'authSubtitle':
          'Convert scanned documents into editable text instantly with AI precision.',
      'continueApple': 'Continue with Apple',
      'continueGoogle': 'Continue with Google',
      'startConverting': 'Start Converting',
      'signInEmail': 'Sign in with Email',
      'or': 'or',
      'termsPrefix': 'By continuing, you agree to our',
      'terms': 'Terms of Service',
      'and': 'and',
      'privacy': 'Privacy Policy',
      'converterPro': 'Converter Pro',
      'uploadPdf': 'Upload PDF',
      'uploadHint': 'Tap to browse or drag file here',
      'tapToUploadMock': 'Tap to choose real files',
      'selectedFiles': 'Selected Files',
      'noFilesSelected': 'No files selected yet.',
      'files': 'files',
      'uploading': 'Uploading...',
      'processing': 'Processing...',
      'ready': 'Ready',
      'failed': 'Failed',
      'queued': 'Queued',
      'recentConversions': 'Recent Conversions',
      'viewAll': 'View All',
      'totalSize': 'Total size',
      'estTime': 'Est. time',
      'lessThanFiveSec': '< 5 sec',
      'convertToWord': 'Convert to Word',
      'history': 'History',
      'refresh': 'Refresh',
      'edit': 'Edit',
      'searchConverted': 'Search converted files...',
      'today': 'TODAY',
      'yesterday': 'YESTERDAY',
      'lastWeek': 'LAST WEEK',
      'statusSucceeded': 'Ready',
      'statusProcessing': 'Processing',
      'statusQueued': 'Queued',
      'statusFailed': 'Failed',
      'statusUnknown': 'Unknown',
      'settings': 'Settings',
      'upgradeToPro': 'Upgrade to Pro',
      'comingSoon': 'Coming Soon',
      'account': 'ACCOUNT',
      'subscription': 'Subscription',
      'freePlan': 'Free Plan',
      'restorePurchases': 'Restore Purchases',
      'preferences': 'PREFERENCES',
      'language': 'Language',
      'darkMode': 'Dark Mode',
      'highQuality': 'High Quality Conversion',
      'notifications': 'NOTIFICATIONS',
      'pushNotifications': 'Push Notifications',
      'emailUpdates': 'Email Updates',
      'support': 'SUPPORT',
      'helpCenter': 'Help Center',
      'rateUs': 'Rate Us',
      'privacyPolicy': 'Privacy Policy',
      'logOut': 'Log Out',
      'version': 'Version 1.0.2 (Build 240)',
      'convert': 'Convert',
      'filesTab': 'Files',
      'settingsTab': 'Settings',
      'convertedAgo': 'Converted 2 hours ago',
      'preview': 'Preview',
      'previewLoading': 'Preparing preview...',
      'previewFailed': 'Preview could not be loaded.',
      'previewEmpty': 'No previewable text was found in this document.',
      'previewOpenFailed': 'Could not open the document. Try again.',
      'openInWord': 'Open in Word',
      'retry': 'Try again',
    },
    'tr': {
      'appName': 'Only PDF to WORD',
      'authSubtitle':
          'Taranmis belgeleri yapay zeka ile saniyeler icinde duzenlenebilir metne donusturun.',
      'continueApple': 'Apple ile devam et',
      'continueGoogle': 'Google ile devam et',
      'startConverting': 'Dönüştürmeye Başla',
      'signInEmail': 'E-posta ile giris yap',
      'or': 'veya',
      'termsPrefix': 'Devam ederek sunlari kabul etmis olursun:',
      'terms': 'Kullanim Kosullari',
      'and': 've',
      'privacy': 'Gizlilik Politikasi',
      'converterPro': 'Converter Pro',
      'uploadPdf': 'PDF Yukle',
      'uploadHint': 'Goz atmak icin dokun veya dosyayi buraya surukle',
      'tapToUploadMock': 'Gercek dosya secmek icin dokun',
      'selectedFiles': 'Secilen Dosyalar',
      'noFilesSelected': 'Henuz dosya secilmedi.',
      'files': 'dosya',
      'uploading': 'Yukleniyor...',
      'processing': 'Isleniyor...',
      'ready': 'Hazir',
      'failed': 'Hatali',
      'queued': 'Kuyrukta',
      'recentConversions': 'Son Donusumler',
      'viewAll': 'Tumunu Gor',
      'totalSize': 'Toplam boyut',
      'estTime': 'Tahmini sure',
      'lessThanFiveSec': '< 5 sn',
      'convertToWord': 'Worde Donustur',
      'history': 'Gecmis',
      'refresh': 'Yenile',
      'edit': 'Duzenle',
      'searchConverted': 'Donusen dosyalarda ara...',
      'today': 'BUGUN',
      'yesterday': 'DUN',
      'lastWeek': 'GECEN HAFTA',
      'statusSucceeded': 'Hazir',
      'statusProcessing': 'Isleniyor',
      'statusQueued': 'Kuyrukta',
      'statusFailed': 'Hatali',
      'statusUnknown': 'Bilinmiyor',
      'settings': 'Ayarlar',
      'upgradeToPro': 'Proya Yukselt',
      'comingSoon': 'Yakinda',
      'account': 'HESAP',
      'subscription': 'Abonelik',
      'freePlan': 'Ucretsiz Plan',
      'restorePurchases': 'Satin Alimlari Geri Yukle',
      'preferences': 'TERCIHLER',
      'language': 'Dil',
      'darkMode': 'Karanlik Mod',
      'highQuality': 'Yuksek Kalite Donusum',
      'notifications': 'BILDIRIMLER',
      'pushNotifications': 'Anlik Bildirim',
      'emailUpdates': 'E-posta Guncellemeleri',
      'support': 'DESTEK',
      'helpCenter': 'Yardim Merkezi',
      'rateUs': 'Bizi Degerlendir',
      'privacyPolicy': 'Gizlilik Politikasi',
      'logOut': 'Cikis Yap',
      'version': 'Surum 1.0.2 (Derleme 240)',
      'convert': 'Donustur',
      'filesTab': 'Dosyalar',
      'settingsTab': 'Ayarlar',
      'convertedAgo': '2 saat once donusturuldu',
      'preview': 'Önizleme',
      'previewLoading': 'Önizleme hazırlanıyor...',
      'previewFailed': 'Önizleme yüklenemedi.',
      'previewEmpty': 'Bu belgeda önizlenecek metin bulunamadı.',
      'previewOpenFailed': 'Belge açılamadı. Tekrar deneyin.',
      'openInWord': "Word'de Aç",
      'retry': 'Tekrar dene',
    },
  };

  String text(String key) {
    final lang = locale.languageCode;
    return _values[lang]?[key] ?? _values['en']?[key] ?? key;
  }

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'AppLocalizations not found in context');
    return localizations!;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
