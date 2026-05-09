import '../../features/settings/models/settings_models.dart';

abstract class SettingsRepository {
  Future<LatestReleaseInfo?> fetchLatestRelease(String url);

  Future<FeedbackResponse> submitFeedback({
    required String accessKey,
    required Map<String, dynamic> fields,
  });
}
