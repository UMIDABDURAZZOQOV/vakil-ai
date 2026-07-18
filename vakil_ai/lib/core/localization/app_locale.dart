enum AppLocale { uz, ru, en }

extension AppLocaleCode on AppLocale {
  String get code {
    switch (this) {
      case AppLocale.uz:
        return 'UZ';
      case AppLocale.ru:
        return 'RU';
      case AppLocale.en:
        return 'EN';
    }
  }
}
