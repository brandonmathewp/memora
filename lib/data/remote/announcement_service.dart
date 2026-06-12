import 'package:dio/dio.dart';
import '../config/constants.dart';

class Announcement {
  final String title;
  final String content;
  final String? minVersion;

  const Announcement({
    required this.title,
    required this.content,
    this.minVersion,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        title: json['title'] as String,
        content: json['content'] as String,
        minVersion: json['min_version'] as String?,
      );
}

class AnnouncementService {
  final Dio _dio = Dio();

  Future<Announcement?> fetchLatest() async {
    try {
      final res = await _dio.get(
        '${AppConstants.serverBaseUrl}/v1/announcement',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      if (res.statusCode == 200 && res.data != null) {
        return Announcement.fromJson(res.data as Map<String, dynamic>);
      }
    } catch (_) {
      // Silently fail
    }
    return null;
  }
}
