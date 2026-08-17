import 'package:flutter/material.dart';
import '../db_helper.dart';

class GroupsManagementView extends StatefulWidget {
  const GroupsManagementView({super.key});

  @override
  State<GroupsManagementView> createState() =>
      _GroupsManagementViewState();
}

class _GroupsManagementViewState
    extends State<GroupsManagementView> {
  List<Map<String, dynamic>> groups = [];
  List<Map<String, dynamic>> filtered = [];

  final searchController = TextEditingController();

  final years = const [
    'الصف الأول الثانوي',
    'الصف الثاني الثانوي',
    'الصف الثالث الثانوي',
  ];

  @override
  void initState() {
    super.initState();
    loadGroups();
  }

  Future<void> loadGroups() async {
    final data = await DBHelper.getAllGroups();

    setState(() {
      groups = data;
      filtered = data;
    });
  }

  void search(String value) {
    setState(() {
      filtered = groups.where((group) {
        return group['name']
            .toString()
            .toLowerCase()
            .contains(value.toLowerCase());
      }).toList();
    });
  }

  Future<void> showGroupDialog({
    Map<String, dynamic>? group,
  }) async {
    final nameController =
        TextEditingController(text: group?['name']);

    String? selectedYear = group?['year'];

    Map<String, bool> days = {
      'السبت': false,
      'الأحد': false,
      'الاثنين': false,
      'الثلاثاء': false,
      'الأربعاء': false,
      'الخميس': false,
      'الجمعة': false,
    };

    if (group != null) {
      final currentDays =
          group['days'].toString().split(',');

      for (final d in currentDays) {
        if (days.containsKey(d)) {
          days[d] = true;
        }
      }
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                group == null
                    ? 'إضافة مجموعة'
                    : 'تعديل المجموعة',
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المجموعة',
                        ),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: selectedYear,
                        items: years.map((e) {
                          return DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setDialogState(() {
                            selectedYear = v;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'السنة الدراسية',
                        ),
                      ),
                      const SizedBox(height: 15),
                      Wrap(
                        spacing: 8,
                        children: days.keys.map((day) {
                          return FilterChip(
                            label: Text(day),
                            selected: days[day]!,
                            onSelected: (value) {
                              setDialogState(() {
                                days[day] = value;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final selectedDays = days.entries
                        .where((e) => e.value)
                        .map((e) => e.key)
                        .join(',');

                    if (group == null) {
                      await DBHelper.addGroup(
                        nameController.text,
                        selectedYear ?? '',
                        selectedDays,
                      );
                    } else {
                      await DBHelper.updateGroup(
                        id: group['id'],
                        name: nameController.text,
                        year: selectedYear ?? '',
                        days: selectedDays,
                      );
                    }

                    Navigator.pop(context);

                    await loadGroups();
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deleteGroup(
      Map<String, dynamic> group) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل تريد حذف ${group['name']} ؟',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      await DBHelper.deleteGroup(group['id']);

      await loadGroups();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'بحث...',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () =>
                    showGroupDialog(),
                icon: const Icon(Icons.add),
                label: const Text(
                  'إضافة مجموعة',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              elevation: 3,
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 40,
                  columns: const [
                    DataColumn(
                      label: Text('اسم المجموعة'),
                    ),
                    DataColumn(
                      label: Text('السنة'),
                    ),
                    DataColumn(
                      label: Text('الأيام'),
                    ),
                    DataColumn(
                      label: Text('عدد الطلاب'),
                    ),
                    DataColumn(
                      label: Text('الإجراءات'),
                    ),
                  ],
                  rows: filtered.map((group) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(group['name']),
                        ),
                        DataCell(
                          Text(group['year']),
                        ),
                        DataCell(
                          Text(group['days']),
                        ),
                        DataCell(
                          Text(
                            group['students_count']
                                .toString(),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  showGroupDialog(
                                    group: group,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  deleteGroup(group);
                                },
                              ),
                            ],
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