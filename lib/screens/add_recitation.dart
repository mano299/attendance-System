import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendance/db_helper.dart';

class AddRecitationPage extends StatefulWidget {
  const AddRecitationPage({super.key});

  @override
  State<AddRecitationPage> createState() => _AddRecitationPageState();
}

class _AddRecitationPageState extends State<AddRecitationPage> {
  String? selectedYear;
  List<String> years = [];

  int? selectedStudentId;
  List<Map<String, dynamic>> students = [];

  TextEditingController sessionNumberController = TextEditingController();
  TextEditingController maxScoreController = TextEditingController();
  TextEditingController codeController = TextEditingController();
  TextEditingController scoreController = TextEditingController();
  TextEditingController notesController = TextEditingController();

  FocusNode codeFocus = FocusNode();
  FocusNode scoreFocus = FocusNode();
  FocusNode notesFocus = FocusNode();

  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadYears();
    loadStudents();
    loadSavedValues();
  }

  Future<void> loadYears() async {
    years = await DBHelper.getAllYears();
    if (mounted) setState(() {});
  }

  Future<void> loadStudents() async {
    final result = await DBHelper.getAllStudents();
    if (mounted) {
      setState(() {
        students = result;
      });
    }
  }

  Future<void> loadSavedValues() async {
    final prefs = await SharedPreferences.getInstance();
    maxScoreController.text = prefs.getString('maxScore') ?? '';
  }

  Future<void> saveMaxScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('maxScore', maxScoreController.text.trim());
  }

  Future<void> onYearSelected(String year) async {
    selectedYear = year;
    // جلب آخر رقم تسميع للسنة
    final lastSession = await DBHelper.getSessionNumbersByYear(year);
    final newSessionNumber = (lastSession.isEmpty ? 0 : lastSession.last) + 1;
    sessionNumberController.text = newSessionNumber.toString();
    setState(() {});
  }

  void showSnack(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> findStudentByCode() async {
    final code = codeController.text.trim();
    if (code.isEmpty) return;

    if (selectedYear == null) {
      showSnack('اختر السنة الدراسية أولاً');
      return;
    }

    final student = await DBHelper.getStudentByCodeAndYear(code, selectedYear!);

    if (student == null) {
      showSnack('كود الطالب غير موجود في هذه السنة');
      selectedStudentId = null;
      setState(() {});
      return;
    }

    selectedStudentId = student['id'];
    setState(() {});
    FocusScope.of(context).requestFocus(scoreFocus);
  }

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> saveRecitation() async {
    if (selectedYear == null) {
      showSnack('اختر السنة الدراسية');
      return;
    }

    if (selectedStudentId == null) {
      showSnack('اختر الطالب أو أدخل الكود الصحيح');
      return;
    }

    if (maxScoreController.text.trim().isEmpty) {
      showSnack('أدخل الدرجة النهائية');
      return;
    }

    final sessionNumber = int.tryParse(sessionNumberController.text);
    final score = double.tryParse(scoreController.text);
    final maxScore = int.tryParse(maxScoreController.text) ?? 0;

    if (sessionNumber == null || sessionNumber <= 0) {
      showSnack('رقم التسميع غير صحيح');
      return;
    }

    if (score == null || score < 0) {
      showSnack('أدخل الدرجة الصحيحة');
      return;
    }

    // ✅ التحقق من الحد الأعلى حسب ما حدده المستخدم
    if (score > maxScore) {
      showSnack('الدرجة لا يمكن أن تتجاوز الدرجة النهائية ($maxScore)');
      return;
    }

    await saveMaxScore();

    await DBHelper.insertRecitation(
      year: selectedYear!,
      studentId: selectedStudentId!,
      date: selectedDate.toIso8601String(),
      sessionNumber: sessionNumber,
      score: score,
      maxScore: maxScore, // ⚡ تمرير الدرجة النهائية كما هي
      notes: notesController.text.trim(),
    );

    showSnack('✅ تم إضافة درجة التسميع بنجاح', color: Colors.green);

    // تفريغ الحقول
    selectedStudentId = null;
    codeController.clear();
    scoreController.clear();
    notesController.clear();
    selectedDate = DateTime.now();

    FocusScope.of(context).requestFocus(codeFocus);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title:
              const Text('إضافة تسميع', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.teal[700],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // اختيار السنة الدراسية
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'اختر السنة الدراسية',
                  border: OutlineInputBorder(),
                ),
                initialValue: selectedYear,
                items: years.map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year),
                  );
                }).toList(),
                onChanged: (year) {
                  if (year != null) onYearSelected(year);
                },
              ),
              const SizedBox(height: 20),

              // رقم التسميع (تلقائي)
              TextField(
                controller: sessionNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'رقم التسميع',
                ),
              ),

              const SizedBox(height: 10),

              // الدرجة النهائية
              TextField(
                controller: maxScoreController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'الدرجة النهائية',
                ),
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(codeFocus),
              ),
              const SizedBox(height: 20),

              // كود الطالب
              TextField(
                controller: codeController,
                focusNode: codeFocus,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => findStudentByCode(),
                decoration: const InputDecoration(
                  labelText: 'كود الطالب',
                ),
              ),
              const SizedBox(height: 10),

              // اختيار الطالب من الدروب داون
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'أو اختر الطالب'),
                items: students.map((student) {
                  return DropdownMenuItem<int>(
                    value: student['id'],
                    child: Text(student['name']),
                  );
                }).toList(),
                initialValue: selectedStudentId,
                onChanged: (val) {
                  setState(() {
                    selectedStudentId = val;
                    codeController.clear();
                  });
                },
              ),
              const SizedBox(height: 10),

              // الدرجة
              TextField(
                controller: scoreController,
                focusNode: scoreFocus,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(notesFocus),
                decoration: const InputDecoration(
                  labelText: 'الدرجة',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d*')), // أرقام و عشري
                ],
              ),
              const SizedBox(height: 10),

              // الملاحظات
              TextField(
                controller: notesController,
                focusNode: notesFocus,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => saveRecitation(),
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 10),

              // اختيار التاريخ
              Row(
                children: [
                  Text(
                      'التاريخ: ${selectedDate.toLocal().toString().split(' ')[0]}'),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: pickDate,
                    child: const Text('اختر التاريخ'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // زر الحفظ
              ElevatedButton(
                onPressed: saveRecitation,
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.teal[800]),
                child: const Text('حفظ التسميع',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
