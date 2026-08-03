import 'package:attendance/screens/session_grades.dart';
import 'package:flutter/material.dart';
import 'package:attendance/db_helper.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  _GradesPageState createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  List<String> years = [];
  String? selectedYear;

  List<int> sessions = [];
  int? selectedSession;

  List<Map<String, dynamic>> grades = [];

  @override
  void initState() {
    super.initState();
    loadYears();
  }

  Future<void> loadYears() async {
    years = await DBHelper.getAllYears();
    setState(() {});
  }

  Future<void> onYearSelected(String year) async {
    selectedYear = year;
    selectedSession = null;
    grades = [];
    sessions = await DBHelper.getSessionNumbersByYear(year);
    setState(() {});
  }

  Future<void> onSessionSelected(int sessionNumber) async {
    selectedSession = sessionNumber;
    grades =
        await DBHelper.getGradesByYearAndSession(selectedYear!, sessionNumber);

    // فتح الصفحة الجديدة مع تمرير الدرجات
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionGradesPage(
          sessionNumber: sessionNumber,
          grades: grades,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('الدرجات'),
          backgroundColor: Colors.teal[700],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // يملأ العرض
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text('اختر السنة الدراسية:',
                    style: TextStyle(fontSize: 18)),
              ),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  children: years.map((year) {
                    return ChoiceChip(
                      label: Text(year),
                      selected: selectedYear == year,
                      onSelected: (_) => onYearSelected(year),
                    );
                  }).toList(),
                ),
              ),
              if (selectedYear != null) ...[
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child:
                      Text('اختر رقم التسميع:', style: TextStyle(fontSize: 18)),
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    children: sessions.map((sessionNum) {
                      return ChoiceChip(
                        label: Text(sessionNum.toString()),
                        selected: selectedSession == sessionNum,
                        onSelected: (_) => onSessionSelected(sessionNum),
                      );
                    }).toList(),
                  ),
                ),
              ],
              SizedBox(height: 20),
              if (grades.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('درجات الطلاب:', style: TextStyle(fontSize: 18)),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: grades.length,
                    itemBuilder: (context, index) {
                      final grade = grades[index];
                      return ListTile(
                        title: Text(grade['name']),
                        subtitle: Text('ملاحظات: ${grade['notes'] ?? ''}'),
                        trailing: Text(
                          'الدرجة: ${grade['score'] != null ? double.parse(grade['score'].toString()).toStringAsFixed(1) : '-'}',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
