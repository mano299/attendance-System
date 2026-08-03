import 'package:attendance/screens/students_category_view.dart';
import 'package:flutter/material.dart';
import '../db_helper.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  String? selectedYear;
  String? selectedMonth;
  Map<String, dynamic>? selectedStudent;

  List<String> years = [];
  final List<String> months = [
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

  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filteredStudents = [];
  bool showSuggestions = false;

  // حالة اختيار الفئة: null = لا فلترة، 'paid' = دافعين، 'unpaid' = متخلفين
  String? showCategory;

  final TextEditingController amountController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  // Focus nodes
  final FocusNode yearFocus = FocusNode();
  final FocusNode monthFocus = FocusNode();
  final FocusNode codeFocus = FocusNode();
  final FocusNode searchFocus = FocusNode();
  final FocusNode amountFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    loadYears();
  }

  @override
  void dispose() {
    yearFocus.dispose();
    monthFocus.dispose();
    codeFocus.dispose();
    searchFocus.dispose();
    amountFocus.dispose();
    super.dispose();
  }

  Future<void> loadYears() async {
    years = await DBHelper.getAllYears();
    setState(() {});
  }

  Future<void> loadStudentsByYear(String year) async {
    students = await DBHelper.getStudentsByYear(year);
    filteredStudents = List.from(students);
    setState(() {});
  }

  // فلترة الطلاب حسب الكود أو الاسم
  void filterStudents(String query) {
    final lower = query.toLowerCase();
    filteredStudents = students.where((s) {
      final name = s['name'].toString().toLowerCase();
      final code = s['code'].toString();
      return name.contains(lower) || code.contains(query);
    }).toList();

    setState(() {
      showSuggestions = filteredStudents.isNotEmpty && query.isNotEmpty;
    });
  }

  // اختيار طالب بالكود
  Future<void> selectStudentByCode() async {
    if (selectedYear == null || codeController.text.trim().isEmpty) return;

    final student = await DBHelper.getStudentByCodeAndYear(
      codeController.text.trim(),
      selectedYear!,
    );

    if (student != null) {
      setState(() {
        selectedStudent = student;
        searchController.text = student['name'];
      });
      FocusScope.of(context).requestFocus(amountFocus);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم العثور على طالب بهذا الكود'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // تسجيل الدفع
  Future<void> savePayment() async {
    if (selectedYear == null ||
        selectedMonth == null ||
        selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اختر السنة والشهر والطالب'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountController.text.trim());

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل مبلغ صحيح'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final monthValue = "$selectedYear-$selectedMonth";

    final alreadyPaid = await DBHelper.hasPaidBeforeMonth(
      selectedStudent!['id'],
      selectedYear!,
      monthValue,
    );

    if (alreadyPaid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('هذا الطالب دفع بالفعل لهذا الشهر'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await DBHelper.insertPayment(
      selectedStudent!['id'],
      amount,
      selectedYear!,
      monthValue,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تسجيل الدفع للطالب: ${selectedStudent!['name']}'),
        backgroundColor: Colors.green,
      ),
    );

    amountController.clear();
    codeController.clear();
    searchController.clear();

    setState(() {
      selectedStudent = null;
      filteredStudents = List.from(students);
      showSuggestions = false;
    });

    FocusScope.of(context).requestFocus(codeFocus);
  }

  // تحديث قائمة الطلاب حسب الفئة
  Future<void> filterStudentsByCategory(String? category) async {
    if (selectedYear == null || selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اختر السنة والشهر أولاً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      showCategory = category;
    });

    final monthValue = "$selectedYear-$selectedMonth";

    if (category == 'paid') {
      students = await DBHelper.getStudentsByYear(selectedYear!);
      filteredStudents = [];
      for (var s in students) {
        final paid = await DBHelper.hasPaidBeforeMonth(
            s['id'], selectedYear!, monthValue);
        if (paid) filteredStudents.add(s);
      }
    } else if (category == 'unpaid') {
      students = await DBHelper.getStudentsByYear(selectedYear!);
      filteredStudents = [];
      for (var s in students) {
        final paid = await DBHelper.hasPaidBeforeMonth(
            s['id'], selectedYear!, monthValue);
        if (!paid) filteredStudents.add(s);
      }
    } else {
      filteredStudents = List.from(students);
    }

    showSuggestions = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل المصروفات'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // زرارين لتصفية الطلاب
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                StudentsCategoryView(category: 'paid'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: const Text(
                          'الدافعين',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                StudentsCategoryView(category: 'unpaid'),
                          ),
                        );
                      },
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: const Text(
                          'المتخلفين عن الدفع',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // باقي الكود الأساسي (السنة، الشهر، الكود، البحث، المبلغ، الخصم، زر تسجيل)
              const Text('اختر السنة الدراسية',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedYear,
                focusNode: yearFocus,
                items: years
                    .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                    .toList(),
                onChanged: (value) {
                  selectedYear = value;
                  selectedStudent = null;
                  amountController.clear();
                  codeController.clear();
                  searchController.clear();
                  loadStudentsByYear(value!);
                  FocusScope.of(context).requestFocus(monthFocus);
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('اختر الشهر',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedMonth,
                focusNode: monthFocus,
                items: months
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMonth = value;
                  });
                  FocusScope.of(context).requestFocus(codeFocus);
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('أدخل كود الطالب',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: codeController,
                      focusNode: codeFocus,
                      onSubmitted: (_) => selectStudentByCode(),
                      decoration: const InputDecoration(
                        hintText: 'كود الطالب',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.code),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: selectStudentByCode,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: const Text(
                      'بحث',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('أو ابحث بالاسم',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: searchController,
                focusNode: searchFocus,
                onChanged: filterStudents,
                onSubmitted: (_) {
                  if (filteredStudents.isNotEmpty) {
                    setState(() {
                      selectedStudent = filteredStudents.first;
                    });
                    FocusScope.of(context).requestFocus(amountFocus);
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'اكتب الاسم أو الكود',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              if (showSuggestions)
                Container(
                  height: 150,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white,
                  ),
                  child: ListView.builder(
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final s = filteredStudents[index];
                      return ListTile(
                        title: Text('${s['name']} - ${s['code']}'),
                        onTap: () {
                          setState(() {
                            selectedStudent = s;
                            searchController.text = s['name'];
                            showSuggestions = false;
                          });
                          FocusScope.of(context).requestFocus(amountFocus);
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                focusNode: amountFocus,
                keyboardType: TextInputType.number,
                textInputAction:
                    TextInputAction.done, // مهم عشان الـ Enter يشتغل كـ "done"
                onSubmitted: (_) =>
                    savePayment(), // هنا نفذ تسجيل الدفع مباشرة عند الضغط Enter
                decoration: const InputDecoration(
                  labelText: 'المبلغ المدفوع',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                ),
              ),

              const SizedBox(height: 16),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: savePayment,
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text('تسجيل المصروفات',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
