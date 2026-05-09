class LatestReleaseInfo {
  const LatestReleaseInfo({
    required this.tagName,
    required this.body,
  });

  final String tagName;
  final String body;
}

class FeedbackResponse {
  const FeedbackResponse({
    required this.success,
    required this.raw,
  });

  final bool success;
  final Map<String, dynamic> raw;
}
