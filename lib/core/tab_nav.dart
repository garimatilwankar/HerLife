import 'package:flutter/foundation.dart';

/// Change the bottom tab from anywhere: TabNav.index.value = 1;
/// 0 Home, 1 Track, 2 Wellness, 3 Learn, 4 Settings.
class TabNav {
  static final ValueNotifier<int> index = ValueNotifier<int>(0);
}