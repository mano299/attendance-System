import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final TextEditingController codeController = TextEditingController();
  String? studentName;

  Future<Database> openDB() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'students.db'),
      version: 1,
      onCreate: (db, version) async {
        // تأكد من إنشاء الجداول
        await db.execute('''
          CREATE TABLE IF NOT EXISTS students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            phone TEXT,
            year TEXT,
            code TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS attendance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER,
            date TEXT,
            FOREIGN KEY(student_id) REFERENCES students(id)
          )
        ''');
      },
    );
  }

  Future<void> markAttendance(String code, BuildContext context) async {
  final db = await openDB();

  String normalizedCode = code.replaceFirst(RegExp(r'^0+'), '');

  final List<Map<String, dynamic>> result = await db.query(
    'students',
    where: 'REPLACE(code, "0", "") = ? OR code = ? OR CAST(code AS TEXT) = ?',
    whereArgs: [normalizedCode, code, normalizedCode],
  );

  if (result.isEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ الكود غير موجود')),
      );
    }
    return;
  }

  int studentId = result.first['id'];
  String name = result.first['name'];

  // التحقق من وجود تسجيل سابق اليوم
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
  final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

  final List<Map<String, dynamic>> existingAttendance = await db.query(
    'attendance',
    where: 'student_id = ? AND date BETWEEN ? AND ?',
    whereArgs: [studentId, startOfDay, endOfDay],
  );

  if (existingAttendance.isNotEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ تم تسجيل الحضور مسبقًا لهذا الطالب اليوم')),
      );
    }
    return;
  }

  await db.insert('attendance', {
    'student_id': studentId,
    'date': DateTime.now().toIso8601String(),
  });

  if (mounted) {
    setState(() {
      studentName = name;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ تم تسجيل الحضور')),
    );
  }

  codeController.clear();
}

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('📝 تسجيل الحضور')),
        body: Center(
          child: Container(
            width: 400, // تقدر تتحكم في العرض حسب التصميم
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ادخل كود الطالب',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textDirection: TextDirection.rtl,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'ادخل كود الطالب هنا',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    String code = codeController.text.trim();
                    if (code.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('⚠️ برجاء إدخال كود الطالب')),
                      );
                      return;
                    }

                    markAttendance(code, context);
                  },
                  child: Text('تسجيل الحضور'),
                ),
                if (studentName != null) ...[
                  SizedBox(height: 20),
                  Text(
                    '📌 الطالب: $studentName حضر بنجاح',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
