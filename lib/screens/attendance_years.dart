import 'package:attendance/screens/attendance_students.dart';
import 'package:flutter/material.dart';
import 'package:attendance/db_helper.dart';

class AttendanceYearsPage extends StatelessWidget {
  final String date;

  const AttendanceYearsPage({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الدفعات ليوم $date'),
        backgroundColor: Colors.teal[700],
      ),
      body: FutureBuilder<List<String>>(
        future: DBHelper.getYearsForDate(date),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا يوجد حضور مسجل.'));
          }

          final years = snapshot.data!;

          return ListView.builder(
            itemCount: years.length,
            itemBuilder: (context, index) {
              final year = years[index];
              return Card(
                color: Colors.lightBlue[50],
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(
                    year,
                    style: const TextStyle(fontSize: 18),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AttendanceStudentsPage(
                            date: date, year: year), // ✅ صح
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
