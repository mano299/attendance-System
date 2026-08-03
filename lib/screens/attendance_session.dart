import 'package:attendance/screens/all_session.dart';
import 'package:flutter/material.dart';
import 'package:attendance/db_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class AttendanceSessionPage extends StatefulWidget {
  final String year;
  final int sessionId;
  final String date;

  const AttendanceSessionPage({
    super.key,
    required this.year,
    required this.sessionId,
    required this.date,
  });

  @override
  State<AttendanceSessionPage> createState() => _AttendanceSessionPageState();
}

class _AttendanceSessionPageState extends State<AttendanceSessionPage> {
  List<Map<String, dynamic>> presentStudents = [];
  List<Map<String, dynamic>> absentStudents = [];
  List<Map<String, dynamic>> filteredPresent = [];
  List<Map<String, dynamic>> filteredAbsent = [];

  TextEditingController codeController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  FocusNode codeFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final present = List<Map<String, dynamic>>.from(
        await DBHelper.getPresentStudents(widget.sessionId));
    final absent = List<Map<String, dynamic>>.from(
        await DBHelper.getAbsentStudents(widget.year, widget.sessionId));

    present.sort((a, b) => a['name'].compareTo(b['name']));
    absent.sort((a, b) => a['name'].compareTo(b['name']));

    setState(() {
      presentStudents = present;
      absentStudents = absent;
      filteredPresent = present;
      filteredAbsent = absent;
    });
  }

  Future<void> _markAttendance(String code) async {
    final student = await DBHelper.getStudentByCodeAndYear(code, widget.year);

    if (student == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الطالب غير موجود')),
      );
      return;
    }

    final alreadyPresent = presentStudents.any((s) => s['id'] == student['id']);
    if (alreadyPresent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تسجيل الحضور مسبقًا')),
      );
      return;
    }

    await DBHelper.markStudentPresent(
      sessionId: widget.sessionId,
      studentId: student['id'],
    );

    codeController.clear();
    await _loadData();
  }

  Widget buildStudentTile(Map<String, dynamic> student, Icon icon,
      {bool showParentPhone = false}) {
    return ListTile(
      leading: icon,
      title: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              student['name'] ?? '',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              student['code'] ?? '',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          if (showParentPhone)
            Expanded(
              flex: 3,
              child: Text(
                student['parent_phone'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red, // رقم ولي الأمر باللون الأحمر
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _printPresentOnly() async {
    try {
      final fontData = await rootBundle.load("assets/fonts/Amiri-Regular.ttf");
      final ttf = pw.Font.ttf(fontData);

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text(
                      'كشف الحضور',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        font: ttf,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('السنة: ${widget.year}',
                      style: pw.TextStyle(font: ttf)),
                  pw.Text('التاريخ: ${widget.date}',
                      style: pw.TextStyle(font: ttf)),
                  pw.SizedBox(height: 20),
                  pw.Table.fromTextArray(
                    headers: ['الكود', 'الاسم'],
                    data: filteredPresent
                        .map((s) => [
                              s['code'].toString(),
                              s['name'].toString(),
                            ])
                        .toList(),
                    headerStyle: pw.TextStyle(
                      font: ttf,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: pw.BoxDecoration(color: PdfColors.green),
                    cellStyle: pw.TextStyle(font: ttf, color: PdfColors.black),
                    cellAlignment: pw.Alignment.centerRight,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء طباعة الحضور: $e')),
      );
    }
  }

  Future<void> _printAbsentOnly() async {
    try {
      final fontData = await rootBundle.load("assets/fonts/Amiri-Regular.ttf");
      final ttf = pw.Font.ttf(fontData);

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text(
                      'كشف الغياب',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        font: ttf,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('السنة: ${widget.year}',
                      style: pw.TextStyle(font: ttf)),
                  pw.Text('التاريخ: ${widget.date}',
                      style: pw.TextStyle(font: ttf)),
                  pw.SizedBox(height: 20),
                  pw.Table.fromTextArray(
                    headers: ['رقم ولي الامر', 'الكود', 'الاسم'],
                    data: filteredAbsent
                        .map((s) => [
                              s['parent_phone'].toString(),
                              s['code'].toString(),
                              s['name'].toString(),
                            ])
                        .toList(),
                    headerStyle: pw.TextStyle(
                      font: ttf,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: pw.BoxDecoration(color: PdfColors.red),
                    cellStyle: pw.TextStyle(font: ttf, color: PdfColors.black),
                    cellAlignment: pw.Alignment.centerRight,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء طباعة الغياب: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => AllSessionsPage()),
                (route) => false,
              );
            },
          ),
          title: Text(widget.year),
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.print),
              onSelected: (value) {
                if (value == 'present') {
                  _printPresentOnly();
                } else if (value == 'absent') {
                  _printAbsentOnly();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'present',
                  child: Text('طباعة الحضور فقط'),
                ),
                PopupMenuItem(
                  value: 'absent',
                  child: Text('طباعة الغياب فقط'),
                ),
              ],
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('التاريخ: ${widget.date}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(
                    width: 200,
                    height: 40,
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'بحث',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        final query = value.trim().toLowerCase();
                        setState(() {
                          filteredPresent = presentStudents.where((student) {
                            final name = (student['name'] ?? '').toLowerCase();
                            final code = (student['code'] ?? '').toLowerCase();
                            return name.contains(query) || code.contains(query);
                          }).toList();

                          filteredAbsent = absentStudents.where((student) {
                            final name = (student['name'] ?? '').toLowerCase();
                            final code = (student['code'] ?? '').toLowerCase();
                            return name.contains(query) || code.contains(query);
                          }).toList();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                focusNode: codeFocus,
                decoration: InputDecoration(
                  labelText: 'أدخل كود الطالب',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                onSubmitted: (value) async {
                  await _markAttendance(value.trim());
                  codeController.clear();
                  codeFocus.requestFocus();
                },
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الحاضرون (${filteredPresent.length})',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: ListView.builder(
                              itemCount: filteredPresent.length,
                              itemBuilder: (context, index) {
                                final student = filteredPresent[index];
                                return buildStudentTile(
                                  student,
                                  Icon(Icons.check_circle, color: Colors.green),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    VerticalDivider(),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الغائبون (${filteredAbsent.length})',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: ListView.builder(
                              itemCount: filteredAbsent.length,
                              itemBuilder: (context, index) {
                                final student = filteredAbsent[index];
                                return buildStudentTile(
                                  student,
                                  Icon(Icons.cancel, color: Colors.red),
                                  showParentPhone: true,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
