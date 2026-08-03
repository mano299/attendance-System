import 'package:attendance/db_helper.dart';
import 'package:flutter/material.dart';

class ViewStudentsPage extends StatefulWidget {
  const ViewStudentsPage({super.key});

  @override
  State<ViewStudentsPage> createState() => _ViewStudentsPageState();
}

class _ViewStudentsPageState extends State<ViewStudentsPage> {
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filteredStudents = [];
  TextEditingController searchController = TextEditingController();

  List<String> orderedYears = [
    'الصف الأول الاعدادي',
    'الصف الثاني الاعدادي',
    'الصف الثالث الاعدادي',
    'الصف الأول الثانوي',
    'الصف الثاني الثانوي',
    'الصف الثالث الثانوي',
  ];
  String? selectedYear;

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {
    final data = await DBHelper.fetchStudentsWithPayments();
    setState(() {
      students = data;
      filteredStudents = data;
      applyFilters();
    });
  }

  void applyFilters() {
    final query = searchController.text.toLowerCase();

    final results = students.where((student) {
      final name = student['name']?.toLowerCase() ?? '';
      final code = student['code']?.toLowerCase() ?? '';
      final year = student['year'] ?? '';
      final matchesSearch = name.contains(query) || code.contains(query);
      final matchesYear = selectedYear == null || year == selectedYear;

      return matchesSearch && matchesYear;
    }).toList();

    setState(() {
      filteredStudents = results;
    });
  }

  void filterSearch(String query) {
    applyFilters();
  }

