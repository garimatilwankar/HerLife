import 'package:herlife/core/network/api_client.dart';
import 'package:herlife/models/api_models.dart';

/// Service for fetching backend-driven educational content.
class EducationService {
  /// Fetches educational articles with optional filters for lifecycle stage and category.
  static Future<List<EducationResponse>> getArticles({
    String? lifecycleStage,
    String? category,
  }) async {
    try {
      final dio = ApiClient().dio;
      final queryParams = <String, dynamic>{};
      if (lifecycleStage != null && lifecycleStage.isNotEmpty) {
        queryParams['lifecycle_stage'] = lifecycleStage;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final response = await dio.get(
        '/api/education',
        queryParameters: queryParams,
      );

      if (response.data is List) {
        final list = response.data as List;
        return list
            .map((item) => EducationResponse.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetches a specific educational article by ID.
  static Future<EducationResponse?> getArticle(int id) async {
    try {
      final dio = ApiClient().dio;
      final response = await dio.get('/api/education/$id');
      if (response.data != null) {
        return EducationResponse.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
