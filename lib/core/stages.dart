/// The one place where life-stage names are defined in the app.
/// Never type a stage name as a string anywhere else.
class LifeStages {
  static const adolescence = 'Adolescence';
  static const menstruation = 'Menstruation';
  static const pregnancy = 'Pregnancy';
  static const postpartum = 'Postpartum';
  static const perimenopause = 'Perimenopause';
  static const menopause = 'Menopause';

  static const all = <String>[
    adolescence,
    menstruation,
    pregnancy,
    postpartum,
    perimenopause,
    menopause,
  ];

  static const _legacy = <String, String>{
    'reproductive years': menstruation,
    'menstruating': menstruation,
  };

  /// Returns the canonical stage name, or null if unknown.
  static String? normalize(String? value) {
    if (value == null) return null;
    final cleaned = value.trim().toLowerCase();
    if (cleaned.isEmpty) return null;
    for (final stage in all) {
      if (stage.toLowerCase() == cleaned) return stage;
    }
    return _legacy[cleaned];
  }
}
