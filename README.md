# Stellar 桌面待办示例

使用 Flutter 3.38 构建的桌面待办示例，演示 **新增/删除/完成**、过滤、状态管理（`Provider`）以及本地 JSON 持久化（`path_provider`）等能力，可用于 macOS / Windows / Linux 桌面端演示。

## 1. 环境准备

1. **安装 Flutter SDK**
   - macOS：`git clone https://github.com/flutter/flutter.git -b stable ~/flutter`
   - 将 `~/flutter/bin` 写入 `PATH`，并为中国大陆网络配置镜像（可写入 `~/.zshrc`）：
     ```bash
     export PUB_HOSTED_URL=https://pub.flutter-io.cn
     export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
     export PATH=$HOME/flutter/bin:$PATH
     ```
   - 验证：`flutter doctor`

2. **桌面依赖**
   - macOS：安装 Xcode、Command Line Tools、CocoaPods `sudo gem install cocoapods`
   - Windows：安装 Visual Studio（含 “Desktop development with C++” 工作负载）
   - Linux：安装 clang、cmake、ninja、gtk3.0-dev（根据发行版选择包管理器）

3. **启用桌面支持**
   ```bash
   flutter config --enable-macos-desktop --enable-windows-desktop --enable-linux-desktop
   ```

4. **可选：Android/iOS**
   - Android：安装 Android Studio，并在 `flutter config --android-sdk <path>` 中配置 SDK
   - iOS：通过 Xcode 的 `Settings > Platforms` 安装所需模拟器运行时

> 当前 `flutter doctor` 仅提示 **Android SDK、CocoaPods、iOS 模拟器、网络到 github.com** 尚未就绪，若后续需要发布移动端或访问 GitHub，请按提示补齐。

## 2. 运行示例

```bash
cd /Users/jerryju/Desktop/stellarpalace/stellar_todo_desktop
flutter pub get
flutter run -d macos   # 或 linux/windows
```

运行后可体验：
- 待办新增（输入框 / 快速添加弹窗）
- 对勾切换完成状态、滑动删除
- 过滤标签（全部 / 进行中 / 已完成）
- 自动保存到本地 JSON，支持空态与错误提示

## 3. 目录与架构

```
lib/
 ├─ models/todo.dart             # Todo 数据模型 + JSON 序列化
 ├─ repository/todo_repository.dart  # 文件仓库实现（Application Support 目录）
 ├─ state/todo_controller.dart   # ChangeNotifier 状态 + 业务逻辑
 └─ main.dart                    # UI、Provider 装配、过滤/输入/列表组件
```

依赖：
- `provider`：状态订阅
- `path_provider`：跨平台应用支持目录
- `uuid`：生成待办 ID

## 4. 构建与打包

macOS 示例：
```bash
flutter build macos
open build/macos/Build/Products/Release/stellar_todo_desktop.app
```

Windows（需在 Windows 环境）：
```powershell
flutter build windows
Start-Process .\build\windows\x64\runner\Release\stellar_todo_desktop.exe
```

Linux：
```bash
flutter build linux
./build/linux/x64/release/bundle/stellar_todo_desktop
```

> 若需要分发安装包，可进一步使用 `productbuild` (macOS)、`MSIX Packaging Tool` (Windows) 或 `AppImage/Flatpak` (Linux) 对 `build` 目录进行封装。

## 5. 测试与质量

- 静态检查：`flutter analyze`
- 单元/组件测试：`flutter test`
- 关键测试：`test/widget_test.dart` 确认启动后显示标题与空态文案

## 6. 常见问题

| 问题 | 解决方案 |
| --- | --- |
| Android SDK 缺失 | 安装 Android Studio 并重新运行 `flutter doctor --android-licenses` |
| CocoaPods 未安装 | `sudo gem install cocoapods && pod setup` |
| iOS 模拟器缺失 | 打开 Xcode -> Settings -> Platforms 下载相应 runtime |
| 访问 `github.com` 失败 | 配置代理或使用镜像；Flutter 依赖下载已指向 `flutter-io.cn` |

## 7. 后续扩展建议

- 接入 SQLite/Isar 等数据库替代 JSON
- 增加快捷键、系统托盘、通知提醒等桌面特性
- 通过 `go_router`/`auto_route` 拆分多页面
- 接入后端 API，实现多端同步
