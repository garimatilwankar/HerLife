import 'package:dio/dio.dart';
import 'package:herlife/core/network/api_client.dart';
import 'package:herlife/models/api_models.dart';

/// Service for making questions to the backend conversational search endpoint POST /api/ask.
class AskService {
  /// Sends a user question and recent conversation history to the backend endpoint POST /api/ask.
  static Future<AskResponse?> askQuestion(
    String question, {
    List<ChatMessageItem> history = const [],
  }) async {
    try {
      final dio = ApiClient().dio;
      final requestData = AskRequest(
        question: question,
        conversationHistory: history,
      ).toJson();

      final response = await dio.post(
        '/api/ask',
        data: requestData,
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.data != null) {
        return AskResponse.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['detail'] != null) {
        throw Exception(e.response?.data['detail'].toString());
      }
      throw Exception(ApiClient.formatError(e));
    } catch (_) {
      throw Exception(
        "I'm having a little trouble responding right now. Please try again in a moment.",
      );
    }
  }
}
