import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 120),
  ));
  final _storage = const FlutterSecureStorage();

  String _baseUrl = '';
  String _apiKey = '';

  Future<void> loadConfig() async {
    _baseUrl = await _storage.read(key: 'api_base_url') ?? '';
    _apiKey = await _storage.read(key: 'api_key') ?? '';
  }

  Future<void> saveConfig(String baseUrl, String apiKey) async {
    await _storage.write(key: 'api_base_url', value: baseUrl);
    await _storage.write(key: 'api_key', value: apiKey);
    _baseUrl = baseUrl;
    _apiKey = apiKey;
  }

  bool get isConfigured => _baseUrl.isNotEmpty && _apiKey.isNotEmpty;

  Future<String> chatCompletion({
    required List<Map<String, String>> messages,
    String? systemPrompt,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    final payload = <String, dynamic>{
      'model': await _storage.read(key: 'model_name') ?? 'deepseek-chat',
      'messages': [
        if (systemPrompt != null)
          {'role': 'system', 'content': systemPrompt},
        ...messages,
      ],
      'temperature': temperature,
      'max_tokens': maxTokens,
    };

    final response = await _dio.post(
      '$_baseUrl/v1/chat/completions',
      data: payload,
      options: Options(headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      }),
    );

    return response.data['choices'][0]['message']['content'] as String;
  }

  String? get baseUrl => _baseUrl;
}
