import 'package:flutter/material.dart';

import '../models/daily_measurement.dart';
import '../models/measurement_history.dart';
import '../models/measurement_record.dart';
import '../repository/history_repository.dart';
import '../services/csv_parser.dart';
import '../services/csv_template_generator.dart';
import '../services/data_calculator.dart';
import '../services/excel_generator.dart';
import '../services/merged_excel_generator.dart';
import '../services/file_service.dart';
import '../services/logger_service.dart';

/// 测量数据状态管理控制器
class MeasurementController extends ChangeNotifier {
  MeasurementController(this._historyRepository);

  final HistoryRepository _historyRepository;

  // 当前测量数据列表
  List<MeasurementRecord> _records = [];
  List<MeasurementRecord> get records => List.unmodifiable(_records);

  // 深度参数
  double? _depth;
  double? get depth => _depth;

  // 加载状态
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 保存状态
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  // 错误消息
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // 历史记录列表
  List<MeasurementHistory> _history = [];
  List<MeasurementHistory> get history => List.unmodifiable(_history);

  // 当前生成的Excel文件路径
  String? _currentExcelPath;
  String? get currentExcelPath => _currentExcelPath;

  // 每日测量数据管理
  final List<DailyMeasurement> _dailyMeasurements = [];
  List<DailyMeasurement> get dailyMeasurements => List.unmodifiable(_dailyMeasurements);

  // 选中的基础记录
  MeasurementHistory? _selectedBaseHistory;
  MeasurementHistory? get selectedBaseHistory => _selectedBaseHistory;

  // 计算结果（按日期索引）
  final Map<DateTime, List<MeasurementRecord>> _calculatedResults = {};
  Map<DateTime, List<MeasurementRecord>> get calculatedResults =>
      Map.unmodifiable(_calculatedResults);

