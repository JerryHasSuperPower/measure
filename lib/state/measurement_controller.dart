import 'package:flutter/material.dart';

import '../models/measurement_history.dart';
import '../models/measurement_record.dart';
import '../repository/history_repository.dart';
import '../services/data_calculator.dart';
import '../services/excel_generator.dart';
import '../services/file_service.dart';

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
}

