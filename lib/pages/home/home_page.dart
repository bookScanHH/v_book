import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VBookScan'), centerTitle: true),
      body: Obx(() {
        switch (controller.currentIndex.value) {
          case 0:
            return _buildDocumentsTab();
          case 1:
            return _buildScanTab();
          case 2:
            return _buildSettingsTab();
          default:
            return _buildDocumentsTab();
        }
      }),
      bottomNavigationBar: Obx(
            () => BottomNavigationBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changePage,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.folder), label: '文档'),
            BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: '扫描'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
          ],
        ),
      ),
      floatingActionButton: Obx(() {
        // 只在文档页面显示添加按钮
        return controller.currentIndex.value == 0
            ? FloatingActionButton(
          onPressed: () => Get.toNamed('/scan'),
          child: const Icon(Icons.add),
        )
            : const SizedBox.shrink();
      }),
    );
  }

  Widget _buildDocumentsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            '暂无文档',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/scan'),
            icon: const Icon(Icons.camera_alt),
            label: const Text('开始扫描'),
          ),
        ],
      ),
    );
  }

  Widget _buildScanTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            '点击下方按钮开始扫描',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/scan'),
            icon: const Icon(Icons.camera_alt),
            label: const Text('开始扫描'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ListTile(
          leading: Icon(Icons.image_search),
          title: Text('OCR设置'),
          subtitle: Text('配置文字识别参数'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.color_lens),
          title: Text('主题设置'),
          subtitle: Text('自定义应用外观'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.storage),
          title: Text('存储管理'),
          subtitle: Text('管理文档存储位置'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.cloud_upload),
          title: Text('云同步'),
          subtitle: Text('配置云存储服务'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.info),
          title: Text('关于'),
          subtitle: Text('应用信息与帮助'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ],
    );
  }
}
