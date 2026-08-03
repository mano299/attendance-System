import 'package:attendance/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:attendance/db_helper.dart';
import 'package:attendance/screens/attendance_session.dart';

class AllSessionsPage extends StatefulWidget {
  const AllSessionsPage({super.key});

  @override
  State<AllSessionsPage> createState() => _AllSessionsPageState();
}

class _AllSessionsPageState extends State<AllSessionsPage> {
  List<Map<String, dynamic>> sessions = [];
  List<Map<String, dynamic>> filteredSessions = [];
  List<String> years = [];
  String? selectedYear;

  Future<void> fetchSessions() async {
  final data = List<Map<String, dynamic>>.from(await DBHelper.getAllSessions());

  // جمع السنوات المختلفة من الحصص
  final yearList = data.map((e) => e['year'].toString()).toSet().toList();

  // ترتيب الحصص تنازليًا حسب رقم الحصة
  data.sort((a, b) => (b['session_number'] as int).compareTo(a['session_number'] as int));

  setState(() {
    sessions = data;
    years = yearList;
    filteredSessions = data; // عرض كل الحصص في البداية
  });
}

  @override
  void initState() {
    super.initState();
    fetchSessions();
  }

  void onYearChanged(String? year) {
    setState(() {
      selectedYear = year;
      if (year == null) {
        filteredSessions = sessions; // عرض كل الحصص إذا لم يتم اختيار سنة
      } else {
        filteredSessions = sessions.where((s) => s['year'] == year).toList(); // تصفية الحصص حسب السنة
      }
      // ترتيب filteredSessions تنازليًا حسب رقم الحصة
      filteredSessions.sort((a, b) => (b['session_number'] as int).compareTo(a['session_number'] as int));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📚 كل الحصص'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => HomePage()),
              (route) => false,
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String?>(
              isExpanded: true,
              hint: Text('اختر السنة الدراسية'),
              value: selectedYear,
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('كل السنوات'),
                ),
                ...years.map((year) => DropdownMenuItem<String>(
                      value: year,
                      child: Text(year),
                    )),
              ],
              onChanged: onYearChanged,
            ),
            const SizedBox(height: 10),
            Text(
              'عدد الحصص: ${filteredSessions.length}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: filteredSessions.isEmpty
                  ? Center(
                      child: Text(selectedYear == null
                          ? 'لا توجد حصص.'
                          : 'لا توجد حصص لهذه السنة.'),
                    )
                  : ListView.builder(
                      itemCount: filteredSessions.length,
                      itemBuilder: (context, index) {
                        final session = filteredSessions[index];
                        final year = session['year'];
                        final date = session['date'];
                        final sessionNumber = session['session_number'];
                        final id = session['id'];

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              '📘 السنة: $year',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('📅 التاريخ: $date'),
                            trailing: Text('الحصة رقم: $sessionNumber'),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AttendanceSessionPage(
                                    date: date,
                                    year: year,
                                    sessionId: id,
                                  ),
                                ),
                              );
                              fetchSessions(); // تحديث القائمة بعد العودة
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
