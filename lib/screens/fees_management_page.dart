import 'package:attendance/db_helper.dart';
import 'package:flutter/material.dart';

class FeesManagementPage extends StatefulWidget {
  const FeesManagementPage({super.key});

  @override
  State<FeesManagementPage> createState() => _FeesManagementPageState();
}

class _FeesManagementPageState extends State<FeesManagementPage> {
  TextEditingController passwordController = TextEditingController();
  TextEditingController feeController = TextEditingController();

  bool authenticated = false;
  final String pagePassword = 'payments12';

  String? selectedYear;
  int selectedFeeAmount = 0;

  List<String> secondaryYears = [
    'الصف الأول الاعدادي',
    'الصف الثاني الاعدادي',
    'الصف الثالث الاعدادي',
    'الصف الأول الثانوي',
    'الصف الثاني الثانوي',
    'الصف الثالث الثانوي',
  ];

  List<Map<String, dynamic>> filteredStudents = [];

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {
    final studentsWithPayments = await DBHelper.fetchStudentsWithPayments();
    filteredStudents = studentsWithPayments
        .where((s) => secondaryYears.contains(s['year']))
        .toList();
    setState(() {});
  }

  Future<void> saveFeeForYear(String year, int amount) async {
    await DBHelper.saveFee(year, amount);
    setState(() {
      selectedFeeAmount = amount;
    });
  }

  Future<int> getFeeForYear(String year) async {
    return await DBHelper.getYearFee(year);
  }

  Future<List<Map<String, dynamic>>> getStudentsWithRemaining() async {
    if (selectedYear == null) return [];

    final yearFee = await getFeeForYear(selectedYear!);

    return filteredStudents
        .where((s) => s['year'] == selectedYear)
        .map((student) {
      final paid = (student['totalPaid'] ?? 0).toDouble();
      final remaining = yearFee - paid;
      return {
        ...student,
        'remaining': remaining < 0 ? 0 : remaining,
        'yearFee': yearFee,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (!authenticated)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔒 أدخل كلمة المرور للوصول إلى المصاريف'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (passwordController.text == pagePassword) {
                        setState(() {
                          authenticated = true;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('🚫 كلمة المرور خاطئة')),
                        );
                      }
                    },
                    child: Text('دخول'),
                  )
                ],
              ),
            if (authenticated)
              Column(
                children: [
                  DropdownButton<String>(
                    value: selectedYear,
                    hint: Text('اختر السنة الدراسية'),
                    isExpanded: true,
                    items: secondaryYears.map((year) {
                      return DropdownMenuItem<String>(
                        value: year,
                        child: Text(year),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      selectedYear = value;
                      if (value != null) {
                        final fee = await getFeeForYear(value);
                        setState(() {
                          selectedFeeAmount = fee;
                          feeController.text = fee > 0 ? fee.toString() : '';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: feeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'أدخل المصاريف لكل دفعة',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.money),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final value = int.tryParse(feeController.text);
                      if (value == null || selectedYear == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('🚫 يرجى اختيار سنة وإدخال مبلغ صحيح')),
                        );
                        return;
                      }
                      saveFeeForYear(selectedYear!, value);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('✅ تم حفظ المصاريف للسنة $selectedYear')),
                      );
                    },
                    child: Text('تأكيد المصاريف'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 400, // حجم محدد للقائمة
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: getStudentsWithRemaining(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }
                        final students = snapshot.data!;
                        if (students.isEmpty) {
                          return Center(
                              child: Text('لا يوجد طلاب لهذه السنة.'));
                        }
                        return ListView(
                          children: students.map((student) {
                            final paid = (student['totalPaid'] ?? 0).toDouble();
                            final remaining = student['remaining'];
                            final fee = student['yearFee'];

                            return Card(
                              child: ListTile(
                                title: Text(student['name']),
                                subtitle: Text(
                                    'المصاريف: $fee   دفع: $paid   المتبقي: ${remaining < 0 ? 0 : remaining}'),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
