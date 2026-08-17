import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class StudentsCategoryView extends StatefulWidget {
  final String category; // 'paid' أو 'unpaid'

  const StudentsCategoryView({super.key, required this.category});

  @override
  State<StudentsCategoryView> createState() => _StudentsCategoryViewState();
}

class _StudentsCategoryViewState extends State<StudentsCategoryView> {
  String? selectedYear;
  String? selectedMonth;
  String? selectedClass;

  List<String> years = [];
  List<String> months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر'
  ];
  List<String> classes = []; // لو عندك أكثر من صف
  List<Map<String, dynamic>> students = [];

  @override
  void initState() {
    super.initState();
    loadYears();
    loadClasses();
  }

  Future<void> loadYears() async {
    years = await DBHelper.getAllYears();
    setState(() {});
  }

  Future<void> loadClasses() async {
    classes = await DBHelper.getAllClasses();
    setState(() {});
  }

  Future<void> loadStudents() async {
    if (selectedYear == null ||
        selectedMonth == null ||
        selectedClass == null) {
      return;
    }
    final monthValue = "$selectedYear-$selectedMonth";
    final allStudents =
        await DBHelper.getStudentsByClassAndYear(selectedClass!, selectedYear!);

    students = [];
    for (var s in allStudents) {
      final paid =
          await DBHelper.hasPaidBeforeMonth(s['id'], selectedYear!, monthValue);

      if ((widget.category == 'paid' && paid) ||
          (widget.category == 'unpaid' && !paid)) {
        students.add(s);
      }
    }

    students.sort(
      (a, b) => int.parse(a['code'].toString())
          .compareTo(int.parse(b['code'].toString())),
    );

    setState(() {});
  }

  Future<void> printStudentsCategory() async {
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
                      widget.category == 'paid'
                          ? 'الطلاب الدافعين'
                          : 'الطلاب المتخلفين عن الدفع',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        font: ttf,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('السنة: $selectedYear',
                      style: pw.TextStyle(font: ttf, fontSize: 16)),
                  pw.Text('الشهر: $selectedMonth',
                      style: pw.TextStyle(font: ttf, fontSize: 16)),
                  pw.Paragraph(
                    text: 'الصف: $selectedClass',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 16,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: widget.category == 'paid'
                          ? PdfColors.green100
                          : PdfColors.red100,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      widget.category == 'paid'
                          ? 'عدد الطلاب الدافعين: ${students.length}'
                          : 'عدد الطلاب المتخلفين عن الدفع: ${students.length}',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: widget.category == 'paid'
                            ? PdfColors.green800
                            : PdfColors.red800,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(3),
                    },
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: widget.category == 'paid'
                              ? PdfColors.green
                              : PdfColors.red,
                        ),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'الكود',
                              textDirection: pw.TextDirection.rtl,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: ttf,
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'الاسم',
                              textDirection: pw.TextDirection.rtl,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: ttf,
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ...students.map(
                        (s) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                s['code'].toString(),
                                textDirection: pw.TextDirection.rtl,
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(font: ttf),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                s['name'],
                                textDirection: pw.TextDirection.rtl,
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(font: ttf),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء الطباعة: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.category == 'paid' ? 'طلاب الدافعين' : 'طلاب المتخلفين'),
        backgroundColor: widget.category == 'paid' ? Colors.green : Colors.red,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.print,
              color: Colors.white,
            ),
            onPressed: students.isEmpty ? null : printStudentsCategory,
          ),
        ],
      ),
      body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 1️⃣ اختر الصف الدراسي أولاً
              DropdownButtonFormField<String>(
                initialValue: selectedClass,
                items: classes
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedClass = value;
                    selectedYear = null; // مسح الاختيارات التالية
                    selectedMonth = null;
                    students = [];
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'اختر الصف الدراسي',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // 2️⃣ اختر السنة بعد اختيار الصف
              DropdownButtonFormField<String>(
                initialValue: selectedYear,
                items: selectedClass == null
                    ? []
                    : years
                        .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedYear = value;
                    selectedMonth = null; // مسح الشهر
                    students = [];
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'اختر السنة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // 3️⃣ اختر الشهر بعد اختيار السنة
              DropdownButtonFormField<String>(
                initialValue: selectedMonth,
                items: selectedYear == null
                    ? []
                    : months
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMonth = value;
                  });
                  loadStudents(); // تحميل الطلاب بعد تحديد الشهر
                },
                decoration: const InputDecoration(
                  labelText: 'اختر الشهر',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),
// فوق Expanded (قبل الجدول)
              TextField(
                decoration: const InputDecoration(
                  hintText: 'ابحث بالاسم أو الكود',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (query) {
                  if (query.isEmpty) {
                    loadStudents(); // لو البحث فاضي، رجع كل الطلاب
                    return;
                  }

                  final lower = query.toLowerCase();
                  setState(() {
                    students = students.where((s) {
                      final name = s['name'].toString().toLowerCase();
                      final code = s['code'].toString();
                      return name.contains(lower) || code.contains(query);
                    }).toList();
                  });
                },
              ),
              const SizedBox(height: 12),

              // باقي الكود: جدول الطلاب
              Expanded(
                child: students.isEmpty
                    ? const Center(child: Text('لا يوجد طلاب'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width,
                            ),
                            child: DataTable(
                              columnSpacing: 24,
                              headingRowColor:
                                  WidgetStateProperty.all(Colors.teal.shade100),
                              columns: const [
                                DataColumn(
                                    label: Text('الاسم',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                DataColumn(
                                    label: Text('الكود',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                              ],
                              rows: students.map((s) {
                                return DataRow(cells: [
                                  DataCell(
                                    Text(
                                      s['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      s['code'].toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          )),
    );
  }
}
