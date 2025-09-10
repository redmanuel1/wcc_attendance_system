import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wcc_attendance_system/pages/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final idNoController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final courseController = TextEditingController();

  bool isLoading = false;

  Future<String?> checkExistingUser(String idNo, String username) async {
    final idQuery = await FirebaseFirestore.instance
        .collection("Users")
        .where("idNo", isEqualTo: idNo)
        .get();

    if (idQuery.docs.isNotEmpty) return "ID Number is already registered";

    final usernameQuery = await FirebaseFirestore.instance
        .collection("Users")
        .where("username", isEqualTo: username)
        .get();

    if (usernameQuery.docs.isNotEmpty) return "Username is already taken";

    return null;
  }

  void registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final errorMessage = await checkExistingUser(
        idNoController.text.trim(),
        usernameController.text.trim(),
      );

      if (errorMessage != null) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        return;
      }

      await FirebaseFirestore.instance.collection("Users").add({
        "idNo": idNoController.text.trim(),
        "firstName": firstNameController.text.trim(),
        "lastName": lastNameController.text.trim(),
        "username": usernameController.text.trim(),
        "password": passwordController.text.trim(),
        "Course": courseController.text.trim(),
      });

      setState(() => isLoading = false);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Success"),
          content: const Text("Account created successfully!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 30),

                TextFormField(
                  controller: idNoController,
                  decoration: const InputDecoration(
                    labelText: "ID Number",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val!.isEmpty ? "Enter your ID Number" : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                    labelText: "First Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val!.isEmpty ? "Enter your First Name" : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                    labelText: "Last Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val!.isEmpty ? "Enter your Last Name" : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: courseController,
                  decoration: const InputDecoration(
                    labelText: "Course",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val!.isEmpty ? "Enter your Course" : null,
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: "Username",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val!.isEmpty ? "Enter a Username" : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val!.length < 6
                      ? "Password must be at least 6 chars"
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Confirm Password",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val!.isEmpty ? "Confirm your Password" : null,
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Register",
                            style:
                                TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
