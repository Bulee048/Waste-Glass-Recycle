import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trip_summary_model.dart';
import 'app_providers.dart';

/// Shared trip state for Screen 1 and post-collection refresh on other screens.
final tripProvider = FutureProvider<TripSummaryModel>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getTodayTrip();
});
