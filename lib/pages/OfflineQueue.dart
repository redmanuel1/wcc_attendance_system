import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class OfflineQueue {
  static const String boxName = 'offlineData';

  // ValueNotifier to allow UI to react to changes
  static final ValueNotifier<List<Map<String, dynamic>>> notifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  /// Call once at app start after opening the Hive box
  static void init() {
    notifier.value = getAllTransactions();
  }

  /// Add a new transaction
  static Future<void> addTransaction(Map<String, dynamic> data) async {
    final box = Hive.box(boxName);
    await box.add(data);
    notifier.value = getAllTransactions();
  }

  /// Get all transactions
  static List<Map<String, dynamic>> getAllTransactions() {
    final box = Hive.box(boxName);
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// Remove a transaction by index
  static Future<void> removeTransaction(int index) async {
    final box = Hive.box(boxName);
    if (index >= 0 && index < box.length) {
      await box.deleteAt(index);
      notifier.value = getAllTransactions();
    }
  }

  /// Remove by uuid (recommended)
  static Future<void> removeTransactionByUuid(String uuid) async {
    final box = Hive.box(boxName);
    final values = box.values.toList();
    for (int i = 0; i < values.length; i++) {
      final tx = Map<String, dynamic>.from(values[i] as Map);
      if (tx['uuid'] == uuid) {
        await box.deleteAt(i);
        notifier.value = getAllTransactions();
        return;
      }
    }
  }

  /// Update a transaction by index (keeps existing behavior)
  static Future<void> updateTransaction(int index, Map<String, dynamic> newData) async {
    final box = Hive.box(boxName);
    if (index >= 0 && index < box.length) {
      await box.putAt(index, newData);
      notifier.value = getAllTransactions();
    }
  }

  /// Update transaction by uuid (merges fields into existing map)
  static Future<void> updateTransactionByUuid(String uuid, Map<String, dynamic> newData) async {
    final box = Hive.box(boxName);
    final values = box.values.toList();
    for (int i = 0; i < values.length; i++) {
      final tx = Map<String, dynamic>.from(values[i] as Map);
      if (tx['uuid'] == uuid) {
        // merge: keep existing keys not overwritten, overwrite keys provided in newData
        tx.addAll(newData);
        await box.putAt(i, tx);
        notifier.value = getAllTransactions();
        return;
      }
    }
  }

  /// Clear all transactions
  static Future<void> clearAll() async {
    final box = Hive.box(boxName);
    await box.clear();
    notifier.value = getAllTransactions();
  }

  /// Find the index of a transaction by its UUID
  static int indexOfTransaction(String uuid) {
    final box = Hive.box(boxName);
    final values = box.values.toList();
    for (int i = 0; i < values.length; i++) {
      final tx = Map<String, dynamic>.from(values[i] as Map);
      if (tx['uuid'] == uuid) return i;
    }
    return -1;
  }

  static Future<Map<String, dynamic>?> getActiveTransaction(String docId) async {
  final box = Hive.box(boxName);
  for (final tx in box.values) {
    if (tx['docId'] == docId && tx['logout'] == null) {
      return Map<String, dynamic>.from(tx);
    }
  }
  return null;
}


}
