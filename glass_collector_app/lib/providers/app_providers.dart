import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import '../services/local_db_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final localDbServiceProvider = Provider<LocalDbService>((ref) => LocalDbService());
