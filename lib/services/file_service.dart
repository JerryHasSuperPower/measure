import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

/// 文件操作服务，负责文件保存和打开
class FileService {
  /// 保存Excel文件到本地
  /// [bytes] Excel文件的字节数据
  /// [fileName] 文件名（不包含扩展名）
  /// 返回保存的文件路径，如果取消则返回null
  static Future<String?> saveExcelFile(
    List<int> bytes,
    String fileName,
  ) async {
    try {
      // 使用file_picker选择保存位置
      print('准备显示保存对话框');
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: '保存Excel文件',
        fileName: '$fileName.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      print('保存对话框返回结果: $outputFile');

      if (outputFile == null || outputFile.isEmpty) {
        // 用户取消了保存或对话框没有返回有效路径
        print('用户取消保存或对话框返回空');
        return null;
      }

      // 写入文件
      print('准备写入文件到: $outputFile');
      final File file = File(outputFile);
      await file.writeAsBytes(bytes);
      print('文件写入成功');

      return outputFile;
    } catch (e, stackTrace) {
      print('保存文件异常: $e');
      print('堆栈跟踪: $stackTrace');
      throw Exception('保存文件失败: $e');
    }
  }

  /// 使用系统默认应用打开Excel文件
  /// [filePath] Excel文件路径
  static Future<void> openExcelFile(String filePath) async {
    try {
      // 使用系统命令打开文件
      if (Platform.isMacOS) {
        await Process.run('open', [filePath]);
      } else if (Platform.isWindows) {
        await Process.run('start', [filePath], runInShell: true);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [filePath]);
      } else {
        throw Exception('不支持的操作系统');
      }
    } catch (e) {
      throw Exception('打开文件失败: $e');
    }
  }

  /// 获取保存目录
  /// 返回应用支持目录下的excel子目录
  static Future<Directory> getSaveDirectory() async {
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final Directory excelDir = Directory(
      '${appSupportDir.path}/stellar_todo_desktop/excel',
    );
    if (!await excelDir.exists()) {
      await excelDir.create(recursive: true);
    }
    return excelDir;
  }

  /// 保存Excel文件到应用支持目录
  /// [bytes] Excel文件的字节数据
  /// [fileName] 文件名（不包含扩展名）
  /// 返回保存的文件路径
  static Future<String> saveExcelFileToAppDir(
    List<int> bytes,
    String fileName,
  ) async {
    try {
      final Directory saveDir = await getSaveDirectory();
      final String filePath = '${saveDir.path}/$fileName.xlsx';
      final File file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      throw Exception('保存文件失败: $e');
    }
  }

  /// 保存Excel文件到下载文件夹
  /// [bytes] Excel文件的字节数据
  /// [fileName] 文件名（不包含扩展名）
  /// 返回保存的文件路径
  static Future<String> saveExcelFileToDownloads(
    List<int> bytes,
    String fileName,
  ) async {
    try {
      String downloadsPath;
      if (Platform.isMacOS) {
        // macOS下载文件夹路径
        final String homeDir = Platform.environment['HOME'] ?? '';
        downloadsPath = '$homeDir/Downloads';
      } else if (Platform.isWindows) {
        downloadsPath = Platform.environment['USERPROFILE'] ?? '';
        downloadsPath = '$downloadsPath\\Downloads';
      } else if (Platform.isLinux) {
        final String homeDir = Platform.environment['HOME'] ?? '';
        downloadsPath = '$homeDir/Downloads';
      } else {
        throw Exception('不支持的操作系统');
      }

      final Directory downloadsDir = Directory(downloadsPath);
      if (!await downloadsDir.exists()) {
        throw Exception('下载文件夹不存在: $downloadsPath');
      }

      final String filePath = '$downloadsPath/$fileName.xlsx';
      final File file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      throw Exception('保存文件到下载文件夹失败: $e');
    }
  }
}

