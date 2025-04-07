import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'scan_controller.dart';

class ScanPage extends GetView<ScanController> {
  const ScanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false, // 不需要返回按钮
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.folder_outlined),
            const SizedBox(width: 8),
            const Text('库'),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 20),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                // 显示文件夹选择
              },
              child: Row(
                children: const [Text('默认文件夹'), Icon(Icons.arrow_drop_down)],
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {
              // 显示更多选项
            },
          ),
        ],
      ),
      body: Obx(() {
        // 只在初始化之前显示加载
        if (!controller.isInitialized.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // 预计算常用的尺寸参数
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height * 0.6;

        return Stack(
          children: [
            // 相机预览
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: screenHeight,
                child: ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 相机预览
                      Center(
                        child: SizedBox(
                          width: screenWidth,
                          height: screenHeight,
                          child: CameraPreview(controller.cameraController),
                        ),
                      ),

                      // 文档边界绘制层
                      Obx(() {
                        final isVisible = controller.isDocumentDetected.value;
                        final corners = controller.documentCorners.toList();
                        final isBackCamera =
                            controller.currentCamera.value == 0;

                        if (!isVisible ||
                            corners.isEmpty ||
                            corners.length < 4) {
                          return const SizedBox.shrink();
                        }

                        return CustomPaint(
                          key: ValueKey(
                            'bounds_${corners.hashCode}_${DateTime.now().millisecondsSinceEpoch}',
                          ),
                          painter: DocumentBoundsPainter(
                            corners: corners,
                            screenSize: Size(screenWidth, screenHeight),
                            isBackCamera: isBackCamera,
                          ),
                          child: const SizedBox.expand(),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            // 底部控制栏
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Stack(
                        children: [
                          // 缩略图
                          Obx(() {
                            if (controller.capturedImage.value != null) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Image.file(
                                  controller.capturedImage.value!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.teal,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  '1',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 拍照按钮
                    Obx(
                      () => GestureDetector(
                        onTap:
                            controller.isCapturing.value
                                ? null
                                : controller.takePicture,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey, width: 3),
                          ),
                          child:
                              controller.isCapturing.value
                                  ? const CircularProgressIndicator()
                                  : const Icon(Icons.camera_alt, size: 40),
                        ),
                      ),
                    ),

                    // 相册按钮
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: controller.pickImageFromGallery,
                        ),
                        const Text(
                          '相册',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// 文档边界绘制器
class DocumentBoundsPainter extends CustomPainter {
  final List<math.Point<int>> corners;
  final Size screenSize;
  final bool isBackCamera;

  DocumentBoundsPainter({
    required this.corners,
    required this.screenSize,
    required this.isBackCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.isEmpty || corners.length < 4) {
      print('DocumentBoundsPainter: 角点为空或数量不足');
      return;
    }

    print(
      'DocumentBoundsPainter: 绘制边框, 角点数量: ${corners.length}, 角点: ${corners.toString()}',
    );
    print('屏幕尺寸: $screenSize');

    // 画笔设置
    final fillPaint =
        Paint()
          ..color = Colors.blue.withOpacity(0.2)
          ..style = PaintingStyle.fill;

    // 添加边缘羽化效果
    final borderPaint =
        Paint()
          ..color = Colors.blue.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);

    // 坐标映射 - 直接使用坐标，因为getImageSize已经将高度乘以0.6来匹配预览区域
    List<Offset> points =
        corners.map((point) {
          double x = point.x.toDouble();
          double y = point.y.toDouble();

          // 处理前置相机的水平翻转
          if (!isBackCamera) {
            x = screenSize.width - x;
          }

          // 确保坐标限制在预览区域内
          x = math.max(0, math.min(x, screenSize.width));
          y = math.max(0, math.min(y, screenSize.height));

          return Offset(x, y);
        }).toList();

    // 创建路径
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    // 绘制填充
    canvas.drawPath(path, fillPaint);
    // 绘制边缘羽化效果
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(DocumentBoundsPainter oldDelegate) {
    // 确保列表引用或内容变化时都会触发重绘
    if (corners.length != oldDelegate.corners.length) return true;

    for (int i = 0; i < corners.length; i++) {
      if (corners[i].x != oldDelegate.corners[i].x ||
          corners[i].y != oldDelegate.corners[i].y) {
        return true;
      }
    }

    return screenSize != oldDelegate.screenSize;
  }
}
