import 'package:attendance/screens/attendance_session.dart';
import 'package:flutter/material.dart';
import 'package:attendance/db_helper.dart';

class AddSessionPage extends StatefulWidget {
  const AddSessionPage({super.key});

  @override
  State<AddSessionPage> createState() => _AddSessionPageState();
}

class _AddSessionPageState extends State<AddSessionPage> {
  DateTime selectedDate = DateTime.now();
  String? selectedYear;

  final List<String> years = [
    'الصف الأول الاعدادي',
    'الصف الثاني الاعدادي',
    'الصف الثالث الاعدادي',
    'الصف الأول الثانوي',
    'الصف الثاني الثانوي',
    'الصف الثالث الثانوي',
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('➕ إضافة حصة')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ListTile(
                title: Text('📅 التاريخ: ${selectedDate.toLocal().toString().split(' ')[0]}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => selectedDate = date);
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: selectedYear,
                items: years
                    .map((year) => DropdownMenuItem(
                          value: year,
                          child: Text(year),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => selectedYear = val),
                decoration: InputDecoration(
                  labelText: '📘 اختر السنة الدراسية',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  if (selectedYear == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('⚠️ اختر السنة الدراسية')),
                    );
                    return;
                  }

                  final dateStr = selectedDate.toIso8601String().split('T').first;

                  // ✅ أضف الحصة وخذ ID الحصة الجديد
                  final sessionId = await DBHelper.addSession(selectedYear!, dateStr);

                  // ✅ انتقل مباشرة إلى صفحة تسجيل الحضور
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttendanceSessionPage(
                        sessionId: sessionId,
                        date: dateStr,
                        year: selectedYear!,
                      ),
                    ),
                  );
                },
                child: Text('بدء الحصة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
