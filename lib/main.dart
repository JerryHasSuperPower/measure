import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'repository/history_repository.dart';
import 'screens/home_screen.dart';
import 'services/logger_service.dart';
import 'state/measurement_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化日志服务
  await LoggerService().init();
  LoggerService().info('应用启动');
  
  final FileHistoryRepository repository = FileHistoryRepository();
  runApp(MeasurementApp(repository: repository));
}

class MeasurementApp extends StatelessWidget {
  const MeasurementApp({super.key, required this.repository});

  final HistoryRepository repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MeasurementController>(
      create: (BuildContext context) =>
          MeasurementController(repository)..init(),
      child: MaterialApp(
        title: '测斜原始记录处理',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0E1117),
          cardColor: const Color(0xFF1A1D24),
          textTheme: ThemeData.dark().textTheme.apply(
                bodyColor: const Color(0xFFE5E7EB),
                displayColor: const Color(0xFFE5E7EB),
              ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A1D24),
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE5E7EB),
              side: const BorderSide(color: Color(0xFF374151)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF252936),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF374151)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF374151)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF6366F1),
                width: 2,
              ),
            ),
            labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            hintStyle: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
