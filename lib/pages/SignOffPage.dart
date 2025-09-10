import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wcc_attendance_system/app_state.dart';
import 'package:wcc_attendance_system/pages/login_page.dart';

class SignOffPage extends StatelessWidget {
  final appState = AppState();

  void _clearAppState() {
    appState.loginTime = null;
    appState.transactionId = null;
    appState.documentID = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'You are now logging off from your current session.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                if (appState.loginTime != null)
                  Text(
                    'Log in date and time: ${DateFormat('MM/dd/yyyy\ny hh:mma').format(appState.loginTime!)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                SizedBox(height: 8),
                Text(
                  'Press Log out button to proceed',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 30),
                Icon(Icons.access_time, size: 80, color: Colors.purple),
                SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () async {
                    // if (appState.transactionId == null || appState.documentID == null) {
                    //   _clearAppState();
                    //   Navigator.of(context).pushAndRemoveUntil(
                    //     MaterialPageRoute(builder: (context) => const LoginPage()),
                    //     (route) => false,
                    //   );
                    // }else{
                    //   await FirebaseFirestore.instance
                    //     .collection('Users')
                    //     .doc(appState.documentID)
                    //     .collection('Transactions')
                    //     .doc(appState.transactionId)
                    //     .update({
                    //   'logout': DateTime.now(),
                    // });

                    // _clearAppState();
                    // Navigator.of(context).pushAndRemoveUntil(
                    //         MaterialPageRoute(builder: (context) => const LoginPage()),
                    //         (route) => false,
                    //       );
                    
                    // }
                     _clearAppState();
                    Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                            (route) => false,
                          );
                  },

                    
                  child: Text('Log out', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
