import 'package:flutter/material.dart';
import '../db_helper.dart';

class DiscountsPage extends StatefulWidget {
  const DiscountsPage({super.key});

  @override
  State<DiscountsPage> createState() => _DiscountsPageState();
}

class _DiscountsPageState extends State<DiscountsPage> {
  final TextEditingController amountController = TextEditingController();

  final TextEditingController reasonController = TextEditingController();

  List<Map<String, dynamic>> discounts = [];
  static const String adminPassword = "123456";
  @override
  void initState() {
    super.initState();
    loadDiscounts();
  }

  Future<void> loadDiscounts() async {
    final data = await DBHelper.getDiscounts();

    setState(() {
      discounts = data;
    });
  }

  Future<void> addDiscount() async {
    if (amountController.text.isEmpty || reasonController.text.isEmpty) {
      return;
    }

    await DBHelper.insertDiscount(
      double.parse(amountController.text),
      reasonController.text,
    );

    amountController.clear();
    reasonController.clear();

    loadDiscounts();
  }

  double get totalDiscounts => discounts.fold(
        0,
        (sum, item) => sum + (item['amount'] ?? 0),
      );

  double get todayDiscounts {
    final today = DateTime.now().toString().split(' ').first;

    return discounts
        .where(
          (e) => e['date'].toString().startsWith(today),
        )
        .fold(
          0,
          (sum, item) => sum + (item['amount'] ?? 0),
        );
  }

  double get monthDiscounts {
    final now = DateTime.now();

    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    return discounts
        .where(
          (e) => e['date'].toString().startsWith(currentMonth),
        )
        .fold(
          0,
          (sum, item) => sum + (item['amount'] ?? 0),
        );
  }

  String getArabicDay(DateTime date) {
    switch (date.weekday) {
      case 1:
        return 'الاثنين';
      case 2:
        return 'الثلاثاء';
      case 3:
        return 'الأربعاء';
      case 4:
        return 'الخميس';
      case 5:
        return 'الجمعة';
      case 6:
        return 'السبت';
      case 7:
        return 'الأحد';
      default:
        return '';
    }
  }

  Future<void> deleteDiscount(int id) async {
    await DBHelper.deleteDiscount(id);

    loadDiscounts();
  }

  Future<bool> verifyPassword() async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد العملية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'أدخل كلمة المرور لتصفير الخصومات',
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'كلمة المرور',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                controller.text == adminPassword,
              );
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إدارة الخصومات',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(
                  Icons.restart_alt,
                  color: Colors.red,
                ),
                label: const Text(
                  'تصفير الخصومات',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
                onPressed: () async {
                  final ok = await verifyPassword();

                  if (!ok) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'كلمة المرور غير صحيحة',
                          ),
                        ),
                      );
                    }
                    return;
                  }

                  await DBHelper.resetDiscounts();

                  await loadDiscounts();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'تم تصفير الخصومات بنجاح',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              statCard(
                title: 'خصومات اليوم',
                value: '${todayDiscounts.toStringAsFixed(0)} ج',
                icon: Icons.today,
                color: const Color(0xff10B981),
              ),
              const SizedBox(width: 15),
              statCard(
                title: 'خصومات الشهر',
                value: '${monthDiscounts.toStringAsFixed(0)} ج',
                icon: Icons.calendar_month,
                color: const Color(0xff3B82F6),
              ),
              const SizedBox(width: 15),
              statCard(
                title: 'إجمالي الخصومات',
                value: '${totalDiscounts.toStringAsFixed(0)} ج',
                icon: Icons.money_off,
                color: const Color(0xffEF4444),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'إضافة خصم جديد',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'مبلغ الخصم',
                            prefixIcon: Icon(Icons.money),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        flex: 4,
                        child: TextField(
                          controller: reasonController,
                          decoration: const InputDecoration(
                            labelText: 'سبب الخصم',
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      SizedBox(
                        height: 55,
                        child: FilledButton.icon(
                          onPressed: addDiscount,
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'إضافة',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          Expanded(
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Expanded(
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: DataTable(
                              columnSpacing: 0,
                              columns: const [
                                DataColumn(
                                    label: Expanded(
                                        child: Center(child: Text('المبلغ')))),
                                DataColumn(
                                    label: Expanded(
                                        child: Center(child: Text('السبب')))),
                                DataColumn(
                                    label: Expanded(
                                        child: Center(child: Text('التاريخ')))),
                                DataColumn(
                                    label: Expanded(
                                        child: Center(child: Text('اليوم')))),
                                DataColumn(
                                    label: Expanded(
                                        child:
                                            Center(child: Text('الإجراءات')))),
                              ],
                              rows: discounts.map((d) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      SizedBox(
                                        width: constraints.maxWidth * .15,
                                        child: Center(
                                          child: Text('${d['amount']} ج'),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: constraints.maxWidth * .35,
                                        child: Center(
                                          child: Text(d['reason']),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: constraints.maxWidth * .20,
                                        child: Center(
                                          child: Text(
                                            d['date']
                                                .toString()
                                                .split(' ')
                                                .first,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: constraints.maxWidth * .15,
                                        child: Center(
                                          child: Text('الاثنين'),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: constraints.maxWidth * .15,
                                        child: Center(
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {},
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
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

Widget statCard({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
}) {
  return Expanded(
    child: Container(
      constraints: const BoxConstraints(
        minHeight: 140,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}
