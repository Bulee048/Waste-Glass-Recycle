import 'package:dio/dio.dart';

import '../models/collection_request_model.dart';
import '../models/collection_result_model.dart';
import '../models/sync_record_model.dart';
import '../models/sync_result_model.dart';
import '../models/trip_report_model.dart';
import '../models/trip_summary_model.dart';
import 'api_exception.dart';

class ApiService {
  ApiService({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? apiBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: const {'Content-Type': 'application/json'},
              ),
            );

  /// Android emulator: `10.0.2.2` maps to the host machine's `localhost`.
  /// Physical device on the same Wi‑Fi: use your PC's LAN IP, e.g. `http://192.168.1.42:5000`.
  static const String apiBaseUrl = 'https://waste-glass-recycle-production.up.railway.app';

  final Dio _dio;

  Future<TripSummaryModel> getTodayTrip() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/trips/today');
      return TripSummaryModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e, 'Failed to load today\'s trip');
    }
  }

  Future<CollectionResultModel> submitCollection(
    CollectionRequestModel request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/collections',
        data: request.toJson(),
      );
      return CollectionResultModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e, 'Failed to submit collection');
    }
  }

  Future<TripReportModel> getTripReport(int tripId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/trips/$tripId/report',
      );
      return TripReportModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e, 'Failed to load trip report');
    }
  }

  Future<SyncResultModel> syncTrip(
    int tripId,
    List<CollectionRequestModel> records, {
    List<DateTime>? collectedAtUtcValues,
  }) async {
    final syncRecords = <SyncRecordModel>[];
    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      syncRecords.add(
        SyncRecordModel(
          supplierCode: record.supplierCode,
          clearKg: record.clearKg,
          colouredKg: record.colouredKg,
          condition: record.condition,
          collectedAtUtc: collectedAtUtcValues != null &&
                  i < collectedAtUtcValues.length
              ? collectedAtUtcValues[i].toUtc()
              : DateTime.now().toUtc(),
        ),
      );
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/trips/$tripId/sync',
        data: {
          'tripId': tripId,
          'records': syncRecords.map((r) => r.toJson()).toList(),
        },
      );
      return SyncResultModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e, 'Failed to sync trip');
    }
  }

  Future<SyncResultModel> syncTripWithTimestamps(
    int tripId,
    List<SyncRecordModel> records,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/trips/$tripId/sync',
        data: {
          'tripId': tripId,
          'records': records.map((r) => r.toJson()).toList(),
        },
      );
      return SyncResultModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e, 'Failed to sync trip');
    }
  }

  ApiException _toApiException(DioException error, String fallback) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['error'] as String? ?? data['message'] as String?;
      if (message != null && message.isNotEmpty) {
        return ApiException(message, statusCode: statusCode);
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        'Request timed out. Check that the API is running and reachable.',
        statusCode: statusCode,
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return ApiException(
        'Cannot reach the server at $apiBaseUrl. '
        'On a physical device, set apiBaseUrl to your PC\'s LAN IP.',
        statusCode: statusCode,
      );
    }

    return ApiException(
      error.message ?? fallback,
      statusCode: statusCode,
    );
  }
}
