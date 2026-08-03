import 'package:attendance/db_helper.dart';
import 'package:flutter/material.dart';

class StudentsByYearPage extends StatefulWidget {
  final String year;

  const StudentsByYearPage({super.key, required this.year});

  @override
  State<StudentsByYearPage> createState() => _StudentsByYearPageState();
}

class _StudentsByYearPageState extends State<StudentsByYearPage> {
  List<Map<String, dynamic>> students = [];

  @override
  void initState() {
    super.initState();
    print("📌 السنة الحالية: ${widget.year}");
    loadStudents();
  }

  Future<void> loadStudents() async {
    final db = await DBHelper.openDB();

    final List<Map<String, dynamic>> data = await db.rawQuery('''
  SELECT 
    students.id,
    students.name,
    students.code,
    students.phone,
    students.parent_phone,
    students.year,
    CASE 
      WHEN EXISTS (
        SELECT 1 FROM payments 
        WHERE payments.student_id = students.id
      ) THEN 1
      ELSE 0
    END AS has_paid
  FROM students
  WHERE TRIM(year) = ?
''', [widget.year]); // ✅ بدلنا = بـ LIKE

    print("📊 عدد الطلاب: ${data.length}");
    print("🧾 البيانات: $data");

    setState(() {
      students = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('طلاب الصف: ${widget.year}')),
      body: students.isEmpty
          ? Center(child: Text('لا يوجد طلاب في هذا الصف'))
          : Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              child: DataTable(
                columnSpacing: 16,
                headingRowColor: WidgetStateProperty.all(Colors.blue[100]),
                headingTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                columns: const [
                  DataColumn(label: Text('الكود')),
                  DataColumn(label: Text('الاسم')),
                  DataColumn(label: Text('رقم الطالب')),
                  DataColumn(label: Text('رقم ولي الأمر')),
                  DataColumn(label: Text('دفع؟')),
                ],
                rows: students.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var student = entry.value;
                  return DataRow(
                    color: WidgetStateProperty.all(
                      idx % 2 == 0 ? Colors.white : Colors.grey[200],
                    ),
                    cells: [
                      DataCell(Text(student['code'] ?? '')),
                      DataCell(Text(student['name'] ?? '')),
                      DataCell(Text(student['phone'] ?? '')),
                      DataCell(Text(student['parent_phone'] ?? '')),
                      DataCell(Text(student['has_paid'] == 1 ? '✅' : '❌')),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }
}
