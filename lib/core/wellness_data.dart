/// Content for the Wellness tab. Edit this file to add routines or recipes.
/// No calories, no weight talk: teen-safe by design.

class MoveRoutine {
  final String title;
  final String tag;
  final int minutes;
  final String blurb;
  final String query; // what to search on YouTube

  const MoveRoutine(this.title, this.tag, this.minutes, this.blurb, this.query);
}

class Recipe {
  final String name;
  final String why;
  final String time;
  final String ingredients;
  final String how;
  final Set<String> diets; // diets this suits
  final Set<String> allergens; // allergens it contains

  const Recipe({
    required this.name,
    required this.why,
    required this.time,
    required this.ingredients,
    required this.how,
    required this.diets,
    this.allergens = const {},
  });
}

class WellnessData {
  static const moveTags = ['All', 'Cramps', 'Posture', 'Strength', 'Mood', 'Sleep'];

  static const routines = <MoveRoutine>[
    MoveRoutine('Cramp relief stretches', 'Cramps', 10,
        'Slow stretches that can ease period cramps.',
        'gentle yoga for period cramps beginners 10 minutes'),
    MoveRoutine('Child pose and hip openers', 'Cramps', 8,
        'Soft poses for lower back and tummy comfort.',
        'yoga for menstrual cramps child pose hip opener'),
    MoveRoutine('Posture reset', 'Posture', 7,
        'Fix a stiff neck and shoulders from study and phone time.',
        'posture exercises for teens neck shoulders 7 minutes'),
    MoveRoutine('Beginner strength', 'Strength', 15,
        'Squats, lunges and planks with no equipment.',
        'beginner bodyweight strength workout for teens no equipment'),
    MoveRoutine('Dance break', 'Mood', 10,
        'Fun movement to lift your mood.',
        'easy dance workout for teens fun 10 minutes'),
    MoveRoutine('Stress relief yoga', 'Mood', 12,
        'Calm your mind before or after exams.',
        'yoga for stress and anxiety for teens'),
    MoveRoutine('Bedtime stretch', 'Sleep', 8,
        'Wind down your body so you sleep better.',
        'bedtime stretching routine for better sleep beginners'),
  ];

  static const diets = ['Vegetarian', 'Eggetarian', 'Non-vegetarian', 'Vegan', 'Jain'];
  static const allergens = ['Nuts or peanuts', 'Dairy', 'Gluten (wheat)', 'Soy', 'Egg', 'Sesame'];

  static const _v = {'Vegetarian', 'Eggetarian', 'Non-vegetarian'};

  static const recipes = <Recipe>[
    Recipe(
      name: 'Ragi dosa with coconut chutney',
      why: 'Ragi is rich in calcium, good for growing bones.',
      time: '20 min',
      ingredients: 'Ragi flour, rice flour, curd or water, salt, coconut, green chilli.',
      how: 'Mix batter with water, rest 10 minutes, spread on a hot pan, serve with chutney.',
      diets: {..._v, 'Vegan'},
    ),
    Recipe(
      name: 'Chana chaat with lemon',
      why: 'Chickpeas give iron and protein.',
      time: '10 min',
      ingredients: 'Boiled chickpeas, tomato, cucumber, lemon, chaat masala.',
      how: 'Mix everything and squeeze lemon on top. Lemon helps your body absorb iron.',
      diets: {..._v, 'Vegan', 'Jain'},
    ),
    Recipe(
      name: 'Moong dal khichdi with vegetables',
      why: 'A light meal with iron and protein.',
      time: '30 min',
      ingredients: 'Rice, moong dal, carrot, peas, turmeric, salt.',
      how: 'Pressure cook everything with water until soft.',
      diets: {..._v, 'Vegan'},
    ),
    Recipe(
      name: 'Palak paneer with roti',
      why: 'Spinach has iron and paneer has calcium.',
      time: '30 min',
      ingredients: 'Spinach, paneer, tomato, spices, whole wheat roti.',
      how: 'Blend cooked spinach, simmer with spices, add paneer cubes.',
      diets: _v,
      allergens: {'Dairy', 'Gluten (wheat)'},
    ),
    Recipe(
      name: 'Egg bhurji with multigrain toast',
      why: 'Eggs give protein and iron.',
      time: '10 min',
      ingredients: 'Eggs, onion, tomato, turmeric, multigrain bread.',
      how: 'Scramble eggs with chopped vegetables and serve with toast.',
      diets: {'Eggetarian', 'Non-vegetarian'},
      allergens: {'Egg', 'Gluten (wheat)'},
    ),
    Recipe(
      name: 'Chicken and vegetable curry',
      why: 'Chicken gives protein and iron.',
      time: '40 min',
      ingredients: 'Chicken, onion, tomato, mixed vegetables, spices, roti or rice.',
      how: 'Cook the chicken with spices and vegetables until fully cooked through.',
      diets: {'Non-vegetarian'},
    ),
    Recipe(
      name: 'Sesame and jaggery laddoo',
      why: 'Sesame has calcium and jaggery has a little iron.',
      time: '15 min',
      ingredients: 'Roasted sesame seeds, jaggery, a little cardamom.',
      how: 'Melt jaggery, mix in sesame, shape into small balls while warm.',
      diets: {..._v, 'Vegan', 'Jain'},
      allergens: {'Sesame'},
    ),
    Recipe(
      name: 'Curd with fruit and seeds',
      why: 'Curd gives calcium and gut-friendly bacteria.',
      time: '5 min',
      ingredients: 'Curd, chopped fruit, pumpkin or sunflower seeds.',
      how: 'Mix and enjoy as a snack or breakfast.',
      diets: {..._v, 'Jain'},
      allergens: {'Dairy'},
    ),
    Recipe(
      name: 'Rajma rice',
      why: 'Kidney beans give iron and protein.',
      time: '45 min',
      ingredients: 'Rajma, rice, onion, tomato, spices.',
      how: 'Soak rajma overnight, pressure cook, simmer in masala, serve with rice.',
      diets: {..._v, 'Vegan'},
    ),
    Recipe(
      name: 'Roasted makhana',
      why: 'A light crunchy snack with some calcium.',
      time: '8 min',
      ingredients: 'Makhana (fox nuts), a little oil or ghee, salt, pepper.',
      how: 'Roast on a low flame until crisp, then season.',
      diets: {..._v, 'Vegan', 'Jain'},
    ),
    Recipe(
      name: 'Soya chunk pulao',
      why: 'Soya gives protein and iron.',
      time: '30 min',
      ingredients: 'Rice, soya chunks, peas, carrot, spices.',
      how: 'Soak soya chunks, then cook with rice and vegetables.',
      diets: {..._v, 'Vegan'},
      allergens: {'Soy'},
    ),
  ];

  /// Recipes that suit [diet] and contain none of [avoid].
  static List<Recipe> filter(String? diet, Set<String> avoid) {
    return recipes.where((r) {
      final dietOk = diet == null || r.diets.contains(diet);
      final safe = r.allergens.intersection(avoid).isEmpty;
      return dietOk && safe;
    }).toList();
  }
}