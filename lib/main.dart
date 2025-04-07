import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'routes/app_pages.dart';
import 'theme/app_theme.dart';
import 'utils/translations/app_translations.dart';
import 'utils/translations/language_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化语言控制器
  final languageController = Get.put(LanguageController());
  await languageController.loadLanguagePreference();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'app_name'.tr,
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      defaultTransition: Transition.fade,

      // 国际化配置
      translations: AppTranslations(),
      locale:
      Get.find<LanguageController>().currentLanguage.value == 'zh_CN'
          ? const Locale('zh', 'CN')
          : const Locale('en', 'US'),
      fallbackLocale: const Locale('zh', 'CN'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
    );
  }
}
