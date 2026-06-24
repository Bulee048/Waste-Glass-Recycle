class SyncRecordResultModel {
  const SyncRecordResultModel({
    required this.supplierCode,
    required this.alreadySynced,
    required this.synced,
    required this.failed,
    this.reason,
  });

  final String supplierCode;
  final bool alreadySynced;
  final bool synced;
  final bool failed;
  final String? reason;

  factory SyncRecordResultModel.fromJson(Map<String, dynamic> json) {
    return SyncRecordResultModel(
      supplierCode: json['supplierCode'] as String,
      alreadySynced: json['alreadySynced'] as bool,
      synced: json['synced'] as bool,
      failed: json['failed'] as bool,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'supplierCode': supplierCode,
        'alreadySynced': alreadySynced,
        'synced': synced,
        'failed': failed,
        'reason': reason,
      };
}

class SyncResultModel {
  const SyncResultModel({
    required this.tripId,
    required this.allSynced,
    required this.results,
  });

  final int tripId;
  final bool allSynced;
  final List<SyncRecordResultModel> results;

  factory SyncResultModel.fromJson(Map<String, dynamic> json) {
    return SyncResultModel(
      tripId: json['tripId'] as int,
      allSynced: json['allSynced'] as bool,
      results: (json['results'] as List<dynamic>)
          .map(
            (e) => SyncRecordResultModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'tripId': tripId,
        'allSynced': allSynced,
        'results': results.map((r) => r.toJson()).toList(),
      };
}
