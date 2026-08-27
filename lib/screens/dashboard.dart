import 'package:attendance/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

bool isTeacher = false;

class _DashboardScreenState extends State<DashboardScreen> {
  int paidCount = 0;
  int unpaidCount = 0;
  int totalAmount = 0;
  bool isLoading = true;
  int todayPaidCount = 0;
  int todayPaidAmount = 0;
  

  List<Map<String, dynamic>> paymentsByYear = [];
  List<Map<String, dynamic>> studentsByYear = [];

  @override
  void initState() {
    super.initState();
    loadRoleAndSummary();
  }

  Future<void> loadRoleAndSummary() async {
    final prefs = await SharedPreferences.getInstance();
    isTeacher = prefs.getBool('isTeacher') ?? false;
    await loadSummary();
  }

  int totalDiscountsAmount = 0;

  Future<void> loadSummary() async {
    final summary = await DBHelper.fetchPaymentsSummary();
    final todaySummary = await DBHelper.fetchTodayPaymentsSummary();
    final yearSummary = await DBHelper.fetchPaymentsByYearWithToday();
    final studentsSummary = await DBHelper.fetchStudentsPaidUnpaidByYear();
    final discountsSummary = await DBHelper.fetchTotalDiscounts(); // 🟢 جديد

    setState(() {
      paidCount = summary['paid'];
      unpaidCount = summary['unpaid'];
      totalAmount = summary['total'];
      todayPaidCount = todaySummary['paidToday']!;
      todayPaidAmount = todaySummary['amountToday']!;
      paymentsByYear = yearSummary;
      studentsByYear = studentsSummary;
      totalDiscountsAmount = discountsSummary ?? 0; // 🟢 تعيين الإجمالي
      isLoading = false;
    });
  }

