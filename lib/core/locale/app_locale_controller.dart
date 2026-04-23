import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kalıcı uygulama dili: yalnızca `tr` ve `ru`.
class AppLocaleController extends ChangeNotifier {
  AppLocaleController._();
  static final AppLocaleController instance = AppLocaleController._();

  static const _prefKey = 'app_locale_code_v1';

  Locale _locale = const Locale('tr');
  Locale get locale => _locale;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString(_prefKey);
    _locale = code == 'ru' ? const Locale('ru') : const Locale('tr');
    notifyListeners();
  }

  Future<void> setLocale(Locale value) async {
    final code = value.languageCode;
    if (code != 'tr' && code != 'ru') {
      return;
    }
    _locale = Locale(code);
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefKey, code);
  }
}
