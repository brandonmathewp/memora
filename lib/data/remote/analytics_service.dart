import 'package:dio/dio.dart';
import '../config/constants.dart';

class AnalyticsService {
  final Dio _dio = Dio();

  Future<void> reportStartup(String version) async {
    try {
      await _dio.post(
        '${AppConstants.serverBaseUrl}/v1/stats',
        data: {'version': version},
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
    } catch (_) {
      // Silently fail - analytics are non-critical
    }
  }
}
