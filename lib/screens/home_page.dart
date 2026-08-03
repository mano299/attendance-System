import 'package:attendance/screens/add_recitation.dart';
import 'package:attendance/screens/add_session.dart';
import 'package:attendance/screens/add_students.dart';
import 'package:attendance/screens/admin_page.dart';
import 'package:attendance/screens/all_session.dart';
import 'package:attendance/screens/attendance_page.dart';
import 'package:attendance/screens/dashboard.dart';
import 'package:attendance/screens/discounts_page.dart';
import 'package:attendance/screens/grades.dart';
import 'package:attendance/screens/payments_page.dart';
import 'package:attendance/screens/view_students.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendance/screens/login.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedPage = 'الرئيسية';
  bool isTeacher = false;

  Widget getContent() {
    switch (selectedPage) {
      case 'إضافة طالب':
        return AddStudentPage();
      case 'تسجيل الحضور':
        return Center(child: AttendancePage());
      case 'إضافة حصة':
        return AddSessionPage();
      case 'المصاريف':
        return PaymentsPage();
      case 'الدرجات':
        return GradesPage();
      case 'عرض الطلاب':
        return ViewStudentsPage();
      case 'الرئيسية':
        return DashboardScreen();
      case 'سجل الغياب':
        return AllSessionsPage();
      case 'إضافة تسميع':
        return AddRecitationPage();
      case 'الادارة':
        return AdminPage();
      case 'الخصومات':
        return DiscountsPage();
      default:
        return Center(child: Text('مرحبًا بك في النظام'));
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserRole();
  }

  Future<void> loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    isTeacher = prefs.getBool('isTeacher') ?? false;
    setState(() {});
  }

  Future<void> logout() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الخروج'),
        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // لا
            child: const Text('لا'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // نعم
            child: const Text('نعم'),
          ),
        ],
      ),
    );

    if (confirm != null && confirm) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Row(
          children: [
            Container(
              width: 200,
              color: Colors.blue[900],
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  sideButton('الرئيسية'),
                  sideButton('إضافة طالب'),
                  sideButton('إضافة حصة'),
                  sideButton('المصاريف'),
                  sideButton('سجل الغياب'),
                  sideButton('إضافة تسميع'),
                  sideButton('الدرجات'),
                  sideButton('عرض الطلاب'),
                  sideButton('الخصومات'),
                  if (isTeacher) sideButton('الادارة'),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton(
                      onPressed: logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                      ),
                      child: const SizedBox(
                        width: 160,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'تسجيل الخروج',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.grey[100],
                child: getContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sideButton(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedPage = title;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedPage == title ? Colors.orange : Colors.white,
          foregroundColor: selectedPage == title ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: SizedBox(
          width: 160,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
