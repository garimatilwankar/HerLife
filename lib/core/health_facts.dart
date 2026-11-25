import 'package:herlife/core/stages.dart';

/// Short facts shown on Home. One new fact each day.
/// Write new ones in your own words from trusted sources (ACOG, NHS, WHO).
class HealthFacts {
  static const _general = <String>[
    'Cycle length is counted from the first day of one period to the first day of the next.',
    'Stress and changes in sleep can shift when a period arrives.',
    'Gentle movement like walking or stretching can ease cramps for many people.',
    'Drinking enough water and sleeping well can make period symptoms feel easier.',
    'Lentils, chickpeas and leafy greens are good iron-rich foods.',
  ];

  static const _byStage = <String, List<String>>{
    LifeStages.adolescence: [
      'In the first years after periods begin, cycles can be irregular. This is common while hormones settle.',
      'Teen cycles can be anywhere from 21 to 45 days in the first years.',
      'Most people get their first period between ages 10 and 15.',
      'Calcium builds strong bones in the teen years. Milk, curd, ragi and sesame are good sources.',
      'Changing your pad every few hours keeps you comfortable and fresh.',
    ],
    LifeStages.menstruation: [
      'Your cycle has four phases: menstrual, follicular, ovulation and luteal.',
      'Ovulation usually happens about 14 days before the next period, not always on day 14.',
      'Tracking a few cycles helps you see what is normal for you.',
      'A heat pack can ease cramps. If pain stops you from daily activities, talk to a doctor.',
      'Many people feel more energetic in the first half of the cycle.',
    ],
    LifeStages.pregnancy: [
      'Folic acid is recommended before and in early pregnancy. Your doctor will guide you on supplements.',
      'Staying hydrated can help with tiredness and constipation during pregnancy.',
      'Regular check-ups let your doctor follow your health and your baby\'s growth.',
      'Gentle walking is fine for many pregnancies. Check with your doctor first.',
      'Most people first feel baby movements between 18 and 25 weeks.',
    ],
    LifeStages.postpartum: [
      'Bleeding after birth can last several weeks. Tell your doctor if it suddenly becomes heavy.',
      'Feeling emotional in the first two weeks is common. If low mood lasts longer, please reach out for support.',
      'There is no deadline for feeling like yourself again. Rest when you can.',
      'Pelvic floor exercises can help recovery after birth.',
      'Drinking water and eating regularly helps your energy, especially while feeding.',
    ],
    LifeStages.perimenopause: [
      'Perimenopause often begins in the 40s. Cycles can get shorter, longer or skip.',
      'Hot flashes and sleep changes are common while hormones fluctuate.',
      'Strength training and weight-bearing exercise help protect your bones.',
      'A cool bedroom and slow cooling breaths can help with night sweats.',
      'Pregnancy is still possible during perimenopause.',
    ],
    LifeStages.menopause: [
      'Menopause is confirmed after 12 months without a period.',
      'Calcium, vitamin D and weight-bearing exercise support bone health.',
      'Any bleeding after menopause should be checked by a doctor.',
      'Walking, balanced meals and regular blood pressure checks support heart health.',
      'A fixed bedtime and less screen time can help you sleep better.',
    ],
  };

  /// The fact for today. The same fact all day, a new one tomorrow.
  static String forToday(String? stage, DateTime today) {
    final pool = <String>[
      ...(_byStage[LifeStages.normalize(stage)] ?? const <String>[]),
      ..._general,
    ];
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;
    return pool[dayOfYear % pool.length];
  }
}