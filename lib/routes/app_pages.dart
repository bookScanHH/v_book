import 'package:get/get.dart';

import '../pages/home/home_binding.dart';
import '../pages/home/home_page.dart';

import '../pages/scan/scan_binding.dart';
import '../pages/scan/scan_page.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SCAN;

  static final routes = [
    GetPage(name: Routes.HOME, page: () => HomePage(), binding: HomeBinding()),
    GetPage(name: Routes.SCAN, page: () => ScanPage(), binding: ScanBinding()),
  ];
}
