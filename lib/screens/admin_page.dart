import 'package:attendance/db_helper.dart';
import 'package:attendance/screens/fees_management_page.dart';
import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final groupNameController = TextEditingController();

  String? selectedYearForGroup;

  final List<String> years = [
  'الصف الأول الثانوي',
  'الصف الثاني الثانوي',
  'الصف الثالث الثانوي',
];

  final Map<String, bool> days = {
    'السبت': false,
    'الأحد': false,
    'الاثنين': false,
    'الثلاثاء': false,
    'الأربعاء': false,
    'الخميس': false,
    'الجمعة': false,
  };
  Widget buildGroupsView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إدارة المجموعات',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: groupNameController,
            decoration: const InputDecoration(
              labelText: 'اسم المجموعة',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            initialValue: selectedYearForGroup,
            decoration: const InputDecoration(
              labelText: 'السنة الدراسية',
              border: OutlineInputBorder(),
            ),
            items: years.map((year) {
              return DropdownMenuItem(
                value: year,
                child: Text(year),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedYearForGroup = value;
              });
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'أيام المجموعة',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Wrap(
            spacing: 10,
            children: days.keys.map((day) {
              return FilterChip(
                label: Text(day),
                selected: days[day]!,
                onSelected: (value) {
                  setState(() {
                    days[day] = value;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('حفظ المجموعة'),
            onPressed: () async {
              if (groupNameController.text.isEmpty ||
    selectedYearForGroup == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('برجاء إدخال اسم المجموعة واختيار السنة'),
    ),
  );
  return;
}

              final selectedDays = days.entries
                  .where((e) => e.value)
                  .map((e) => e.key)
                  .join(',');

              await DBHelper.addGroup(
                groupNameController.text,
                selectedYearForGroup!,
                selectedDays,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حفظ المجموعة'),
                ),
              );

              groupNameController.clear();

              setState(() {
                selectedYearForGroup = null;

                for (var key in days.keys) {
                  days[key] = false;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  String? selectedPage;
  Map<String, double> monthlyIncome = {}; // دخل كل شهر

  @override
  void initState() {
    super.initState();
    loadMonthlyIncome();
  }

  Future<void> loadMonthlyIncome() async {
    // استدعاء دالة من DBHelper ترجع الدخل لكل شهر
    Map<String, double> income = await DBHelper.getMonthlyIncome();
    setState(() {
      monthlyIncome = income;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإدارة')),
      body: Row(
        children: [
          // القائمة الجانبية
          Container(
            width: 250,
            color: Colors.grey[200],
            child: ListView(
              children: [
                adminCard(
                  title: 'إدارة الأسعار',
                  color: Colors.blue[600]!,
                  icon: Icons.attach_money,
                  onTap: () {
                    setState(() {
                      selectedPage = 'fees';
                    });
                  },
                ),
                adminCard(
                  title: 'إدارة المجموعات',
                  color: Colors.purple,
                  icon: Icons.groups,
                  onTap: () {
                    setState(() {
                      selectedPage = 'groups';
                    });
                  },
                ),
                adminCard(
                  title: 'إضافة يوزرز',
                  color: Colors.green[600]!,
                  icon: Icons.person_add,
                  onTap: () {
                    showAddUserDialog();
                  },
                ),
                adminCard(
                  title: 'الدخل الشهري',
                  color: Colors.orange[600]!,
                  icon: Icons.bar_chart,
                  onTap: () {
                    setState(() {
                      selectedPage = 'income';
                    });
                  },
                ),
              ],
            ),
          ),

          // محتوى الصفحة
          Expanded(
            child: Builder(
              builder: (context) {
                switch (selectedPage) {
                  case 'fees':
                    return const FeesManagementPage();

                  case 'groups':
                    return buildGroupsView();

                  case 'income':
                    return buildMonthlyIncomeView();

                  default:
                    return const Center(
                      child: Text('اختر صفحة من القائمة الجانبية'),
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget adminCard({
    required String title,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }

  // صفحة عرض الدخل الشهري
  Widget buildMonthlyIncomeView() {
    if (monthlyIncome.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الدخل الشهري لكل شهر',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: monthlyIncome.entries.map((entry) {
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading:
                        Icon(Icons.calendar_month, color: Colors.orange[600]),
                    title: Text(entry.key), // اسم الشهر
                    trailing: Text(
                      '${entry.value.toStringAsFixed(2)} ج',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // داخل _AdminPageState

// --- دالة عرض الـ Dialog لإضافة مستخدم ---
  void showAddUserDialog() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        String selectedRole = 'teacher'; // هنا داخل builder

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('➕ إضافة مستخدم جديد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration:
                        const InputDecoration(labelText: 'اسم المستخدم'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'كلمة المرور'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('مدرس'),
                          value: 'teacher',
                          groupValue: selectedRole,
                          onChanged: (val) {
                            if (val != null) setState(() => selectedRole = val);
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('سكرتير'),
                          value: 'secretary',
                          groupValue: selectedRole,
                          onChanged: (val) {
                            if (val != null) setState(() => selectedRole = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  final username = usernameController.text.trim();
                  final password = passwordController.text.trim();

                  if (username.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❗ برجاء ملء جميع الحقول')),
                    );
                    return;
                  }

                  bool success = await DBHelper.addUser(
                    username: username,
                    password: password,
                    role: selectedRole,
                  );

                  if (success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ تم إضافة المستخدم بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❗ اسم المستخدم موجود بالفعل لهذا الدور'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('إضافة'),
              ),
            ],
          ),
        );
      },
    );
  }
}