  /// 初始化，加载历史记录
  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _history = await _historyRepository.loadHistory();
    } catch (error) {
      _errorMessage = '加载历史记录失败：$error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 生成测量数据
  /// [depth] 深度参数（单位：米）
  Future<void> generateData(double depth) async {
    if (depth <= 0) {
      _errorMessage = '深度参数必须大于0';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _depth = depth;
    notifyListeners();

    try {
      // 生成数据
      _records = DataCalculator.generateMeasurementData(depth);
      _currentExcelPath = null; // 重置文件路径
    } catch (error) {
      _errorMessage = '生成数据失败：$error';
      _records = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 生成Excel文件并保存到应用目录
  Future<String?> generateExcelFile() async {
    if (_records.isEmpty) {
      _errorMessage = '没有可生成的数据';
      notifyListeners();
      return null;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 生成Excel字节数据
      final List<int> excelBytes = ExcelGenerator.generateExcel(_records);

      // 生成文件名（包含时间戳）
      final String fileName =
          '测斜原始记录处理_${_depth}m_${DateTime.now().millisecondsSinceEpoch}';

      // 保存到应用目录
      final String filePath =
          await FileService.saveExcelFileToAppDir(excelBytes, fileName);

      _currentExcelPath = filePath;
      return filePath;
    } catch (error) {
      _errorMessage = '生成Excel文件失败：$error';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// 下载Excel文件（保存到用户选择的位置）
  Future<String?> downloadExcel() async {
    if (_records.isEmpty) {
      _errorMessage = '没有可下载的数据';
      notifyListeners();
      return null;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 生成Excel字节数据
      final List<int> excelBytes = ExcelGenerator.generateExcel(_records);
      debugPrint('Excel文件生成成功，大小: ${excelBytes.length} 字节');

      // 生成文件名
      final String fileName =
          '测斜原始记录处理_${_depth}m_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('准备保存文件: $fileName.xlsx');

      // 先尝试使用文件选择对话框保存
      String? filePath;
      try {
        filePath = await FileService.saveExcelFile(excelBytes, fileName);
        debugPrint('文件保存结果: $filePath');
      } catch (e) {
        debugPrint('使用文件选择对话框保存失败: $e');
        filePath = null;
      }

      // 如果文件选择对话框返回null或失败，自动保存到下载文件夹
      if (filePath == null || filePath.isEmpty) {
        debugPrint('文件选择对话框未返回有效路径，尝试保存到下载文件夹');
        try {
          filePath = await FileService.saveExcelFileToDownloads(excelBytes, fileName);
          debugPrint('文件已保存到下载文件夹: $filePath');
        } catch (e2) {
          debugPrint('保存到下载文件夹失败: $e2');
          _errorMessage = '保存文件失败: $e2';
          notifyListeners();
          return null;
        }
      }

      if (filePath != null && filePath.isNotEmpty) {
        _currentExcelPath = filePath;
        // 保存到历史记录
        debugPrint('准备保存到历史记录');
        await _saveToHistory(filePath);
        debugPrint('历史记录保存完成');
        // 重新加载历史记录列表
        await loadHistory();
      } else {
        debugPrint('所有保存方式都失败');
        _errorMessage = '保存文件失败：无法保存到任何位置';
        notifyListeners();
      }

      return filePath;
    } catch (error) {
      debugPrint('下载Excel文件失败：$error');
      _errorMessage = '下载Excel文件失败：$error';
      notifyListeners();
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// 在外部应用打开Excel文件
  Future<void> openExcelInExternalApp(String? filePath) async {
    final String path = filePath ?? _currentExcelPath ?? '';
    if (path.isEmpty) {
      _errorMessage = '没有可打开的文件';
      notifyListeners();
      return;
    }

    try {
      await FileService.openExcelFile(path);
    } catch (error) {
      _errorMessage = '打开文件失败：$error';
      notifyListeners();
    }
  }

  /// 保存到历史记录
  Future<void> _saveToHistory(String filePath) async {
    if (_depth == null || _records.isEmpty) {
      debugPrint('无法保存历史记录：depth=$_depth, records=${_records.length}');
      return;
    }

    try {
      debugPrint('创建历史记录对象');
      final MeasurementHistory history = MeasurementHistory(
        depth: _depth!,
        createdAt: DateTime.now(),
        filePath: filePath,
        records: List.from(_records),
      );

      debugPrint('添加到历史记录仓库');
      await _historyRepository.addHistory(history);
      debugPrint('历史记录已添加到仓库');
      
      // 重新加载历史记录以确保同步
      _history = await _historyRepository.loadHistory();
      debugPrint('历史记录列表已更新，共 ${_history.length} 条');
      notifyListeners();
    } catch (error, stackTrace) {
      // 保存历史记录失败不影响主流程
      debugPrint('保存历史记录失败：$error');
      debugPrint('堆栈跟踪：$stackTrace');
    }
  }

  /// 加载历史记录
  Future<void> loadHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _history = await _historyRepository.loadHistory();
    } catch (error) {
      _errorMessage = '加载历史记录失败：$error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 删除历史记录
  Future<void> deleteHistory(String id) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _historyRepository.deleteHistory(id);
      _history.removeWhere((MeasurementHistory h) => h.id == id);
    } catch (error) {
      _errorMessage = '删除历史记录失败：$error';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// 从历史记录加载数据
  Future<void> loadFromHistory(MeasurementHistory history) async {
    _depth = history.depth;
    _records = List.from(history.records);
    _currentExcelPath = history.filePath;
    _errorMessage = null;
    notifyListeners();
  }

  /// 清除错误消息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ========== 每日测量数据管理 ==========

  /// 设置基础记录
  void setBaseHistory(MeasurementHistory? history) {
    _selectedBaseHistory = history;
    // 如果切换了基础记录，清空计算结果
    if (history == null) {
      _calculatedResults.clear();
    }
    notifyListeners();
  }

  /// 添加单日测量数据
  void addDailyMeasurement(DailyMeasurement measurement) {
    // 检查行数是否与基础记录一致
    if (_selectedBaseHistory != null &&
        measurement.values.length != _selectedBaseHistory!.records.length) {
      _errorMessage =
          '每日数据行数(${measurement.values.length})与基础记录行数(${_selectedBaseHistory!.records.length})不一致';
      notifyListeners();
      return;
    }
    _dailyMeasurements.add(measurement);
    _errorMessage = null;
    notifyListeners();
  }

  /// 更新单日测量数据
  void updateDailyMeasurement(int index, DailyMeasurement measurement) {
    if (index < 0 || index >= _dailyMeasurements.length) {
      return;
    }
    // 检查行数是否与基础记录一致
    if (_selectedBaseHistory != null &&
        measurement.values.length != _selectedBaseHistory!.records.length) {
      _errorMessage =
          '每日数据行数(${measurement.values.length})与基础记录行数(${_selectedBaseHistory!.records.length})不一致';
      notifyListeners();
      return;
    }
    _dailyMeasurements[index] = measurement;
    _errorMessage = null;
    notifyListeners();
  }

  /// 删除单日测量数据
  void removeDailyMeasurement(int index) {
    if (index >= 0 && index < _dailyMeasurements.length) {
      final removed = _dailyMeasurements.removeAt(index);
      // 清除对应的计算结果
      _calculatedResults.remove(removed.date);
      notifyListeners();
    }
  }

  /// 清空所有每日测量数据
  void clearDailyMeasurements() {
    _dailyMeasurements.clear();
    _calculatedResults.clear();
    notifyListeners();
  }

  /// 计算所有每日数据
  Future<void> calculateFromDailyData() async {
    if (_selectedBaseHistory == null) {
      _errorMessage = '请先选择基础记录';
      notifyListeners();
      return;
    }

    if (_dailyMeasurements.isEmpty) {
      _errorMessage = '请先添加每日测量数据';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _calculatedResults.clear();
      final results = DataCalculator.calculateMultipleDays(
        _dailyMeasurements,
        _selectedBaseHistory!.records,
      );
      _calculatedResults.addAll(results);
    } catch (error) {
      _errorMessage = '计算失败：$error';
      _calculatedResults.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 生成计算结果的Excel文件（单个日期）
  Future<String?> generateCalculatedExcel(DateTime date) async {
    final records = _calculatedResults[date];
    if (records == null || records.isEmpty) {
      _errorMessage = '该日期没有计算结果';
      notifyListeners();
      return null;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 生成Excel字节数据
      final List<int> excelBytes = ExcelGenerator.generateExcel(records);

      // 生成文件名（包含日期）
      final String dateStr =
          '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
      final String fileName = '测斜计算结果_$dateStr';

      // 保存到用户选择的位置
      String? filePath;
      try {
        filePath = await FileService.saveExcelFile(excelBytes, fileName);
      } catch (e) {
        debugPrint('使用文件选择对话框保存失败: $e');
      }

      // 如果文件选择对话框返回null或失败，自动保存到下载文件夹
      if (filePath == null || filePath.isEmpty) {
        try {
          filePath = await FileService.saveExcelFileToDownloads(excelBytes, fileName);
        } catch (e2) {
          _errorMessage = '保存文件失败: $e2';
          notifyListeners();
          return null;
        }
      }

      return filePath;
    } catch (error) {
      _errorMessage = '生成Excel文件失败：$error';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// 批量生成所有计算结果的Excel文件
  Future<List<String>> generateAllCalculatedExcels() async {
    if (_calculatedResults.isEmpty) {
      _errorMessage = '没有计算结果';
      notifyListeners();
      return [];
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final List<String> filePaths = [];

    try {
      for (final entry in _calculatedResults.entries) {
        final date = entry.key;
        final records = entry.value;

        // 生成Excel字节数据
        final List<int> excelBytes = ExcelGenerator.generateExcel(records);

        // 生成文件名（包含日期）
        final String dateStr =
            '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
        final String fileName = '测斜计算结果_$dateStr';

        // 保存到下载文件夹
        try {
          final filePath =
              await FileService.saveExcelFileToDownloads(excelBytes, fileName);
          filePaths.add(filePath);
        } catch (e) {
          debugPrint('保存文件失败: $e');
        }
      }
    } catch (error) {
      _errorMessage = '批量生成Excel文件失败：$error';
    } finally {
      _isSaving = false;
      notifyListeners();
    }

    return filePaths;
  }

  /// 生成合并所有计算结果的Excel文件
  /// 将所有日期的数据横向合并到一个表格中
  /// 返回保存的文件路径，如果失败则返回null
  Future<String?> generateMergedExcel() async {
    if (_calculatedResults.isEmpty) {
      _errorMessage = '没有计算结果';
      notifyListeners();
      return null;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      LoggerService().info('开始生成合并Excel文件，共 ${_calculatedResults.length} 天的数据');
      
      // 生成合并Excel（包含三个工作表）
      final mergedBytes = MergedExcelGenerator.generateMergedExcel(
        _calculatedResults,
        baseRecords: _selectedBaseHistory?.records,
        dailyMeasurements: _dailyMeasurements,
      );
      LoggerService().info('合并Excel生成成功，大小: ${mergedBytes.length} 字节');

      // 生成文件名
      final String fileName = '测斜计算结果_合并_${DateTime.now().millisecondsSinceEpoch}';

      // 保存到用户选择的位置
      String? filePath;
      try {
        filePath = await FileService.saveExcelFile(mergedBytes, fileName);
        LoggerService().info('通过文件选择对话框保存合并文件: $filePath');
      } catch (e) {
        LoggerService().error('使用文件选择对话框保存失败', e);
        debugPrint('使用文件选择对话框保存失败: $e');
      }

      // 如果文件选择对话框返回null或失败，自动保存到下载文件夹
      if (filePath == null || filePath.isEmpty) {
        try {
          filePath = await FileService.saveExcelFileToDownloads(mergedBytes, fileName);
          LoggerService().info('合并文件已保存到下载文件夹: $filePath');
        } catch (e2) {
          _errorMessage = '保存合并文件失败: $e2';
          LoggerService().error('保存合并文件到下载文件夹失败', e2);
          notifyListeners();
          return null;
        }
      }

      LoggerService().info('合并Excel生成完成: $filePath');
      return filePath;
    } catch (error, stackTrace) {
      _errorMessage = '生成合并Excel文件失败：$error';
      LoggerService().error('生成合并Excel文件失败', error, stackTrace);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ========== CSV模板和导入功能 ==========

  /// 生成每日测量数据导入CSV模板
  /// [defaultDates] 默认日期列表（可选）
  /// 返回保存的文件路径，如果取消则返回null
  Future<String?> generateDailyDataTemplate({List<DateTime>? defaultDates}) async {
    LoggerService().info('开始生成每日测量数据CSV模板');
    
    if (_selectedBaseHistory == null) {
      _errorMessage = '请先选择基础记录';
      LoggerService().warning('生成模板失败：未选择基础记录');
      notifyListeners();
      return null;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      LoggerService().info('基础记录：深度=${_selectedBaseHistory!.depth}m, 行数=${_selectedBaseHistory!.records.length}');
      
      // 生成CSV模板（默认10天）
      final templateBytes = CsvTemplateGenerator.generateTemplate(
        _selectedBaseHistory!,
        defaultDates: defaultDates,
      );
      
      LoggerService().info('CSV模板生成成功，大小: ${templateBytes.length} 字节');

      // 生成文件名
      final String fileName = '每日测量数据模板_${_selectedBaseHistory!.depth}m';

      // 保存到用户选择的位置
      String? filePath;
      try {
        filePath = await FileService.saveCsvFile(templateBytes, fileName);
        if (filePath != null && filePath.isNotEmpty) {
          LoggerService().info('通过文件选择对话框保存模板: $filePath');
        } else {
          // 用户取消了保存对话框
          LoggerService().info('用户取消了模板保存');
          _isSaving = false;
          notifyListeners();
          return null;
        }
      } catch (e) {
        LoggerService().error('使用文件选择对话框保存失败', e);
        debugPrint('使用文件选择对话框保存失败: $e');
        _errorMessage = '保存模板失败: $e';
        _isSaving = false;
        notifyListeners();
        return null;
      }

      LoggerService().info('CSV模板生成完成: $filePath');
      return filePath;
    } catch (error, stackTrace) {
      _errorMessage = '生成模板失败：$error';
      LoggerService().error('生成模板失败', error, stackTrace);
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// 从CSV文件导入每日测量数据
  /// 返回导入的数据数量，如果失败则返回0
  Future<int> importDailyDataFromExcel() async {
    LoggerService().info('开始导入CSV文件');
    
    if (_selectedBaseHistory == null) {
      _errorMessage = '请先选择基础记录';
      LoggerService().warning('导入失败：未选择基础记录');
      notifyListeners();
      return 0;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 选择CSV文件
      final bytes = await FileService.pickCsvFile();
      if (bytes == null) {
        // 用户取消了选择
        LoggerService().info('用户取消了文件选择');
        _isLoading = false;
        notifyListeners();
        return 0;
      }

      LoggerService().info('已选择CSV文件，大小: ${bytes.length} 字节');

      // 解析CSV文件
      final measurements = CsvParser.parseDailyMeasurements(bytes);
      LoggerService().info('CSV文件解析成功，共 ${measurements.length} 天的数据');

      // 验证数据行数
      final expectedRowCount = _selectedBaseHistory!.records.length;
      for (final measurement in measurements) {
        if (measurement.values.length != expectedRowCount) {
          _errorMessage =
              '导入的数据行数(${measurement.values.length})与基础记录行数($expectedRowCount)不一致';
          LoggerService().error('数据行数不匹配: ${measurement.values.length} vs $expectedRowCount');
          _isLoading = false;
          notifyListeners();
          return 0;
        }
      }

      // 清空现有数据并添加新数据
      _dailyMeasurements.clear();
      _calculatedResults.clear();
      _dailyMeasurements.addAll(measurements);

      LoggerService().info('导入完成，共导入 ${measurements.length} 天的数据');
      return measurements.length;
    } catch (error, stackTrace) {
      // 确保错误信息详细
      String errorMsg = '导入Excel文件失败';
      if (error is Exception) {
        errorMsg = error.toString();
        // 移除 "Exception: " 前缀，使错误信息更清晰
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring(11);
        }
      } else {
        errorMsg = '导入Excel文件失败：$error';
      }
      
      _errorMessage = errorMsg;
      
      try {
        LoggerService().error('导入Excel文件失败', error, stackTrace);
      } catch (logError) {
        print('日志记录失败: $logError');
        print('原始错误: $error');
        print('堆栈跟踪: $stackTrace');
      }
      
      return 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

