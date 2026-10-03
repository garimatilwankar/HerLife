import 'package:herlife/core/network/api_client.dart';
import 'package:herlife/models/api_models.dart';

/// Service for fetching health insights from GET /api/insights via FastAPI backend.
class InsightsService {
  /// Fetches computed cycle, symptom, mood, and lifecycle insights.
  static Future<InsightsResponse?> getInsights() async {
    try {
      final dio = ApiClient().dio;
      final response = await dio.get('/api/insights');

      if (response.data == null) return null;

      return InsightsResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }
}
