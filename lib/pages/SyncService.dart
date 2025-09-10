import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wcc_attendance_system/pages/OfflineQueue.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  bool _isSyncing = false;

  Future<void> syncOfflineData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pending = OfflineQueue.getAllTransactions();

      for (final tx in pending) {
        final uuid = tx['uuid'];
        if (uuid == null) continue;

        final docId = tx['docId'];
        if (docId == null || docId.isEmpty) {
          await OfflineQueue.removeTransactionByUuid(uuid);
          continue;
        }

        DateTime loginDt =
            DateTime.tryParse(tx['login'] ?? '') ?? DateTime.now();
        DateTime? logoutDt;
        if (tx['logout'] != null && tx['logout'] != '') {
          logoutDt = DateTime.tryParse(tx['logout']);
        }

        try {
          final txnId = tx['txnId'];

          if (txnId != null && txnId.isNotEmpty) {
            // 🔄 Update existing Firestore transaction
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(docId)
                .collection('Transactions')
                .doc(txnId)
                .update({
              'companions': tx['companions'] ?? [],
              'login': loginDt,
              'logout': logoutDt,
              'purpose': tx['purpose'] ?? '',
            });
          } else {
            // ➕ Create new Firestore transaction
            final docRef = await FirebaseFirestore.instance
                .collection('Users')
                .doc(docId)
                .collection('Transactions')
                .add({
              'companions': tx['companions'] ?? [],
              'login': loginDt,
              'logout': logoutDt,
              'purpose': tx['purpose'] ?? '',
            });

            // save txnId back into Hive
            final newTx = Map<String, dynamic>.from(tx);
            newTx['txnId'] = docRef.id;
            await OfflineQueue.updateTransactionByUuid(uuid, newTx);
          }

          await OfflineQueue.removeTransactionByUuid(uuid);
        } catch (e) {
          break;
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<Map<String, dynamic>?> getActiveTransactionOnline(String docId) async {
  final query = await FirebaseFirestore.instance
      .collection('Users')
      .doc(docId)
      .collection('Transactions')
      .where('logout', isNull: true)
      .limit(1)
      .get();

  if (query.docs.isNotEmpty) {
    return query.docs.first.data();
  }
  return null;
}

Future<bool> hasActiveTransaction(String docId) async {
  final local = await OfflineQueue.getActiveTransaction(docId);

  if (local != null) {
    final txnId = local['txnId'];
    if (txnId != null) {
      final online = await FirebaseFirestore.instance
          .collection('Users')
          .doc(docId)
          .collection('Transactions')
          .doc(txnId)
          .get();

      if (online.exists && online.data()?['logout'] != null) {
        // Firestore already logged out, so clear stale offline record
        await OfflineQueue.removeTransactionByUuid(local['uuid']);
        return false;
      }
    }
    return true; // only true if Firestore still agrees it's active
  }

  final online = await getActiveTransactionOnline(docId);
  return online != null;
}


}