  Future<void> showSelectiveResetDialog() async {
  final passwordController = TextEditingController();

  bool students = false;
  bool groups = false;
  bool attendance = false;
  bool recitations = false;
  bool payments = false;
  bool discounts = false;
  bool sessions = false;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.delete_forever,
                  color: Colors.red,
                ),
                SizedBox(width: 8),
                Text('إعادة ضبط البيانات'),
              ],
            ),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'اختر البيانات التي تريد حذفها:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 15),

                    CheckboxListTile(
                      value: students,
                      title: const Text('الطلاب'),
                      secondary: const Icon(Icons.people),
                      onChanged: (value) {
                        setDialogState(() {
                          students = value ?? false;
                        });
                      },
                    ),

                    CheckboxListTile(
                      value: groups,
                      title: const Text('المجموعات'),
                      secondary: const Icon(Icons.groups),
                      onChanged: (value) {
                        setDialogState(() {
                          groups = value ?? false;
                        });
                      },
                    ),

                    CheckboxListTile(
                      value: attendance,
                      title: const Text('الحضور'),
                      secondary: const Icon(Icons.fact_check),
                      onChanged: (value) {
                        setDialogState(() {
                          attendance = value ?? false;
                        });
                      },
                    ),

                    CheckboxListTile(
                      value: recitations,
                      title: const Text('التسميعات'),
                      secondary: const Icon(Icons.menu_book),
                      onChanged: (value) {
                        setDialogState(() {
                          recitations = value ?? false;
                        });
                      },
                    ),

                    CheckboxListTile(
                      value: payments,
                      title: const Text('المدفوعات'),
                      secondary: const Icon(Icons.payments),
                      onChanged: (value) {
                        setDialogState(() {
                          payments = value ?? false;
                        });
                      },
                    ),

                    CheckboxListTile(
                      value: discounts,
                      title: const Text('الخصومات'),
                      secondary: const Icon(Icons.money_off),
                      onChanged: (value) {
                        setDialogState(() {
                          discounts = value ?? false;
                        });
                      },
                    ),

                    CheckboxListTile(
                      value: sessions,
                      title: const Text('الحصص'),
                      secondary: const Icon(Icons.calendar_month),
                      onChanged: (value) {
                        setDialogState(() {
                          sessions = value ?? false;
                        });
                      },
                    ),

                    const Divider(),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('إلغاء'),
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (passwordController.text != '123456') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('كلمة المرور غير صحيحة'),
                      ),
                    );
                    return;
                  }

                  final hasSelection =
                      students ||
                      groups ||
                      attendance ||
                      recitations ||
                      payments ||
                      discounts ||
                      sessions;

                  if (!hasSelection) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'اختر على الأقل نوعًا واحدًا من البيانات',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(dialogContext);

                  await showResetConfirmation(
                    students: students,
                    groups: groups,
                    attendance: attendance,
                    recitations: recitations,
                    payments: payments,
                    discounts: discounts,
                    sessions: sessions,
                  );
                },
                child: const Text('متابعة'),
              ),
            ],
          );
        },
      );
    },
  );

  passwordController.dispose();
}
Future<void> showResetConfirmation({
  required bool students,
  required bool groups,
  required bool attendance,
  required bool recitations,
  required bool payments,
  required bool discounts,
  required bool sessions,
}) async {
  final selected = <String>[];

  if (students) selected.add('الطلاب');
  if (groups) selected.add('المجموعات');
  if (attendance) selected.add('الحضور');
  if (recitations) selected.add('التسميعات');
  if (payments) selected.add('المدفوعات');
  if (discounts) selected.add('الخصومات');
  if (sessions) selected.add('الحصص');

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          '⚠️ تأكيد الحذف',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أنت على وشك حذف:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            ...selected.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(item),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              '⚠️ لا يمكن التراجع عن هذه العملية.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('إلغاء'),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await DBHelper.resetSelectedData(
                  students: students,
                  groups: groups,
                  attendance: attendance,
                  recitations: recitations,
                  payments: payments,
                  discounts: discounts,
                  sessions: sessions,
                );

                if (!mounted) return;

                Navigator.pop(context);

                await loadSummary();

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.green,
                    content: Text(
                      'تم حذف البيانات المحددة بنجاح',
                    ),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(
                      e.toString().replaceFirst(
                            'Exception: ',
                            '',
                          ),
                    ),
                  ),
                );
              }
            },
            child: const Text('حذف نهائي'),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          if (isTeacher)
            IconButton(
              icon: const Icon(
                Icons.delete_forever,
                color: Colors.white,
              ),
              tooltip: 'إعادة ضبط النظام',
              onPressed: showSelectiveResetDialog,
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  buildFancyCard("عدد الطلاب اللي دفعوا اليوم", todayPaidCount,
                      Icons.today, Colors.cyan, Colors.blue),
                  buildFancyCard("المبلغ المدفوع اليوم", todayPaidAmount,
                      Icons.monetization_on, Colors.deepPurple, Colors.purple),
                  buildFancyCard("إجمالي الخصومات", totalDiscountsAmount,
                      Icons.money_off, Colors.orange, Colors.deepOrange),
                  const SizedBox(height: 12),
                  if (isTeacher) ...[
                    buildFancyCard("عدد الطلاب اللي دفعوا (إجمالًا)", paidCount,
                        Icons.check_circle, Colors.green, Colors.teal),
                    buildFancyCard("عدد الطلاب اللي ما دفعوش", unpaidCount,
                        Icons.cancel, Colors.red, Colors.orange),
                    buildFancyCard(
                        "إجمالي المبلغ المدفوع",
                        totalAmount,
                        Icons.account_balance_wallet,
                        Colors.blue,
                        Colors.indigo),
                    const SizedBox(height: 25),
                    sectionTitle("📊 المصاريف حسب السنوات"),
                    const SizedBox(height: 12),
                    Column(
                      children: paymentsByYear.map((data) {
                        final year = data['year'];
                        final totalPaid = data['totalPaid'] ?? 0;
                        final todayPaid = data['todayPaid'] ?? 0;
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 8,
                          margin: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 5),
                          color: Colors.teal.shade50,
                          shadowColor: Colors.teal.withValues(alpha: 0.3),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.school,
                                  color: Colors.teal, size: 30),
                            ),
                            title: Text(
                              "$year",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 19,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 5),
                                Text(
                                  "مدفوع اليوم: $todayPaid",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  "إجمالي المدفوع: $totalPaid",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.teal.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 25),
                    sectionTitle("👥 حالة الطلاب حسب الدفعات"),
                    const SizedBox(height: 12),
                    Column(
                      children: studentsByYear.map((data) {
                        final year = data['year'];
                        final paid = data['paidCount'];
                        final unpaid = data['unpaidCount'];

                        return FutureBuilder<int>(
                          future: DBHelper.getYearFee(year),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox();
                            }
                            final yearFee = snapshot.data!;
                            final remaining = unpaid * yearFee;

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 8,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 16),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange.shade200,
                                      Colors.deepOrange.shade400
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 26,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.8),
                                    child: const Icon(Icons.people,
                                        color: Colors.deepOrange, size: 30),
                                  ),
                                  title: Text(
                                    "$year",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "المصاريف: $yearFee ج.م\n"
                                    "دافعين: $paid\n"
                                    "غير دافعين: $unpaid\n"
                                    "المبلغ المتبقي: $remaining ج.م",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  /// 🎨 كارت متدرج بالألوان
  Widget buildFancyCard(
      String title, int value, IconData icon, Color c1, Color c2) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [c1.withValues(alpha: 0.7), c2.withValues(alpha: 0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: c2.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(2, 4))
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        leading: Icon(icon, color: Colors.white, size: 36),
        title: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        trailing: Text(
          value.toString(),
          style: const TextStyle(
              fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// 🏷️ عنوان القسم
  Widget sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
    );
  }
}
