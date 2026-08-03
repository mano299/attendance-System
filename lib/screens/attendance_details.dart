import 'package:attendance/db_helper.dart';
import 'package:flutter/material.dart';

class AttendanceDetailsPage extends StatefulWidget {
  final String date;
  const AttendanceDetailsPage({super.key, required this.date});

  @override
  State<AttendanceDetailsPage> createState() => _AttendanceDetailsPageState();
}

class _AttendanceDetailsPageState extends State<AttendanceDetailsPage> {
  List<Map<String, dynamic>> allData = [];
  List<Map<String, dynamic>> filteredData = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadAttendance();
  }

  Future<void> loadAttendance() async {
    final data = await DBHelper.getAttendanceForDate(widget.date);
    setState(() {
      allData = data;
      filteredData = data;
    });
  }

  void filterData(String query) {
    final filtered = allData.where((student) {
      final name = student['name']?.toLowerCase() ?? '';
      final year = student['year']?.toLowerCase() ?? '';
      return name.contains(query.toLowerCase()) || year.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredData = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الحضور ليوم ${widget.date}'),
        backgroundColor: Colors.teal[700],
        centerTitle: true,
      ),
      body: allData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: filterData,
                    decoration: InputDecoration(
                      hintText: 'ابحث بالاسم أو السنة الدراسية',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(Colors.teal[100]),
                            dataRowColor: WidgetStateProperty.all(Colors.white),
                            columnSpacing: 20,
                            columns: const [
                              DataColumn(label: Text('الاسم', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('السنة الدراسية', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('وقت الحضور', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: filteredData.map((student) {
                              return DataRow(cells: [
                                DataCell(Text(student['name'] ?? '')),
                                DataCell(Text(student['year'] ?? '')),
                                DataCell(Text(student['date'].toString().substring(11, 16))),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
