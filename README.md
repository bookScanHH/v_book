# v_book

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter Scan application.

## 项目目录结构
```
├── android/                 # Android平台相关代码
├── ios/                     # iOS平台相关代码
├── lib/                     # 主要的Dart代码
│   ├── app/                 # 应用核心
│   │   ├── bindings/        # 全局依赖注入绑定
│   │   ├── data/            # 数据层
│   │   │   ├── models/      # 数据模型
│   │   │   ├── providers/   # 数据提供者(API、本地存储等)
│   │   │   └── repositories/# 数据仓库
│   │   ├── modules/         # 功能模块
│   │   │   ├── home/        # 首页模块
│   │   │   │   ├── bindings/# 首页绑定
│   │   │   │   ├── controllers/# 首页控制器
│   │   │   │   └── views/   # 首页视图
│   │   │   ├── scan/        # 扫描模块
│   │   │   ├── library/     # 文档库模块
│   │   │   ├── edit/        # 编辑模块
│   │   │   ├── ocr_result/  # OCR结果模块
│   │   │   └── profile/     # 个人中心模块
│   │   ├── routes/          # 路由管理
│   │   │   ├── app_pages.dart
│   │   │   └── app_routes.dart
│   │   ├── theme/           # 主题配置
│   │   │   └── app_theme.dart
│   │   └── utils/           # 工具类
│   │       ├── constants.dart
│   │       ├── helpers.dart
│   │       └── extensions.dart
│   ├── core/                # 核心功能
│   │   ├── camera/          # 相机相关
│   │   ├── ocr/             # OCR相关
│   │   ├── document_detection/# 文档检测
│   │   ├── image_processing/ # 图像处理
│   │   └── storage/         # 存储管理
│   ├── services/            # 全局服务
│   │   ├── camera_service.dart
│   │   ├── ocr_service.dart
│   │   ├── storage_service.dart
│   │   └── permission_service.dart
│   ├── widgets/             # 可复用组件
│   │   ├── document_card.dart
│   │   ├── scan_button.dart
│   │   ├── filter_option.dart
│   │   └── custom_bottom_nav.dart
│   └── main.dart            # 应用入口
├── assets/                  # 静态资源
│   ├── images/              # 图片资源
│   ├── icons/               # 图标资源
│   └── fonts/               # 字体资源
├── test/                    # 测试代码
├── pubspec.yaml             # 依赖配置
└── README.md                # 项目说明
```


## 主要功能

- 文档扫描与边缘检测
- OCR文字识别
- 文档编辑与增强
- 文本朗读
- 文档管理与分类
- 云端备份与同步
- 多种导出格式支持

## 技术栈

- Flutter框架
- GetX状态管理
- 相机与图像处理
- OCR文字识别
- 本地存储与云存储

## 开发环境设置

1. 确保已安装Flutter SDK
2. 克隆项目到本地
3. 运行 `flutter pub get` 安装依赖
4. 运行 `flutter run` 启动应用

## 贡献指南

欢迎提交Pull Request或Issue来帮助改进项目。

## 许可证

[MIT License](LICENSE)
