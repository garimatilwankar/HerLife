import 'package:dio/dio.dart';
import 'package:herlife/core/network/api_client.dart';
import 'package:herlife/models/api_models.dart';

/// Service for making questions to the backend educational search endpoint POST /api/ask.
class AskService {
  /// Sends a user question to the backend and returns structured educational sources and answer.
  static Future<AskResponse?> askQuestion(String question) async {
    try {
      final dio = ApiClient().dio;
      final response = await dio.post(
        '/api/ask',
        data: {'question': question},
      );

      if (response.data != null) {
        return AskResponse.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['detail'] != null) {
        throw Exception(e.response?.data['detail'].toString());
      }
      rethrow;
    } catch (_) {
      return null;
    }
  }
}
