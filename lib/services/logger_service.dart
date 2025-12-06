import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// 日志服务，负责记录应用执行日志
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  File? _logFile;
  final List<String> _logBuffer = [];
  static const int _maxBufferSize = 100;

  /// 初始化日志服务
  Future<void> init() async {
    try {
      final Directory appSupportDir = await getApplicationSupportDirectory();
      final Directory logDir = Directory('${appSupportDir.path}/stellar_todo_desktop/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      // 使用日期作为日志文件名
      final String dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _logFile = File('${logDir.path}/app_$dateStr.log');

      // 写入启动日志
      await _writeToFile('=== 应用启动 ===');
      await _writeToFile('时间: ${DateTime.now().toIso8601String()}');
    } catch (e) {
      print('初始化日志服务失败: $e');
    }
  }

  /// 记录信息日志
  void info(String message) {
    _log('INFO', message);
  }

  /// 记录警告日志
  void warning(String message) {
    _log('WARN', message);
  }

  /// 记录错误日志
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', message);
    if (error != null) {
      _log('ERROR', '错误详情: $error');
    }
    if (stackTrace != null) {
      _log('ERROR', '堆栈跟踪: $stackTrace');
    }
  }

  /// 记录调试日志
  void debug(String message) {
    _log('DEBUG', message);
  }

  /// 内部日志记录方法
  void _log(String level, String message) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
    final logMessage = '[$timestamp] [$level] $message';
    
    // 打印到控制台
    print(logMessage);
    
    // 添加到缓冲区
    _logBuffer.add(logMessage);
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }
    
    // 异步写入文件
    _writeToFile(logMessage);
  }

  /// 写入日志到文件
  Future<void> _writeToFile(String message) async {
    if (_logFile == null) {
      return;
    }
    
    try {
      await _logFile!.writeAsString('$message\n', mode: FileMode.append);
    } catch (e) {
      print('写入日志文件失败: $e');
    }
  }

  /// 获取日志文件路径
  String? getLogFilePath() {
    return _logFile?.path;
  }

  /// 获取最近的日志（从缓冲区）
  List<String> getRecentLogs() {
    return List.from(_logBuffer);
  }

  /// 清空日志缓冲区
  void clearBuffer() {
    _logBuffer.clear();
  }
}

