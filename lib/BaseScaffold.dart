import 'package:flutter/material.dart';

class BaseScaffold extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Widget child;

  const BaseScaffold({
    required this.currentIndex,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        selectedItemColor: Colors.blue,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: ''),
        ],
      ),
    );
  }
}
