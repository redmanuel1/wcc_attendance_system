import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wcc_attendance_system/app_state.dart';
import 'package:wcc_attendance_system/pages/OfflineQueue.dart';
import 'package:wcc_attendance_system/pages/SyncService.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  File? _pickedImage;
  bool _uploading = false;


  Future<void> _handleRefresh() async {
    final results = await Connectivity().checkConnectivity();
    final isOnline = results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.mobile);

    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
      return;
    }

    await SyncService().syncOfflineData();
    setState(() {});
  }

  String formatDateTime(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('MM/dd/yyyy h:mm a').format(value.toDate());
    }
    if (value is DateTime) {
      return DateFormat('MM/dd/yyyy h:mm a').format(value);
    }
    if (value is String) {
      return DateFormat('MM/dd/yyyy h:mm a').format(DateTime.parse(value));
    }
    return 'N/A';
  }

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('MM/dd/yyyy').format(value.toDate());
    }
    if (value is DateTime) {
      return DateFormat('MM/dd/yyyy').format(value);
    }
    if (value is String) {
      return DateFormat('MM/dd/yyyy').format(DateTime.parse(value));
    }
    return 'Invalid Date';
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _pickedImage = File(picked.path);
      _uploading = true;
    });

    try {
      final idNo = AppState().idNo;
      final userDocId = AppState().documentID;

      final ref = FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .child('$idNo.jpg');
      await ref.putFile(_pickedImage!);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userDocId)
          .update({'photoUrl': url});
      setState(() => _uploading = false);
    } catch (e) {
      setState(() => _uploading = false);
      debugPrint('Upload failed: $e');
    }
  }

  Future<void> _logoutTransaction(Map<String, dynamic> tx) async {
    if (tx['isOffline'] == true) {
      final allTx = OfflineQueue.getAllTransactions();
      final index = allTx.indexWhere((t) => t['uuid'] == tx['uuid']);
      if (index != -1) {
        allTx[index]['logout'] = DateTime.now().toIso8601String();
        final box = Hive.box(OfflineQueue.boxName);
        await box.putAt(index, allTx[index]);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline logout recorded')),
        );
      }
    } else {
      try {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(AppState().documentID)
            .collection('Transactions')
            .doc(tx['id'])
            .update({'logout': Timestamp.now()});
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logout recorded successfully')),
        );
      } catch (e) {
        debugPrint('Logout failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to record logout')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final idNo = AppState().idNo;
    final firstName = AppState().firstName;
    final lastName = AppState().lastName;
    final course = AppState().course;
    final userDocId = AppState().documentID;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'RAMPGUARD',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage: _pickedImage != null
                            ? FileImage(_pickedImage!)
                            : null,
                        child: _pickedImage == null
                            ? const Icon(Icons.account_circle,
                                size: 80, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickAndUploadImage,
                          child: const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.edit, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_uploading)
                    const Padding(
                      padding: EdgeInsets.all(4),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  Text('$firstName $lastName',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text('$idNo', style: const TextStyle(color: Colors.white70)),
                  Text('$course',
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Recent Activity',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Users')
                      .doc(userDocId)
                      .collection('Transactions')
                      .orderBy('login', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final firestoreDocs = snapshot.data?.docs ?? [];
                    final offlineDocs = OfflineQueue.getAllTransactions();

                    final unsyncedOfflineList =
                        offlineDocs.where((tx) => tx['synced'] != true).map((tx) {
                      return {
                        'uuid': tx['uuid'],
                        'id': null,
                        'purpose': tx['purpose'] ?? 'Unknown Activity',
                        'login': tx['login'],
                        'logout': tx['logout'],
                        'companions':
                            List<String>.from(tx['companions'] ?? []),
                        'isOffline': true,
                      };
                    }).toList();

                    final onlineList = firestoreDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return {
                        'id': doc.id,
                        'purpose': data['purpose'] ?? 'Unknown Activity',
                        'login': data['login'],
                        'logout': data['logout'],
                        'companions':
                            List<String>.from(data['companions'] ?? []),
                        'isOffline': false,
                      };
                    }).toList();

                    final allTransactions = [
                      ...unsyncedOfflineList,
                      ...onlineList
                    ];

                    if (allTransactions.isEmpty) {
                      return const Center(
                          child: Text('No recent activity.'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: allTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = allTransactions[index];
                        final purpose = tx['purpose'];
                        final login = tx['login'];
                        final logout = tx['logout'];
                        final companions =
                            List<String>.from(tx['companions']);
                        final loginDate = formatDateTime(login);
                        final logoutDate = logout != null
                            ? formatDateTime(logout)
                            : 'N/A';
                        final mainDate = formatDate(login);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            title: Text(
                              tx['isOffline']
                                  ? '$purpose (Pending Sync)'
                                  : purpose,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(mainDate),
                            children: [
                              if (login != null)
                                ListTile(
                                  title: const Text('Sign in',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(loginDate),
                                ),
                              if (companions.isNotEmpty)
                                ListTile(
                                  title: const Text('Companions',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(companions.join('\n')),
                                ),
                              if (logout != null)
                                ListTile(
                                  title: const Text('Sign off',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(logoutDate),
                                ),
                              if (logout == null)
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white),
                                    icon: const Icon(Icons.logout),
                                    label: const Text('Sign off'),
                                    onPressed: () => _logoutTransaction(tx),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
