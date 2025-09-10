import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wcc_attendance_system/app_state.dart';
import 'package:wcc_attendance_system/main.dart';
import 'package:wcc_attendance_system/pages/FirestoreTestPage.dart';
import 'package:wcc_attendance_system/pages/RegisterPage.dart';
import 'package:wcc_attendance_system/pages/homepage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  void loginUser() async {
    setState(() => isLoading = true);

    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    final query = await FirebaseFirestore.instance
        .collection('Users')
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .get();

    setState(() => isLoading = false);

    if (query.docs.isNotEmpty) {
      final docSnapshot = query.docs.first;
      final userData = docSnapshot.data();
      AppState().idNo = userData['idNo'];
      AppState().documentID = docSnapshot.id;
      AppState().firstName = userData['firstName'];
      AppState().lastName = userData['lastName'];
      AppState().course = userData['Course'];
      AppState().loginTime = DateTime.now();

// Don't set transactionId here, first transaction hasn't been created yet

      await AppState().saveState();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) =>  MainNavigation()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'RAMPGUARD',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              Image.asset(
                'assets/logo.png',
                height: 150,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  hintText: 'Username',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Login',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              TextButton(
                onPressed: () {
                             Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterPage()),
                            );

                    },
                child: const Text(
                  'Register',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
