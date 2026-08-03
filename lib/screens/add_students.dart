import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
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
  final List<String> years = [
    'الصف الأول الاعدادي',
    'الصف الثاني الاعدادي',
    'الصف الثالث الاعدادي',
    'الصف الأول الثانوي',
    'الصف الثاني الثانوي',
    'الصف الثالث الثانوي'
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

  Future<Database> openDB() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'students.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
  CREATE TABLE students (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    phone TEXT,
    parent_phone TEXT,
    year TEXT,
    code TEXT
  )
''');

        await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER,
        date TEXT,
        FOREIGN KEY(student_id) REFERENCES students(id)
      )
    ''');

        await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER,
        amount REAL,
        date TEXT,
        is_paid INTEGER,
        FOREIGN KEY(student_id) REFERENCES students(id)
      )
    ''');
      },
    );
  }

  Future<void> generateStudentCode() async {
    final db = await openDB();

    final result = await db.rawQuery(
        'SELECT MAX(CAST(code AS INTEGER)) as max_code FROM students');
    int lastCode =
        int.tryParse(result.first['max_code']?.toString() ?? '0') ?? 0;

    String newCode = (lastCode + 1).toString().padLeft(3, '0');
    codeController.text = newCode;
  }

  Future<void> insertStudent(String name, String phone, String parentPhone,
      String year, String code, BuildContext context) async {
    final db = await openDB();

    // تحقق من الكود المكرر
    final existing =
        await db.query('students', where: 'code = ?', whereArgs: [code]);
    if (existing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❗ الكود مستخدم بالفعل. الرجاء توليد كود جديد')),
      );
      return;
    }

    await db.insert('students', {
      'name': name,
      'phone': phone,
      'parent_phone': parentPhone,
      'year': year,
      'code': code,
    });

    // مسح الحقول بعد الإضافة
    nameController.clear();
    phoneController.clear();
    parentPhoneController.clear();
    codeController.clear();
    setState(() {
      selectedYear = null;
    });

    FocusScope.of(context).requestFocus(nameFocus); // يبدأ من الاسم بعد الإضافة
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
                  onChanged: (value) {
                    setState(() {
                      selectedYear = value;
                    });
                    FocusScope.of(context).requestFocus(codeFocus);
                  },
                  items: years
                      .map((year) =>
                          DropdownMenuItem(value: year, child: Text(year)))
                      .toList(),
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
                    onPressed: () {
                      String name = nameController.text.trim();
                      String phone = phoneController.text.trim();
                      String year = selectedYear ?? '';
                      String code = codeController.text.trim();

                      if (name.isEmpty ||
                          phone.isEmpty ||
                          year.isEmpty ||
                          code.isEmpty) {
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
                        insertStudent(
                            name, phone, parentPhone, year, code, context);
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
