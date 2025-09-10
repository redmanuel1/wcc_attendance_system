import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wcc_attendance_system/app_state.dart';
import 'package:wcc_attendance_system/main.dart';
import 'package:wcc_attendance_system/pages/OfflineQueue.dart';
import 'package:uuid/uuid.dart';

class FormPage extends StatefulWidget {
  const FormPage({Key? key}) : super(key: key);

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _purposes = [
    'Local Flight',
    'Cross Country Flight',
    'Taxi',
    'Other Ramp Activity',
  ];

  String? _selectedPurpose;
  final TextEditingController _otherPurposeController = TextEditingController();
  final List<TextEditingController> _companionsControllers = [TextEditingController()];
  bool _submitting = false;

  @override
  void dispose() {
    _otherPurposeController.dispose();
    for (var c in _companionsControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveFormData() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final docId = AppState().documentID;
    if (docId == null || docId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You appear to be logged out. Please log in first.')),
      );
      setState(() => _submitting = false);
      return;
    }

    final purpose = _selectedPurpose == 'Other Ramp Activity'
        ? _otherPurposeController.text.trim()
        : (_selectedPurpose ?? '');

    final companions = _companionsControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final uuid = const Uuid().v4();
    final now = DateTime.now();

    // always save to Hive first
    final offlineData = {
      'uuid': uuid,
      'companions': companions,
      'login': now.toIso8601String(),
      'logout': null,
      'purpose': purpose,
      'docId': docId,
      'txnId': null, // 🔄 will be set if uploaded online
    };

    await OfflineQueue.addTransaction(offlineData);

    // then try Firestore if online
    final online = await _hasInternet();
    if (online) {
      try {
        final docRef = await FirebaseFirestore.instance
            .collection('Users')
            .doc(docId)
            .collection('Transactions')
            .add({
          'companions': companions,
          'login': now,
          'logout': null,
          'purpose': purpose,
        });

        // update Hive record with txnId + synced flag
        final updatedData = Map<String, dynamic>.from(offlineData);
        updatedData['txnId'] = docRef.id;
        updatedData['synced'] = true;
        await OfflineQueue.updateTransactionByUuid(uuid, updatedData);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction saved!')),
        );
      } catch (e) {
        debugPrint('Firestore write failed: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sync online. Saved locally.')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data saved on device. Please login again')),
      );
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation(initialIndex: 0)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Please fill out the form", style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.blue),
        centerTitle: true,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text("Purpose", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPurpose,
                items: _purposes
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (newValue) => setState(() => _selectedPurpose = newValue),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Please select a purpose' : null,
              ),
              const SizedBox(height: 16),
              if (_selectedPurpose == 'Other Ramp Activity') ...[
                const Text("If Others, Please specify",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _otherPurposeController,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  validator: (value) {
                    if (_selectedPurpose == 'Other Ramp Activity' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Please specify your purpose';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              const Text("Companions", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._companionsControllers.map((controller) {
                final index = _companionsControllers.indexOf(controller);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Companion ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: () =>
                    setState(() => _companionsControllers.add(TextEditingController())),
                child: const Row(
                  children: [
                    Icon(Icons.add_circle, size: 25),
                    SizedBox(width: 4),
                    Text('Tap to add more companions', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting ? null : () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _saveFormData();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Please fill in all required fields')),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text("Submit", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
