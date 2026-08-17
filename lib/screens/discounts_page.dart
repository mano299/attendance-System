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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إدارة الخصومات',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
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
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowHeight: 55,
                  dataRowMinHeight: 65,
                  dataRowMaxHeight: 65,
                  headingRowColor: WidgetStateProperty.all(
                    Colors.grey.shade100,
                  ),
                  columns: const [
                    DataColumn(
                      label: Text('المبلغ'),
                    ),
                    DataColumn(
                      label: Text('السبب'),
                    ),
                    DataColumn(
                      label: Text('التاريخ'),
                    ),
                    DataColumn(
                      label: Text('اليوم'),
                    ),
                    DataColumn(
                      label: Text('حذف'),
                    ),
                  ],
                  rows: discounts.map((d) {
                    final date = DateTime.tryParse(
                      d['date'].toString(),
                    );

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            '${d['amount']} ج',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              d['reason'],
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            d['date'].toString().split(' ').first,
                          ),
                        ),
                        DataCell(
                          Text(
                            date == null ? '-' : getArabicDay(date),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            onPressed: () async {
                              final result = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text(
                                    'حذف الخصم',
                                  ),
                                  content: const Text(
                                    'هل تريد حذف هذا الخصم؟',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context, false);
                                      },
                                      child: const Text(
                                        'إلغاء',
                                      ),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        Navigator.pop(context, true);
                                      },
                                      child: const Text(
                                        'حذف',
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (result == true) {
                                deleteDiscount(
                                  d['id'],
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
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
