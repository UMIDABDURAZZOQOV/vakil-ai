import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../localization/app_locale.dart';
import '../localization/app_strings.dart';

final localeProvider = StateProvider<AppLocale>((ref) => AppLocale.uz);

/// Shorthand translator bound to the currently selected locale.
/// Usage inside a ConsumerWidget: `ref.tr('settings')`.
extension TranslateRef on WidgetRef {
  String tr(String key) => AppStrings.t(watch(localeProvider), key);
}
