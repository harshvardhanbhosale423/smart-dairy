import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  static const String _dbFileName = 'smart_dairy_local_db.json';
  File? _dbFile;
  bool _initialized = false;

  // In-memory collections: collectionName -> (docId -> dataMap)
  final Map<String, Map<String, Map<String, dynamic>>> _data = {};

  // Stream controllers for each collection
  final Map<String, StreamController<List<Map<String, dynamic>>>> _controllers = {};

  StreamController<List<Map<String, dynamic>>> _getController(String collection) {
    if (!_controllers.containsKey(collection) || _controllers[collection]!.isClosed) {
      _controllers[collection] = StreamController<List<Map<String, dynamic>>>.broadcast();
    }
    return _controllers[collection]!;
  }

  /// Initialize local database from disk
  Future<void> init() async {
    if (_initialized) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      _dbFile = File('${dir.path}/$_dbFileName');

      if (await _dbFile!.exists()) {
        final content = await _dbFile!.readAsString();
        if (content.trim().isNotEmpty) {
          final decoded = jsonDecode(content) as Map<String, dynamic>;
          decoded.forEach((colKey, colVal) {
            _data[colKey] = {};
            if (colVal is Map<String, dynamic>) {
              colVal.forEach((docKey, docVal) {
                if (docVal is Map<String, dynamic>) {
                  final deserialized = _deserializeMap(docVal);
                  if (colKey == 'dairy_profiles' &&
                      (deserialized['ownerUpiId'] == 'harshvardhan@upi' ||
                          deserialized['ownerUpiId'] == 'owner@upi')) {
                    deserialized['ownerUpiId'] = '';
                  }
                  _data[colKey]![docKey] = deserialized;
                }
              });
            }
          });
        }
      } else {
        // First launch: create empty file and seed default demo data
        await _seedDefaultData();
        await _persistToDisk();
      }
    } catch (e) {
      debugPrint('LocalDatabase init error: $e');
      if (_data.isEmpty) {
        await _seedDefaultData();
      }
    } finally {
      _initialized = true;
    }
  }

  /// Pre-seed default owner and dairy profile so app is ready out of the box
  Future<void> _seedDefaultData() async {
    const defaultOwnerId = 'owner_default_1';

    // 1. Default Dairy Profile
    _data['dairy_profiles'] = {
      defaultOwnerId: {
        'id': defaultOwnerId,
        'ownerId': defaultOwnerId,
        'dairyName': 'भोसले दूध डेअरी (Smart Dairy)',
        'ownerName': 'हर्षवर्धन भोसले',
        'ownerPhone': '9822000000',
        'ownerUpiId': '',
        'accountHolderName': 'हर्षवर्धन भोसले',
        'cowsOwned': 10,
        'defaultMilkRate': 60.0,
        'address': 'पुणे, महाराष्ट्र',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      }
    };

    // 2. Default Owner User
    _data['users'] = {
      defaultOwnerId: {
        'uid': defaultOwnerId,
        'phone': '9822000000',
        'username': 'harshvardhan',
        'password': 'password123',
        'role': 'owner',
        'status': 'approved',
        'name': 'हर्षवर्धन भोसले',
        'dairyId': defaultOwnerId,
        'createdAt': Timestamp.now(),
      }
    };

    _data['customers'] = {};
    _data['milk_entries'] = {};
    _data['customer_ledgers'] = {};
    _data['monthly_bills'] = {};
    _data['payments'] = {};
    _data['expenses'] = {};
    _data['audit_logs'] = {};
  }

  /// Persist entire database asynchronously to local disk
  Future<void> _persistToDisk() async {
    try {
      if (_dbFile == null) {
        final dir = await getApplicationDocumentsDirectory();
        _dbFile = File('${dir.path}/$_dbFileName');
      }

      final serializable = <String, dynamic>{};
      _data.forEach((colKey, colMap) {
        serializable[colKey] = {};
        colMap.forEach((docKey, docVal) {
          serializable[colKey][docKey] = _serializeMap(docVal);
        });
      });

      final jsonString = jsonEncode(serializable);
      await _dbFile!.writeAsString(jsonString, flush: true);
    } catch (e) {
      debugPrint('LocalDatabase persist error: $e');
    }
  }

  /// Convert complex values (Timestamps, Dates) into JSON serializable structures
  Map<String, dynamic> _serializeMap(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    map.forEach((k, v) {
      if (v is Timestamp) {
        result[k] = {'_is_timestamp_': true, 'millis': v.millisecondsSinceEpoch};
      } else if (v is DateTime) {
        result[k] = {'_is_timestamp_': true, 'millis': v.millisecondsSinceEpoch};
      } else if (v is Map<String, dynamic>) {
        result[k] = _serializeMap(v);
      } else if (v is List) {
        result[k] = v.map((item) => item is Map<String, dynamic> ? _serializeMap(item) : item).toList();
      } else {
        result[k] = v;
      }
    });
    return result;
  }

  /// Re-convert serialized values back into Timestamps
  Map<String, dynamic> _deserializeMap(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    map.forEach((k, v) {
      if (v is Map && v['_is_timestamp_'] == true && v['millis'] != null) {
        result[k] = Timestamp.fromMillisecondsSinceEpoch(v['millis'] as int);
      } else if (v is Map<String, dynamic>) {
        result[k] = _deserializeMap(v);
      } else if (v is List) {
        result[k] = v.map((item) => item is Map<String, dynamic> ? _deserializeMap(item) : item).toList();
      } else {
        result[k] = v;
      }
    });
    return result;
  }

  /// Notify stream listeners for a collection
  void _notifyCollection(String collection) {
    if (_controllers.containsKey(collection)) {
      final list = getAll(collection);
      _controllers[collection]!.add(list);
    }
  }

  // -------------------------------------------------------------
  // GENERIC CRUD METHODS
  // -------------------------------------------------------------

  /// Get document by ID
  Map<String, dynamic>? get(String collection, String docId) {
    if (!_data.containsKey(collection)) return null;
    final doc = _data[collection]![docId];
    if (doc == null) return null;
    return Map<String, dynamic>.from(doc);
  }

  /// Get all documents in collection
  List<Map<String, dynamic>> getAll(String collection) {
    if (!_data.containsKey(collection)) return [];
    return _data[collection]!.values.map((d) => Map<String, dynamic>.from(d)).toList();
  }

  /// Set or replace document
  Future<void> set(String collection, String docId, Map<String, dynamic> data) async {
    if (!_data.containsKey(collection)) {
      _data[collection] = {};
    }

    final docData = Map<String, dynamic>.from(data);
    docData['id'] ??= docId;
    _data[collection]![docId] = docData;

    _notifyCollection(collection);
    await _persistToDisk();
  }

  /// Update document fields
  Future<void> update(String collection, String docId, Map<String, dynamic> updateFields) async {
    if (!_data.containsKey(collection) || !_data[collection]!.containsKey(docId)) {
      await set(collection, docId, updateFields);
      return;
    }

    final current = _data[collection]![docId]!;
    updateFields.forEach((k, v) {
      current[k] = v;
    });

    _notifyCollection(collection);
    await _persistToDisk();
  }

  /// Delete document
  Future<void> delete(String collection, String docId) async {
    if (_data.containsKey(collection)) {
      _data[collection]!.remove(docId);
      _notifyCollection(collection);
      await _persistToDisk();
    }
  }

  /// Query documents matching condition
  List<Map<String, dynamic>> query(
    String collection, {
    bool Function(Map<String, dynamic>)? where,
  }) {
    final all = getAll(collection);
    if (where == null) return all;
    return all.where(where).toList();
  }

  /// Stream of documents matching condition
  Stream<List<Map<String, dynamic>>> stream(
    String collection, {
    bool Function(Map<String, dynamic>)? where,
  }) {
    final controller = _getController(collection);
    // Initial emit
    Future.microtask(() {
      final initial = query(collection, where: where);
      if (!controller.isClosed) {
        controller.add(initial);
      }
    });

    return controller.stream.map((list) {
      if (where == null) return list;
      return list.where(where).toList();
    });
  }
}
