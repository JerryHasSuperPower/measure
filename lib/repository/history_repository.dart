import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/measurement_history.dart';

/// 历史记录仓库接口
abstract class HistoryRepository {
  Future<List<MeasurementHistory>> loadHistory();
  Future<void> saveHistory(List<MeasurementHistory> history);
  Future<void> addHistory(MeasurementHistory history);
  Future<void> deleteHistory(String id);
  Future<void> clear();
}

/// 使用JSON文件存储历史记录
class FileHistoryRepository implements HistoryRepository {
  FileHistoryRepository({this.fileName = 'measurement_history.json'});

  final String fileName;

  Future<File> get _storageFile async {
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final Directory historyDir = Directory(
      '${appSupportDir.path}/stellar_todo_desktop',
    );
    if (!await historyDir.exists()) {
      await historyDir.create(recursive: true);
    }
    return File('${historyDir.path}/$fileName');
  }

  @override
  Future<List<MeasurementHistory>> loadHistory() async {
    try {
      final File file = await _storageFile;
      if (!await file.exists()) {
        return <MeasurementHistory>[];
      }
      final String content = await file.readAsString();
      if (content.trim().isEmpty) {
        return <MeasurementHistory>[];
      }
      final List<dynamic> jsonList = jsonDecode(content) as List<dynamic>;
      return jsonList
          .map(
            (dynamic item) => MeasurementHistory.fromJson(
              item as Map<String, dynamic>? ?? <String, dynamic>{},
            ),
          )
          .toList();
    } on FormatException {
      // 若文件损坏则清空并返回空列表
      await clear();
      return <MeasurementHistory>[];
    } catch (e) {
      return <MeasurementHistory>[];
    }
  }

  @override
  Future<void> saveHistory(List<MeasurementHistory> history) async {
    final File file = await _storageFile;
    final String serialized = jsonEncode(
      history.map((MeasurementHistory h) => h.toJson()).toList(),
    );
    await file.writeAsString(serialized);
  }

  @override
  Future<void> addHistory(MeasurementHistory history) async {
    final List<MeasurementHistory> allHistory = await loadHistory();
    allHistory.insert(0, history); // 新记录添加到最前面
    await saveHistory(allHistory);
  }

  @override
  Future<void> deleteHistory(String id) async {
    final List<MeasurementHistory> allHistory = await loadHistory();
    allHistory.removeWhere((MeasurementHistory h) => h.id == id);
    await saveHistory(allHistory);
  }

  @override
  Future<void> clear() async {
    final File file = await _storageFile;
    if (await file.exists()) {
      await file.delete();
    }
  }
}


