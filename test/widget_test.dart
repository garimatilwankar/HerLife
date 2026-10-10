import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herlife/main.dart';
import 'package:herlife/screens/tabs/ui.dart';
import 'package:herlife/services/auth_service.dart';

void main() {
  testWidgets('HerLifeApp builds and displays initial AppGate splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const HerLifeApp());

    // Verify MaterialApp title and AppGate splash elements
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(HerLifeSplashScreen), findsOneWidget);
    expect(find.text('Your health, your data, your journey.'), findsOneWidget);
  });

  testWidgets('WelcomeScreen renders action buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomeScreen(),
      ),
    );

    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });

  group('HerData Unit Tests', () {
    test('Default cycle calculations return expected defaults when empty', () {
      final data = HerData();
      expect(data.periods, isEmpty);
      expect(data.lengths, isEmpty);
      expect(data.avg, 28);
      expect(data.cycleDay, 0);
      expect(data.phase, 'No data');
      expect(data.last, isNull);
      expect(data.next, isNull);
    });

    test('Cycle length and phase calculations with single period entry', () {
      final data = HerData();
      final today = DateTime.now();
      data.periods = [DateTime(today.year, today.month, today.day)];

      expect(data.cycleDay, 1);
      expect(data.phase, 'Menstrual');
      expect(data.avg, 28);
    });

    test('AuthResult values', () {
      const success = AuthResult.success();
      expect(success.ok, isTrue);
      expect(success.error, isNull);

      const failure = AuthResult.failure('Invalid password');
      expect(failure.ok, isFalse);
      expect(failure.error, 'Invalid password');
    });
  });
}

