import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends GetxController {
  final RxString currentLanguage = 'zh_CN'.obs;

  @override
  void onInit() {
    super.onInit();
    loadLanguagePreference();
  }

  // 加载保存的语言偏好
  Future<void> loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('language');

    if (savedLanguage != null) {
      currentLanguage.value = savedLanguage;
      updateLocale(savedLanguage);
    }
  }

  // 更新应用语言
  void updateLocale(String languageCode) {
    final locale = _getLocaleFromLanguage(languageCode);
    Get.updateLocale(locale);
    saveLanguagePreference(languageCode);
  }

  // 保存语言偏好
  Future<void> saveLanguagePreference(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    currentLanguage.value = languageCode;
  }

  // 获取语言对应的Locale
  Locale _getLocaleFromLanguage(String languageCode) {
    switch (languageCode) {
      case 'en_US':
        return const Locale('en', 'US');
      case 'zh_CN':
        return const Locale('zh', 'CN');
      default:
        return const Locale('zh', 'CN'); // 默认为简体中文
    }
  }

  // 获取当前语言名称
  String getCurrentLanguageName() {
    switch (currentLanguage.value) {
      case 'en_US':
        return 'English';
      case 'zh_CN':
        return '简体中文';
      default:
        return '简体中文';
    }
  }

  // 获取所有支持的语言
  List<Map<String, String>> get supportedLanguages => [
    {'code': 'zh_CN', 'name': '简体中文'},
    {'code': 'en_US', 'name': 'English'},
  ];
}
