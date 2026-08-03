import 'package:attendance/db_helper.dart';
import 'package:attendance/screens/attendance_years.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceDatesPage extends StatefulWidget {
  const AttendanceDatesPage({super.key});

  @override
  State<AttendanceDatesPage> createState() => _AttendanceDatesPageState();
}

class _AttendanceDatesPageState extends State<AttendanceDatesPage> {
  List<String> allDates = [];
  List<String> filteredDates = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadDates();
  }

  Future<void> loadDates() async {
    final dates = await DBHelper.getAttendanceDates();
    setState(() {
      allDates = dates;
      filteredDates = dates;
    });
  }

  void filterDates(String query) {
    setState(() {
      filteredDates = allDates
          .where((date) => date.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );

    if (picked != null) {
      String formatted = DateFormat('yyyy-MM-dd').format(picked);
      searchController.text = formatted;
      filterDates(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'سجل الحضور اليومي',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[900],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: filterDates,
                    decoration: InputDecoration(
                      hintText: 'ابحث بالتاريخ (مثال: 2025-08)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.calendar_today, size: 28),
                  onPressed: pickDate,
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredDates.isEmpty
                ? const Center(child: Text('لا يوجد نتائج للتاريخ المدخل.'))
                : ListView.builder(
                    itemCount: filteredDates.length,
                    itemBuilder: (context, index) {
                      final date = filteredDates[index];
                      return Card(
                        color: Colors.orange[100],
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          title: Text(
                            date,
                            style: const TextStyle(fontSize: 18),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AttendanceYearsPage(date: date),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