  // 🔑 إعادة تعيين الدفع مع كلمة سر
  void resetPaymentsWithPassword() {
    TextEditingController passwordController = TextEditingController();
    const correctPassword = "youssef101"; // الباسورد اللي تحدده

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("🔑 تأكيد الهوية"),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: "ادخل كلمة السر",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.trim() == correctPassword) {
                Navigator.pop(context);
                await DBHelper.resetAllPayments();
                await loadStudents();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("✅ تم إعادة تعيين الدفع لكل الطلاب"),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("❌ كلمة السر غير صحيحة"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text("تأكيد"),
          ),
        ],
      ),
    );
  }

  // ✏️ تعديل بيانات الطالب
  void editStudent(Map<String, dynamic> student, BuildContext context) {
    TextEditingController nameController =
        TextEditingController(text: student['name'] ?? '');
    TextEditingController phoneController =
        TextEditingController(text: student['phone'] ?? '');
    TextEditingController parentPhoneController =
        TextEditingController(text: student['parent_phone'] ?? '');
    TextEditingController codeController =
        TextEditingController(text: student['code'] ?? '');

    String selectedYearLocal = student['year'] ?? orderedYears.first;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('✏️ تعديل الطالب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'الاسم'),
            ),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'رقم الطالب'),
            ),
            TextField(
              controller: parentPhoneController,
              decoration: InputDecoration(labelText: 'رقم ولي الأمر'),
            ),
            TextField(
              controller: codeController,
              decoration: InputDecoration(labelText: 'الكود'),
            ),
            DropdownButton<String>(
              value: selectedYearLocal,
              isExpanded: true,
              items: orderedYears.map((year) {
                return DropdownMenuItem<String>(
                  value: year,
                  child: Text(year),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  selectedYearLocal = value;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await DBHelper.updateStudent(
                id: student['id'],
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                parentPhone: parentPhoneController.text.trim(),
                year: selectedYearLocal,
              );
              Navigator.pop(context);
              loadStudents();
            },
            child: Text('💾 حفظ'),
          ),
        ],
      ),
    );
  }

  // 📘 عرض الدرجات
  Future<void> showGrades(int studentId, String studentName) async {
    final db = await DBHelper.openDB();

    final grades = await db.query(
      'recitations',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'session_number ASC',
    );

    if (grades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚫 لا توجد درجات لهذا الطالب')),
      );
      return;
    }

    // نحسب المجموع الكلي بناء على العمود الفعلي
    double totalScore = 0;
    double totalMaxScore = 0;

    for (var g in grades) {
      final scoreObj = g['score'] ?? 0;
      final maxScoreObj = g['max_score'] ?? 0;

      // تحويل لأي نوع عددي
      double score = 0;
      double maxScore = 0;

      if (scoreObj is int) {
        score = scoreObj.toDouble();
      } else if (scoreObj is double) {
        score = scoreObj;
      } else if (scoreObj is String) {
        score = double.tryParse(scoreObj) ?? 0;
      }

      if (maxScoreObj is int) {
        maxScore = maxScoreObj.toDouble();
      } else if (maxScoreObj is double) {
        maxScore = maxScoreObj;
      } else if (maxScoreObj is String) {
        maxScore = double.tryParse(maxScoreObj) ?? 0;
      }

      totalScore += score;
      totalMaxScore += maxScore;
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.teal[700],
                width: double.infinity,
                child: Text(
                  '📊 درجات الطالب: $studentName',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width - 40),
                        child: DataTable(
                          columnSpacing: 30,
                          columns: const [
                            DataColumn(label: Text('رقم التسميع')),
                            DataColumn(label: Text('الدرجة')),
                            DataColumn(label: Text('الدرجة النهائية')),
                            DataColumn(label: Text('ملاحظات')),
                          ],
                          rows: grades.map((g) {
                            final sessionNumber = g['session_number'] ?? 0;
                            final score = g['score'] ?? 0;
                            final maxScore = g['max_score'] ?? 0;
                            final notes = g['notes'] ?? '';
                            return DataRow(cells: [
                              DataCell(Text(sessionNumber.toString())),
                              DataCell(Text(score.toString())),
                              DataCell(Text(maxScore.toString())),
                              DataCell(Text(notes.toString())),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                alignment: Alignment.centerRight,
                width: double.infinity,
                child: Text(
                  'المجموع الكلي: $totalScore / $totalMaxScore',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.teal),
                  textAlign: TextAlign.right,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📅 عرض الغياب
  Future<void> showAttendance(
    int studentId,
    String studentName,
    String studentYear,
  ) async {
    final db = await DBHelper.openDB();

    final attendance = await db.rawQuery('''
  SELECT 
    s.date,
    CASE 
      WHEN a.id IS NOT NULL THEN 'حاضر'
      ELSE 'غائب'
    END as status
  FROM sessions s
  LEFT JOIN attendance a 
    ON s.id = a.session_id 
    AND a.student_id = ?
  WHERE s.year = ?
  ORDER BY s.date DESC
''', [studentId, studentYear]);

    if (attendance.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🚫 لا يوجد حصص مسجلة بعد')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('📅 سجل الحضور: $studentName'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('التاريخ')),
                DataColumn(label: Text('الحالة')),
              ],
              rows: attendance.map((a) {
                final date = a['date'] ?? '';
                final status = a['status'] ?? '❌ غائب';
                return DataRow(cells: [
                  DataCell(Text(date.toString())),
                  DataCell(Text(status.toString())),
                ]);
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('📋 قائمة الطلاب'),
          actions: [
            IconButton(
              icon: Icon(Icons.lock_reset),
              tooltip: 'إعادة تعيين الدفع',
              onPressed: resetPaymentsWithPassword,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                height: 45,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ChoiceChip(
                      label: Text('الكل'),
                      selected: selectedYear == null,
                      onSelected: (_) {
                        setState(() {
                          selectedYear = null;
                          applyFilters();
                        });
                      },
                    ),
                    ...orderedYears.map((year) {
                      final isSelected = year == selectedYear;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(year),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              selectedYear = year;
                              applyFilters();
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: '🔍 ابحث بالاسم أو الكود',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: filterSearch,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filteredStudents.isEmpty
                    ? Center(child: Text('🚫 لا يوجد طلاب مطابقين'))
                    : Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            headingRowColor:
                                WidgetStateProperty.all(Colors.blue[100]),
                            headingTextStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            columns: const [
                              DataColumn(label: Text('الكود')),
                              DataColumn(label: Text('الاسم')),
                              DataColumn(label: Text('رقم الطالب')),
                              DataColumn(label: Text('رقم ولي الأمر')),
                              DataColumn(label: Text('السنة الدراسية')),
                              DataColumn(label: Text('دفع؟')),
                              DataColumn(label: Text('المبلغ المدفوع')),
                              DataColumn(label: Text('خيارات')),
                            ],
                            rows: filteredStudents.map((student) {
                              return DataRow(cells: [
                                DataCell(Text(student['code'] ?? '')),
                                DataCell(Text(student['name'] ?? '')),
                                DataCell(Text(student['phone'] ?? '')),
                                DataCell(Text(student['parent_phone'] ?? '')),
                                DataCell(Text(student['year'] ?? '')),
                                DataCell(Text(
                                    (student['totalPaid'] ?? 0).toInt() > 0
                                        ? '✅'
                                        : '❌')),
                                DataCell(Text(
                                    '💰${(student['totalPaid'] ?? 0).toInt()}')),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                      icon:
                                          Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        editStudent(student, context);
                                      },
                                    ),
                                    IconButton(
                                      icon:
                                          Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('تأكيد الحذف'),
                                            content: Text(
                                                'هل أنت متأكد من حذف الطالب؟'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text('إلغاء'),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  Navigator.pop(context);
                                                  await DBHelper.deleteStudent(
                                                      student['id']);
                                                  loadStudents();
                                                },
                                                child: Text('حذف'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.grade,
                                          color: Colors.green),
                                      tooltip: 'عرض الدرجات',
                                      onPressed: () {
                                        showGrades(
                                            student['id'], student['name']);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.calendar_today,
                                          color: Colors.orange),
                                      tooltip: 'عرض الغياب',
                                      onPressed: () {
                                        showAttendance(
                                          student['id'],
                                          student['name'],
                                          student['year'],
                                        );
                                      },
                                    ),
                                  ],
                                ))
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
