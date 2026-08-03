import 'package:attendance/db_helper.dart';
import 'package:attendance/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  DBHelper.addUser(username: 'mano', password: '1234', role: 'teacher');
  // final prefs = await SharedPreferences.getInstance();
//  await prefs.clear(); // مسح الشيريد علشان الباسورد

  // final isLogged = prefs.getBool('isLogged') ?? false;
  runApp(
    AttendanceSystem(),
  );
}

class AttendanceSystem extends StatelessWidget {
  const AttendanceSystem({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(fontFamily: 'Elmessiri'),
      locale: Locale('ar'),
      supportedLocales: [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: LoginView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
