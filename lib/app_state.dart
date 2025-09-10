import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  String? idNo;
  String? documentID;
  String? firstName;
  String? lastName;
  String? course;
  String? transactionId;
  DateTime? loginTime;

  /// Save current login state to SharedPreferences
  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    if (idNo != null) prefs.setString('idNo', idNo!);
    if (documentID != null) prefs.setString('documentID', documentID!);
    if (firstName != null) prefs.setString('firstName', firstName!);
    if (lastName != null) prefs.setString('lastName', lastName!);
    if (course != null) prefs.setString('course', course!);
    if (transactionId != null) prefs.setString('transactionId', transactionId!);
    if (loginTime != null) prefs.setString('loginTime', loginTime!.toIso8601String());
  }

  /// Load login state from SharedPreferences
  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    idNo = prefs.getString('idNo');
    documentID = prefs.getString('documentID');
    firstName = prefs.getString('firstName');
    lastName = prefs.getString('lastName');
    course = prefs.getString('course');
    transactionId = prefs.getString('transactionId');
    final loginTimeStr = prefs.getString('loginTime');
    if (loginTimeStr != null) loginTime = DateTime.tryParse(loginTimeStr);
  }

  /// Clear stored login state
  Future<void> clearState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    idNo = null;
    documentID = null;
    firstName = null;
    lastName = null;
    course = null;
    transactionId = null;
    loginTime = null;
  }
}
