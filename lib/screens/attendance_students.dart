import 'package:flutter/material.dart';
import 'package:attendance/db_helper.dart';

class AttendanceStudentsPage extends StatelessWidget {
  final String date;
  final String year;

  const AttendanceStudentsPage({super.key, required this.date, required this.year});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('حضور $year - $date'),
        backgroundColor: Colors.indigo[800],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DBHelper.getStudentsByDateAndYear(date, year),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا يوجد طلاب حضروا.'));
          }

          final students = snapshot.data!;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
              child: DataTable(
                headingRowColor: WidgetStateColor.resolveWith((states) => Colors.indigo.shade200),
                dataRowColor: WidgetStateColor.resolveWith((states) => Colors.orange.shade50),
                columnSpacing: 30,
                columns: const [
                  DataColumn(
                    label: Text('اسم الطالب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  DataColumn(
                    label: Text('السنة الدراسية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  DataColumn(
                    label: Text('وقت الحضور', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
                rows: List.generate(students.length, (index) {
                  final student = students[index];
                  final bgColor = index % 2 == 0 ? Colors.orange[50] : Colors.orange[100];

                  return DataRow(
                    color: WidgetStateColor.resolveWith((states) => bgColor!),
                    cells: [
                      DataCell(Text(student['name'] ?? '', style: TextStyle(fontSize: 15))),
                      DataCell(Text(student['year'] ?? '', style: TextStyle(fontSize: 15))),
                      DataCell(Text(
                        student['date'] != null
                            ? student['date'].toString().substring(11, 16)
                            : '',
                        style: TextStyle(fontSize: 15),
                      )),
                    ],
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }
}
