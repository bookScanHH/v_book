import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ScanController extends GetxController {
  late List<CameraDescription> cameras;
  late CameraController cameraController;

  final RxBool isInitialized = false.obs;
  final RxBool isCapturing = false.obs;
  final RxBool isFlashOn = false.obs;
  final RxBool isGridOn = false.obs;
  final RxInt currentCamera = 0.obs; // 0: 后置, 1: 前置
  final Rx<File?> capturedImage = Rx<File?>(null);

  // 新增控制变量
  final RxBool isTimerEnabled = false.obs;
  final RxInt timerDuration = 3.obs; // 默认3秒延时
  final RxBool isAutoScanEnabled = false.obs;
  final RxBool isMoreFeaturesOpen = false.obs;

  // 页面选择相关
  final RxInt selectedPage = 1.obs; // 1: 第一页, 2: 第二页
  final RxBool isAutoDetectEnabled = true.obs; // 默认开启自动检测

  // 图像处理相关功能
  final RxBool isColorCorrectionEnabled = false.obs; // 色彩校正
  final RxBool isFingerRemovalEnabled = false.obs; // 删除手指
  final RxBool isStraightenEnabled = false.obs; // 拉直功能

  // 添加新的控制变量
  final RxList<List<Map<String, double>>> handLandmarks =
      RxList<List<Map<String, double>>>([]);

  // 文档检测相关变量
  final RxList<math.Point<int>> documentCorners = RxList<math.Point<int>>([]);
  final targetRect = Rx<Rect?>(null);
  final zoomLevel = 1.0.obs;
  final RxBool isDocumentDetected = false.obs;
  final RxBool isProcessingFrame = false.obs;

  // 帧处理计时器
  Timer? _frameProcessTimer;

  // ML Kit检测器
  late final TextRecognizer _textRecognizer;
  late final ObjectDetector _objectDetector;

  @override
  void onInit() async {
    super.onInit();

    // 初始化ML Kit检测器
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);

    final modelPath = await getModelPath('assets/ml/yolo11n_float32.tflite');
    // 使用预构建的对象检测器
    final options = ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: true,
      // modelPath: modelPath, // 自定义模型路径
    );

    _objectDetector = ObjectDetector(options: options);

    print('ScanController: 准备初始化相机');
    initCamera();
  }

  Future<String> getModelPath(String asset) async {
    final path = '${(await getApplicationSupportDirectory()).path}/$asset';
    await Directory(dirname(path)).create(recursive: true);
    final file = File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(asset);
      await file.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );
    }
    return file.path;
  }

  @override
  void onClose() {
    _frameProcessTimer?.cancel();
    cameraController.dispose();
    _textRecognizer.close();
    _objectDetector.close();
    super.onClose();
  }

  Future<void> initCamera() async {
    try {
      print('ScanController: 开始初始化相机...');
      // 先请求相机权限
      var status = await Permission.camera.request();
      print('ScanController: 相机权限状态: $status');
      if (!status.isGranted) {
        Get.snackbar(
          '错误',
          '需要相机权限来使用扫描功能',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      cameras = await availableCameras();

      cameraController = CameraController(
        cameras[currentCamera.value],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      print('ScanController: 正在初始化相机控制器...');
      await cameraController.initialize();
      print('ScanController: 相机控制器初始化完成！');

      // 启动文档检测流
      if (isAutoDetectEnabled.value) {
        print('ScanController: 启动文档检测...');
        startDocumentDetection();
      }

      isInitialized.value = true;
      print('ScanController: 初始化完成，isInitialized = ${isInitialized.value}');
      update(); // 调用update()通知UI更新
    } catch (e) {
      print('ScanController: 相机初始化失败: $e');
      Get.snackbar(
        '错误',
        '相机初始化失败: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void startDocumentDetection() {
    // 设置定时器来定期处理帧，以便检测文档
    _frameProcessTimer = Timer.periodic(const Duration(milliseconds: 2000), (
      _,
    ) {
      if (isInitialized.value &&
          !isCapturing.value &&
          !isProcessingFrame.value) {
        processLatestFrame();
      }
    });
  }

  void stopDocumentDetection() {
    _frameProcessTimer?.cancel();
    _frameProcessTimer = null;
    isDocumentDetected.value = false;
    documentCorners.clear();
  }

  Future<void> processLatestFrame() async {
    if (!isInitialized.value || isCapturing.value || isProcessingFrame.value) {
      print(
        'ScanController: 跳过帧处理，isInitialized=${isInitialized.value}, isCapturing=${isCapturing.value}, isProcessingFrame=${isProcessingFrame.value}',
      );
      return;
    }

    isProcessingFrame.value = true;
    print('ScanController: 开始处理帧...');

    try {
      // 捕获当前帧
      final XFile photo = await cameraController.takePicture();
      print('ScanController: 捕获帧到: ${photo.path}');

      // 使用ML Kit检测文档边缘
      final corners = await detectDocumentWithMlKit(photo.path);

      // final corners = await DocumentScanner().getScannedDocumentAsImages(photo.path);
      // print('ScanController: 检测结果角点数量: ${corners.length}');

      // 更新UI显示检测结果
      if (corners.isNotEmpty) {
        // 输出检测到的原始点坐标信息
        print('ScanController: 检测到文档，原始坐标: $corners');

        // 获取图像尺寸并将坐标映射到屏幕上
        final imageSize = await getImageSize(photo.path);
        if (imageSize != null) {
          print(
            'ScanController: 获取到的图像尺寸: ${imageSize.width}x${imageSize.height}',
          );

          // 获取屏幕尺寸 - 相机预览区域高度为屏幕高度的60%
          final screenWidth = Get.width;
          final screenHeight = Get.height * 0.6;

          // 计算图像坐标到屏幕坐标的映射比例
          final ratioX = screenWidth / imageSize.width;
          final ratioY = screenHeight / imageSize.height;

          // 将图像坐标映射到屏幕坐标
          final adjustedCorners =
              corners.map((point) {
                int x = (point.x * ratioX).round();
                int y = (point.y * ratioY).round();

                // 确保坐标在屏幕范围内
                x = math.max(0, math.min(x, screenWidth.toInt()));
                y = math.max(0, math.min(y, screenHeight.toInt()));

                return math.Point<int>(x, y);
              }).toList();

          final newCorners = List<math.Point<int>>.from(adjustedCorners);

          // 更新文档角点和检测状态
          documentCorners.assignAll(newCorners);
          isDocumentDetected.value = true;
          print('ScanController: 文档检测成功，更新UI');
          // 删除临时文件
          // await File(photo.path).delete();
          update(); // 通知UI更新
        } else {
          print('ScanController: 无法获取图像尺寸');
          isDocumentDetected.value = false;
          documentCorners.clear();
          // 删除临时文件
          // await File(photo.path).delete();
          update(); // 通知UI更新
        }
      } else {
        // 确保设为false触发变化
        isDocumentDetected.value = false;
        documentCorners.clear();
        print('ScanController: 未检测到文档');
        update(); // 通知UI更新
      }

      // // 删除临时文件
      // await File(photo.path).delete();
    } catch (e) {
      print('ScanController: 处理帧时出错: $e');
      // 只在状态变化时显示错误
      if (isDocumentDetected.value) {
        showToast("检测出错，请重试");
      }
      documentCorners.clear();
      isDocumentDetected.value = false;
      update(); // 通知UI更新
    } finally {
      isProcessingFrame.value = false;
    }
  }

  void _adjustZoom(double width, double height) {
    // 根据物体在画面中的比例计算zoom值
    // final screenRatio = width * height / (MediaQuery.of(context).size.width * MediaQuery.of(context).size.height);
    // _zoomLevel = 1.0 + (1.0 - screenRatio).clamp(0.0, 0.5);
    cameraController.setZoomLevel(zoomLevel.value);
  }

  Future<List<math.Point<int>>> detectDocumentWithMlKit(
    String imagePath,
  ) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);

      // 使用文本识别器检测文本块
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // 尝试使用对象检测器检测文档
      final detectedObjects = await _objectDetector.processImage(inputImage);

      // 综合文本块和对象检测的结果来确定文档边缘
      return determineDocumentCorners(
        imagePath,
        recognizedText,
        detectedObjects,
      );
    } catch (e) {
      print('ML Kit文档检测失败: $e');

      // 如果ML Kit检测失败，使用备选方案
      return await fallbackDocumentDetection(imagePath);
    }
  }

  Future<List<math.Point<int>>> determineDocumentCorners(
    String imagePath,
    RecognizedText recognizedText,
    List<DetectedObject> detectedObjects,
  ) async {
    try {
      // 读取图像获取尺寸
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) return [];

      final imageWidth = image.width;
      final imageHeight = image.height;

      // if (detectedObjects.isNotEmpty) {
      //   final target = detectedObjects.first;
      //   final boundingBox = target.boundingBox;
      //   targetRect.value = boundingBox;
      //   return [
      //     math.Point<int>(boundingBox.left.toInt(), boundingBox.top.toInt()),
      //     math.Point<int>(boundingBox.right.toInt(), boundingBox.top.toInt()),
      //     math.Point<int>(
      //       boundingBox.right.toInt(),
      //       boundingBox.bottom.toInt(),
      //     ),
      //     math.Point<int>(boundingBox.left.toInt(), boundingBox.bottom.toInt()),
      //   ];
      // }

      // // 尝试从对象检测结果中找到文档
      // for (final object in detectedObjects) {
      //   // 检查对象是否可能是文档或卡片
      //   final boundingBox = object.boundingBox;
      //   final ratio = boundingBox.width / boundingBox.height;
      //
      //   final target = detectedObjects.first;
      //
      //   // 文档通常有特定的宽高比范围(A4, ID卡等)
      //   if ((ratio > 0.6 && ratio < 1.8) &&
      //       (boundingBox.width > imageWidth * 0.3) &&
      //       (boundingBox.height > imageHeight * 0.3)) {
      //     // 计算矩形的四个角点
      //     return [
      //       math.Point<int>(boundingBox.left.toInt(), boundingBox.top.toInt()),
      //       math.Point<int>(boundingBox.right.toInt(), boundingBox.top.toInt()),
      //       math.Point<int>(
      //         boundingBox.right.toInt(),
      //         boundingBox.bottom.toInt(),
      //       ),
      //       math.Point<int>(
      //         boundingBox.left.toInt(),
      //         boundingBox.bottom.toInt(),
      //       ),
      //     ];
      //   }
      // }
      //
      // 如果没有找到合适的对象，尝试使用文本块来确定文档边界
      if (recognizedText.blocks.isNotEmpty) {
        // 获取所有文本块的边界框
        List<Rect> textBoxes =
            recognizedText.blocks.map((block) => block.boundingBox).toList();

        // 找出最外层的边界，形成文档的轮廓
        double minX = double.infinity;
        double minY = double.infinity;
        double maxX = 0;
        double maxY = 0;

        for (final box in textBoxes) {
          if (box.left < minX) minX = box.left;
          if (box.top < minY) minY = box.top;
          if (box.right > maxX) maxX = box.right;
          if (box.bottom > maxY) maxY = box.bottom;
        }

        // 稍微扩大边界，更接近文档实际大小
        final expandX = (maxX - minX) * 0.05;
        final expandY = (maxY - minY) * 0.05;

        minX = math.max(0, minX - expandX);
        minY = math.max(0, minY - expandY);
        maxX = math.min(imageWidth.toDouble(), maxX + expandX);
        maxY = math.min(imageHeight.toDouble(), maxY + expandY);

        // 将文本块的外部边界作为文档边界
        return [
          math.Point<int>(minX.toInt(), minY.toInt()),
          math.Point<int>(maxX.toInt(), minY.toInt()),
          math.Point<int>(maxX.toInt(), maxY.toInt()),
          math.Point<int>(minX.toInt(), maxY.toInt()),
        ];
      }

      // 如果所有方法都失败，使用备选方案
      return await fallbackDocumentDetection(imagePath);
    } catch (e) {
      print('确定文档角点失败: $e');
      return await fallbackDocumentDetection(imagePath);
    }
  }

  Future<List<math.Point<int>>> fallbackDocumentDetection(
    String imagePath,
  ) async {
    return [];
  }

  void toggleFlash() {
    isFlashOn.value = !isFlashOn.value;
    cameraController.setFlashMode(
      isFlashOn.value ? FlashMode.torch : FlashMode.off,
    );
  }

  void toggleGrid() {
    isGridOn.value = !isGridOn.value;
  }

  // 获取设备方向
  DeviceOrientation _getDeviceOrientation() {
    // 从设备方向获取当前方向
    final currentOrientation =
        MediaQueryData.fromView(WidgetsBinding.instance.window).orientation;

    if (currentOrientation == Orientation.portrait) {
      return DeviceOrientation.portraitUp;
    } else {
      // 横屏时，根据加速度计确定具体横屏方向
      // 简化实现，默认为左横屏
      return DeviceOrientation.landscapeLeft;
    }
  }

  Future<void> takePicture() async {
    if (!cameraController.value.isInitialized) {
      return;
    }

    isCapturing.value = true;

    try {
      final XFile photo = await cameraController.takePicture();
      capturedImage.value = File(photo.path);
      Get.toNamed('/document_edit', arguments: {'image_path': photo.path});
    } catch (e) {
      Get.snackbar(
        '错误',
        '拍照失败: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isCapturing.value = false;
    }
  }

  Future<void> pickImageFromGallery() async {
    // 从相册选择图片的功能
    try {
      // 请求存储权限
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        Get.snackbar(
          '错误',
          '需要存储权限来访问相册',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // 这里将实现从相册选择图片的功能
      // 暂时显示提示信息
      Get.snackbar(
        '提示',
        '相册功能即将上线',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        '错误',
        '选择图片失败: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // 切换页面选择
  void selectPage(int page) {
    selectedPage.value = page;
  }

  // 切换自动检测
  void toggleAutoDetect() {
    isAutoDetectEnabled.value = !isAutoDetectEnabled.value;
    if (isAutoDetectEnabled.value) {
      Get.snackbar(
        '提示',
        '自动检测已启用',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      startDocumentDetection();
    } else {
      Get.snackbar(
        '提示',
        '自动检测已关闭',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.grey,
        colorText: Colors.white,
      );
      stopDocumentDetection();
    }
  }

  void toggleTimer() {
    isTimerEnabled.value = !isTimerEnabled.value;
    if (isTimerEnabled.value) {
      Get.snackbar(
        '提示',
        '延时拍摄已启用: ${timerDuration.value}秒',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    }
  }

  // 切换自动扫描
  void toggleAutoScan() {
    isAutoScanEnabled.value = !isAutoScanEnabled.value;
    if (isAutoScanEnabled.value) {
      Get.snackbar(
        '提示',
        '自动扫描已启用',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    }
  }

  // 切换更多功能面板
  void toggleMoreFeatures() {
    isMoreFeaturesOpen.value = !isMoreFeaturesOpen.value;
  }

  // 切换色彩校正
  void toggleColorCorrection() {
    isColorCorrectionEnabled.value = !isColorCorrectionEnabled.value;
    Get.snackbar(
      '提示',
      isColorCorrectionEnabled.value ? '色彩校正已启用' : '色彩校正已关闭',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  // 切换删除手指
  void toggleFingerRemoval() {
    isFingerRemovalEnabled.value = !isFingerRemovalEnabled.value;
    Get.snackbar(
      '提示',
      isFingerRemovalEnabled.value ? '删除手指功能已启用' : '删除手指功能已关闭',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  // 切换拉直功能
  void toggleStraighten() {
    isStraightenEnabled.value = !isStraightenEnabled.value;
    Get.snackbar(
      '提示',
      isStraightenEnabled.value ? '拉直功能已启用' : '拉直功能已关闭',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  // 显示临时Toast提示
  void showToast(String message) {
    Get.snackbar(
      '', // 空标题
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.black.withOpacity(0.7),
      colorText: Colors.white,
      margin: const EdgeInsets.only(top: 10, left: 50, right: 50),
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      duration: const Duration(milliseconds: 1000), // 持续1秒
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutQuint,
      reverseAnimationCurve: Curves.easeInQuint,
      barBlur: 7.0,
    );
  }

  // 获取图像尺寸的辅助方法
  Future<Size?> getImageSize(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image != null) {
        // 返回实际的图像尺寸
        return Size(image.width.toDouble(), image.height.toDouble());
      }
      return null;
    } catch (e) {
      print('获取图像尺寸失败: $e');
      return null;
    }
  }
}
