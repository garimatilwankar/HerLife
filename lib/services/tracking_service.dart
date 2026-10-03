import 'package:herlife/core/network/api_client.dart';
import 'package:herlife/models/api_models.dart';

/// Service for managing periods, symptoms, and daily check-ins via FastAPI backend.
class TrackingService {
  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  // -------------------- PERIODS --------------------

  /// Fetches period history from GET /api/periods.
  static Future<List<PeriodResponse>> getPeriods() async {
    try {
      final dio = ApiClient().dio;
      final response = await dio.get('/api/periods');

      final list = response.data as List? ?? [];
      return list
          .map((item) => PeriodResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Creates a period entry via POST /api/periods.
  static Future<PeriodResponse?> createPeriod(
    DateTime startDate, {
    DateTime? endDate,
  }) async {
    try {
      final dio = ApiClient().dio;
      final payload = <String, dynamic>{
        'start_date': _formatDate(startDate),
        if (endDate != null) 'end_date': _formatDate(endDate),
      };

      final response = await dio.post('/api/periods', data: payload);
      return PeriodResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Updates a period entry via PATCH /api/periods/{period_id}.
  static Future<PeriodResponse?> updatePeriod(
    int periodId,
    DateTime startDate, {
    DateTime? endDate,
  }) async {
    try {
      final dio = ApiClient().dio;
      final payload = <String, dynamic>{
        'start_date': _formatDate(startDate),
        'end_date': endDate != null ? _formatDate(endDate) : null,
      };

      final response = await dio.patch('/api/periods/$periodId', data: payload);
      return PeriodResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // -------------------- SYMPTOMS --------------------

  /// Fetches symptom history from GET /api/symptoms.
  static Future<List<SymptomResponse>> getSymptoms() async {
    try {
      final dio = ApiClient().dio;
      final response = await dio.get('/api/symptoms');

      final list = response.data as List? ?? [];
      return list
          .map((item) => SymptomResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Creates a symptom entry via POST /api/symptoms.
  static Future<SymptomResponse?> createSymptom(
    DateTime recordedOn,
    String name, {
    int? severity,
  }) async {
    try {
      final dio = ApiClient().dio;
      final payload = <String, dynamic>{
        'recorded_on': _formatDate(recordedOn),
        'name': name.trim(),
        'severity': ?severity,
      };

      final response = await dio.post('/api/symptoms', data: payload);
      return SymptomResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Deletes a symptom entry via DELETE /api/symptoms/{symptom_id}.
  static Future<bool> deleteSymptom(int symptomId) async {
    try {
      final dio = ApiClient().dio;
      await dio.delete('/api/symptoms/$symptomId');
      return true;
    } catch (_) {
      return false;
    }
  }

  // -------------------- DAILY CHECK-INS --------------------

  /// Fetches daily check-in history from GET /api/checkins.
  static Future<List<CheckinResponse>> getCheckins() async {
    try {
      final dio = ApiClient().dio;
      final response = await dio.get('/api/checkins');

      final list = response.data as List? ?? [];
      return list
          .map((item) => CheckinResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Creates or updates a daily check-in entry via POST /api/checkins.
  static Future<CheckinResponse?> createCheckin(
    DateTime recordedOn,
    String mood, {
    int? energy,
    String? notes,
  }) async {
    try {
      final dio = ApiClient().dio;
      final payload = <String, dynamic>{
        'recorded_on': _formatDate(recordedOn),
        'mood': mood.trim(),
        'energy': ?energy,
        'notes': ?notes,
      };

      final response = await dio.post('/api/checkins', data: payload);
      return CheckinResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
