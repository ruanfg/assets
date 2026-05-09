import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/app_dio_factory.dart';
import '../../domain/settings/settings_repository.dart';
import '../../features/settings/models/settings_models.dart';

class RemoteSettingsRepository implements SettingsRepository {
  RemoteSettingsRepository({Dio? dio}) : _dio = dio ?? AppDioFactory.create();

  final Dio _dio;

  @override
  Future<LatestReleaseInfo?> fetchLatestRelease(String url) async {
    if (url.trim().isEmpty) return null;
    final response = await _dio.get<Map<String, dynamic>>(
      url,
      options: Options(responseType: ResponseType.json),
    );
    if ((response.statusCode ?? 500) >= 400 || response.data == null) {
      return null;
    }
    return LatestReleaseInfo(
      tagName: response.data?['tag_name']?.toString() ?? '',
      body: response.data?['body']?.toString() ?? '',
    );
  }

  @override
  Future<FeedbackResponse> submitFeedback({
    required String accessKey,
    required Map<String, dynamic> fields,
  }) async {
    final formData = FormData.fromMap({
      'access_key': accessKey,
      ...fields,
    });
    final response = await _dio.post<String>(
      'https://api.web3forms.com/submit',
      data: formData,
    );
    final decoded = jsonDecode(response.data ?? '{}');
    final raw = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    return FeedbackResponse(
      success: raw['success'] == true,
      raw: raw,
    );
  }
}
