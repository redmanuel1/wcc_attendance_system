import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:wcc_attendance_system/app_state.dart';
import 'package:wcc_attendance_system/firebase_options.dart';
import 'package:wcc_attendance_system/pages/QRScannerPage.dart';
import 'package:wcc_attendance_system/pages/SignOffPage.dart';
import 'package:wcc_attendance_system/pages/homepage.dart';
import 'package:wcc_attendance_system/pages/login_page.dart';
import 'package:firebase_app_check/firebase_app_check.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // load saved login state
  await AppState().loadState();

  // initialize Hive for offline storage
  await Hive.initFlutter();
  await Hive.openBox('offlineData');

  // initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // activate Firebase App Check in debug for both Android & iOS
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // Android debug
    appleProvider: AppleProvider.debug,     // iOS debug
    webProvider: null,                       // optional for web
  );

  runApp(MyApp(
    isLoggedIn: AppState().documentID != null,
  ));
}

class MyApp extends StatelessWidget {
   final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login UI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 19, 98, 225)),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home:  isLoggedIn
          ? const MainNavigation(initialIndex: 1) // start on Homepage
          : const LoginPage(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  const MainNavigation({super.key, this.initialIndex = 1}); // default = QRScanner

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _selectedIndex;

  final List<Widget> _pages = [
    const Homepage(),
    QRScannerPage(),
    SignOffPage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // 👈 use initialIndex
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Log out'),
        ],
      ),
    );
  }
}

