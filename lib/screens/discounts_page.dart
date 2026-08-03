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
  final FocusNode amountFocus = FocusNode();
  final FocusNode reasonFocus = FocusNode();

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
    if (amountController.text.isEmpty || reasonController.text.isEmpty) return;

    await DBHelper.insertDiscount(
      double.parse(amountController.text),
      reasonController.text,
    );

    amountController.clear();
    reasonController.clear();
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
            'الخصومات',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: amountController,
                      focusNode: amountFocus,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) {
                        FocusScope.of(context).requestFocus(reasonFocus);
                      },
                      decoration: const InputDecoration(
                        labelText: 'مبلغ الخصم',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: reasonController,
                      focusNode: reasonFocus,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => addDiscount(),
                      decoration: const InputDecoration(
                        labelText: 'سبب الخصم',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: addDiscount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: const Text(
                        'إضافة',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'جميع الخصومات',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: DataTable(
                        headingRowColor:
                            WidgetStateProperty.all(Colors.grey[200]),
                        columnSpacing: 40,
                        columns: const [
                          DataColumn(label: Text('المبلغ')),
                          DataColumn(label: Text('السبب')),
                          DataColumn(label: Text('التاريخ')),
                        ],
                        rows: discounts.map((d) {
                          return DataRow(cells: [
                            DataCell(Text(
                              d['amount'].toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            )),
                            DataCell(Text(d['reason'])),
                            DataCell(Text(d['date'])),
                          ]);
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
