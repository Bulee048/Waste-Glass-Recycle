import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/trip_sequence_screen.dart';

void main() {
  runApp(const ProviderScope(child: GlassCollectorApp()));
}

class GlassCollectorApp extends StatelessWidget {
  const GlassCollectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glass Collector',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const TripSequenceScreen(),
    );
  }
}
