import 'package:attendance/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController parentPhoneController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  // 👇 FocusNodes لكل حقل
  final FocusNode nameFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();
  final FocusNode parentPhoneFocus = FocusNode();
  final FocusNode yearFocus = FocusNode();
  final FocusNode codeFocus = FocusNode();
  String? selectedYear;
  String? selectedGroup;
  List<Map<String, dynamic>> groups = [];
  final List<String> years = [
  'الصف الأول الثانوي',
  'الصف الثاني الثانوي',
  'الصف الثالث الثانوي',
];

  @override
  void initState() {
    super.initState();
    sqfliteFfiInit(); // ضروري لتشغيل القاعدة على ويندوز
    databaseFactory = databaseFactoryFfi;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    parentPhoneController.dispose();
    codeController.dispose();

    nameFocus.dispose();
    phoneFocus.dispose();
    parentPhoneFocus.dispose();
    yearFocus.dispose();
    codeFocus.dispose();

    super.dispose();
  }

  Future<void> loadGroups(String year) async {
  final result = await DBHelper.getGroupsByYear(year);

  setState(() {
    groups = List<Map<String, dynamic>>.from(result);
    selectedGroup = null;
  });
}

  Future<void> generateStudentCode() async {
    codeController.text = await DBHelper.generateNextCode();
  }

  Future<void> insertStudent(
    String name,
    String phone,
    String parentPhone,
    String year,
    String code,
    BuildContext context,
  ) async {
    final db = await DBHelper.openDB();
    final existing =
        await db.query('students', where: 'code = ?', whereArgs: [code]);

    if (existing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❗ الكود مستخدم بالفعل'),
        ),
      );
      return;
    }

    await DBHelper.insertStudent(
      name: name,
      phone: phone,
      parentPhone: parentPhone,
      year: year,
      code: code,
      groupId: int.parse(selectedGroup!),
    );

    nameController.clear();
    phoneController.clear();
    parentPhoneController.clear();
    codeController.clear();

    setState(() {
      selectedYear = null;
      selectedGroup = null;
      groups.clear();
    });

    FocusScope.of(context).requestFocus(nameFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('➕ إضافة طالب جديد'),
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  focusNode: nameFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    FocusScope.of(context).requestFocus(phoneFocus);
                  },
                  decoration: InputDecoration(
                    labelText: '👤 اسم الطالب',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: phoneController,
                  focusNode: phoneFocus,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(11),
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    FocusScope.of(context).requestFocus(parentPhoneFocus);
                  },
                  decoration: InputDecoration(
                    labelText: '📞 رقم الطالب',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: parentPhoneController,
                  focusNode: parentPhoneFocus,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(11),
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    FocusScope.of(context).requestFocus(yearFocus);
                  },
                  decoration: InputDecoration(
                    labelText: '👨‍👩‍👧‍👦 رقم ولي الأمر',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  focusNode: yearFocus,
                  decoration: InputDecoration(
                    labelText: '📚 السنة الدراسية',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: selectedYear,
                  onChanged: (value) async {
                    selectedYear = value;

                    if (value != null) {
                      await loadGroups(value);
                    }

                    setState(() {});

                    FocusScope.of(context).requestFocus(codeFocus);
                  },
                  items: years
                      .map((year) =>
                          DropdownMenuItem(value: year, child: Text(year)))
                      .toList(),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: selectedGroup,
                  decoration: const InputDecoration(
                    labelText: '👥 المجموعة',
                    border: OutlineInputBorder(),
                  ),
                  items: groups.map((group) {
                    return DropdownMenuItem<String>(
                      value: group['id'].toString(),
                      child: Text(group['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedGroup = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: codeController,
                        focusNode: codeFocus,
                        decoration: InputDecoration(
                          labelText: '🔢 الكود التلقائي',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: generateStudentCode,
                      child: Text('توليد كود'),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      String name = nameController.text.trim();
                      String phone = phoneController.text.trim();
                      String year = selectedYear ?? '';
                      String code = codeController.text.trim();

                      if (name.isEmpty ||
                          phone.isEmpty ||
                          year.isEmpty ||
                          code.isEmpty ||
                          selectedGroup == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('❗ برجاء ملئ جميع البيانات')),
                        );
                      } else if (phone.length < 11) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('📵 رقم الهاتف يجب ألا يقل عن 11 رقم')),
                        );
                      } else {
                        String parentPhone = parentPhoneController.text.trim();
                        await insertStudent(
                          name,
                          phone,
                          parentPhone,
                          year,
                          code,
                          context,
                        );

                        if (!mounted) return;

                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text('✅ تم'),
                            content:
                                Text('✅ تم إضافة $name بنجاح (الكود: $code)'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('موافق'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        textStyle: TextStyle(fontSize: 18)),
                    child: Text('📥 إضافة الطالب'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
