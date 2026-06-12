import 'package:dio/dio.dart';
import '../../config/constants.dart';

class FeedbackService {
  final Dio _dio = Dio();

  Future<bool> submit(String content, {String? email}) async {
    try {
      final res = await _dio.post(
        '${AppConstants.serverBaseUrl}/v1/feedback',
        data: {
          'content': content,
          if (email != null) 'email': email,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
