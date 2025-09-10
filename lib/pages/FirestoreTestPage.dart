import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreTestPage extends StatelessWidget {
  const FirestoreTestPage({super.key});

  Future<void> fetchAndLogData() async {
    final idNo = "12345"; // string
    debugPrint('Fetching user data for idNo: $idNo');

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('idNo', isEqualTo: idNo)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('No user found for idNo: $idNo');
        return;
      }

      for (var userDoc in querySnapshot.docs) {
        debugPrint('User Document ID: ${userDoc.id}');
        debugPrint('User Data: ${userDoc.data()}');

        final transactionsSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(userDoc.id)
            .collection('Transactions')
            .get();

        if (transactionsSnapshot.docs.isEmpty) {
          debugPrint('No transactions found for this user.');
        } else {
          debugPrint('Transactions for user ${userDoc.id}:');
          for (var tx in transactionsSnapshot.docs) {
            debugPrint('Transaction ID: ${tx.id}');
            debugPrint('Transaction Data: ${tx.data()}');
          }
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Firestore Query')),
      body: Center(
        child: ElevatedButton(
          onPressed: fetchAndLogData,
          child: const Text('Fetch User & Transactions'),
        ),
      ),
    );
  }
}
