import 'package:flutter/material.dart';
import 'package:herlife/screens/tabs/ui.dart';
import 'package:herlife/widgets/herlife_header.dart';

class WellnessTab extends StatelessWidget {
  const WellnessTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            HerLifeHeader(subtitle: 'Wellness'),
            SizedBox(height: 20),
            AppCard(child: Text('Move, Eat and Calm are coming next.')),
          ],
        ),
      ),
    );
  }
}