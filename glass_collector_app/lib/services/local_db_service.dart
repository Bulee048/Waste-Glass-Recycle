// OFFLINE-FIRST COLLECTION RULE (read before changing Screen 2 logic):
//
// When the collector confirms a collection on Screen 2:
//   1. ALWAYS call LocalDbService.insertCollection() first — persist locally immediately.
//   2. THEN attempt ApiService.submitCollection().
//   3. If the API call succeeds, mark the local row synced (or rely on server state).
//   4. If the API call fails (no connectivity, timeout, etc.), leave synced = 0 and
//      continue to the next stop — do NOT block the user or show a hard error.
//      A quiet note that the record will sync later is enough.
//
// Trip report reads from getAllCollections(). Background / manual sync uses
// getUnsyncedCollections() + markSynced() after a successful POST /api/trips/{id}/sync.

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/collection_request_model.dart';

class LocalDbService {
  static const _dbName = 'glass_collector.db';
  static const _dbVersion = 2;
  static const _tablePendingCollections = 'pending_collections';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createPendingCollectionsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS collection_records');
          await _createPendingCollectionsTable(db);
        }
      },
    );
  }

  Future<void> _createPendingCollectionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_tablePendingCollections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        supplier_code TEXT NOT NULL,
        clear_kg REAL NOT NULL,
        coloured_kg REAL NOT NULL,
        condition TEXT NOT NULL,
        collected_at_utc TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Persists a collection locally as soon as the collector confirms on Screen 2.
  /// [collectedAtUtc] defaults to now if omitted. Returns the SQLite row id.
  Future<int> insertCollection(
    CollectionRequestModel record, {
    DateTime? collectedAtUtc,
  }) async {
    final db = await database;
    final timestamp = (collectedAtUtc ?? DateTime.now()).toUtc();

    return db.insert(
      _tablePendingCollections,
      {
        'trip_id': record.tripId,
        'supplier_code': record.supplierCode,
        'clear_kg': record.clearKg,
        'coloured_kg': record.colouredKg,
        'condition': record.condition,
        'collected_at_utc': timestamp.toIso8601String(),
        'synced': 0,
      },
    );
  }

  /// All locally stored collections (online and offline), newest first.
  Future<List<CollectionRequestModel>> getAllCollections() async {
    final db = await database;
    final rows = await db.query(
      _tablePendingCollections,
      orderBy: 'collected_at_utc ASC',
    );
    return rows.map(_mapRow).toList();
  }

  /// Collections not yet confirmed synced with the server (synced = 0).
  Future<List<CollectionRequestModel>> getUnsyncedCollections() async {
    final db = await database;
    final rows = await db.query(
      _tablePendingCollections,
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'collected_at_utc ASC',
    );
    return rows.map(_mapRow).toList();
  }

  Future<void> markSynced(int localId) async {
    final db = await database;
    await db.update(
      _tablePendingCollections,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// Removes all local records for a trip (handy between demo runs).
  Future<void> clearTrip(int tripId) async {
    final db = await database;
    await db.delete(
      _tablePendingCollections,
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
  }

  CollectionRequestModel _mapRow(Map<String, Object?> row) {
    return CollectionRequestModel(
      tripId: row['trip_id'] as int,
      supplierCode: row['supplier_code'] as String,
      clearKg: (row['clear_kg'] as num).toDouble(),
      colouredKg: (row['coloured_kg'] as num).toDouble(),
      condition: row['condition'] as String,
      localId: row['id'] as int,
      collectedAtUtc: DateTime.parse(row['collected_at_utc'] as String),
      synced: (row['synced'] as int) == 1,
    );
  }
}
