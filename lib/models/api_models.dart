/// Strongly-typed Dart data models matching FastAPI schemas.
library;

class UserResponse {
  final int id;
  final String name;
  final String email;

  const UserResponse({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
      };
}

class TokenResponse {
  final String accessToken;
  final String tokenType;

  const TokenResponse({
    required this.accessToken,
    required this.tokenType,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
    );
  }
}

class ProfileResponse {
  final int id;
  final int userId;
  final DateTime? dateOfBirth;
  final String? biologicalAssignment;
  final String? lifecycleStage;

  const ProfileResponse({
    required this.id,
    required this.userId,
    this.dateOfBirth,
    this.biologicalAssignment,
    this.lifecycleStage,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      biologicalAssignment: json['biological_assignment'] as String?,
      lifecycleStage: json['lifecycle_stage'] as String?,
    );
  }
}

class PeriodResponse {
  final int id;
  final DateTime startDate;
  final DateTime? endDate;

  const PeriodResponse({
    required this.id,
    required this.startDate,
    this.endDate,
  });

  factory PeriodResponse.fromJson(Map<String, dynamic> json) {
    return PeriodResponse(
      id: json['id'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
    );
  }
}

class SymptomResponse {
  final int id;
  final DateTime recordedOn;
  final String name;
  final int? severity;

  const SymptomResponse({
    required this.id,
    required this.recordedOn,
    required this.name,
    this.severity,
  });

  factory SymptomResponse.fromJson(Map<String, dynamic> json) {
    return SymptomResponse(
      id: json['id'] as int,
      recordedOn: DateTime.parse(json['recorded_on'] as String),
      name: json['name'] as String,
      severity: json['severity'] as int?,
    );
  }
}

class CheckinResponse {
  final int id;
  final DateTime recordedOn;
  final String mood;
  final int? energy;
  final String? notes;

  const CheckinResponse({
    required this.id,
    required this.recordedOn,
    required this.mood,
    this.energy,
    this.notes,
  });

  factory CheckinResponse.fromJson(Map<String, dynamic> json) {
    return CheckinResponse(
      id: json['id'] as int,
      recordedOn: DateTime.parse(json['recorded_on'] as String),
      mood: json['mood'] as String,
      energy: json['energy'] as int?,
      notes: json['notes'] as String?,
    );
  }
}

class InsightsResponse {
  final Map<String, dynamic> lifecycle;
  final Map<String, dynamic> cycle;
  final Map<String, dynamic> symptoms;
  final Map<String, dynamic> mood;
  final String safetyNote;

  const InsightsResponse({
    required this.lifecycle,
    required this.cycle,
    required this.symptoms,
    required this.mood,
    required this.safetyNote,
  });

  factory InsightsResponse.fromJson(Map<String, dynamic> json) {
    return InsightsResponse(
      lifecycle: Map<String, dynamic>.from(json['lifecycle'] as Map? ?? {}),
      cycle: Map<String, dynamic>.from(json['cycle'] as Map? ?? {}),
      symptoms: Map<String, dynamic>.from(json['symptoms'] as Map? ?? {}),
      mood: Map<String, dynamic>.from(json['mood'] as Map? ?? {}),
      safetyNote: json['safety_note'] as String? ?? '',
    );
  }
}
