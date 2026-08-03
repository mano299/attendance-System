import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DBHelper {
  static Future<Database> openDB() async {
  

    final dbPath = await databaseFactory.getDatabasesPath();
    final path = join(dbPath, 'students.db');

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
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
  CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE,
  password TEXT,
  role TEXT
)
''');
          await db.execute('''
CREATE TABLE discounts(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  amount REAL,
  reason TEXT,
  date TEXT
)
''');

          await db.execute('''
  CREATE TABLE attendance (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id INTEGER,
    session_id INTEGER,
    date TEXT,
    time TEXT,
    FOREIGN KEY(student_id) REFERENCES students(id),
    FOREIGN KEY(session_id) REFERENCES sessions(id)
  )
''');

          await db.execute('''
  CREATE TABLE payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id INTEGER,
    amount REAL,
    month TEXT,
    date TEXT,
    is_paid INTEGER DEFAULT 1,
    FOREIGN KEY(student_id) REFERENCES students(id)
  )
''');

          await db.execute('''
            CREATE TABLE meta (
              key TEXT PRIMARY KEY,
              value TEXT
            )
          ''');
          await db.execute('''
  CREATE TABLE recitations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id INTEGER,
    date TEXT,
    session_number INTEGER,
    score REAL,
    max_score REAL,   -- ⚡ أضف هذا العمود
    notes TEXT
  )
''');

          await db.execute('''
  CREATE TABLE sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    year TEXT,
    date TEXT,
    session_number INTEGER
  )
''');

          await db.execute('''
  CREATE TABLE fees (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    year TEXT,
    amount INTEGER
  )
''');

          await db.insert('meta', {'key': 'last_code', 'value': '0'});
        },
      ),
    );
  }

  static Future<String> generateNextCode() async {
    final db = await openDB();

    while (true) {
      // 1. احصل على أكبر كود حالي موجود
      final result = await db.rawQuery(
          'SELECT MAX(CAST(code AS INTEGER)) as max_code FROM students');
      int lastCode = result.first['max_code'] == null
          ? 0
          : int.tryParse(result.first['max_code'].toString()) ?? 0;

      // 2. زود الكود
      lastCode++;
      final newCode = lastCode.toString().padLeft(3, '0');

      // 3. تأكد إنه غير مستخدم فعلاً (زيادة أمان)
      final existing =
          await db.query('students', where: 'code = ?', whereArgs: [newCode]);

      if (existing.isEmpty) {
        return newCode;
      }

      // لو مستخدم، عيد التكرار
    }
  }

  static Future<void> insertStudent({
    required String name,
    required String phone,
    required String parentPhone,
    required String year,
    String? code,
  }) async {
    final db = await openDB();

    code ??= await generateNextCode();

    final existing = await db.query(
      'students',
      where: 'code = ?',
      whereArgs: [code],
    );
    if (existing.isNotEmpty) {
      throw Exception('الكود مستخدم بالفعل');
    }

    await db.insert('students', {
      'name': name,
      'phone': phone,
      'parent_phone': parentPhone,
      'year': year,
      'code': code,
    });
  }

  static Future<void> updateStudent({
    required int id,
    required String name,
    required String phone,
    required String parentPhone,
    required String year,
  }) async {
    final db = await openDB();
    await db.update(
      'students',
      {
        'name': name,
        'phone': phone,
        'parent_phone': parentPhone,
        'year': year,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<Map<String, dynamic>?> getStudentByCode(String code) async {
    final db = await openDB();
    final normalizedCode = code.replaceFirst(RegExp(r'^0+'), '');
    final result = await db.query(
      'students',
      where: 'REPLACE(code, "0", "") = ? OR code = ? OR CAST(code AS TEXT) = ?',
      whereArgs: [normalizedCode, code, normalizedCode],
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<void> markStudentPresent({
    required int sessionId,
    required int studentId,
  }) async {
    final db = await openDB();
    final now = DateTime.now();

    // تأكد ما اتسجلش قبل كده
    final existing = await db.query(
      'attendance',
      where: 'session_id = ? AND student_id = ?',
      whereArgs: [sessionId, studentId],
    );

    if (existing.isEmpty) {
      await db.insert('attendance', {
        'student_id': studentId,
        'session_id': sessionId,
        'date': now.toIso8601String(),
        'time':
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      });
    }
  }

  static Future<void> insertPayment(
      int studentId, double amount, String year, String month) async {
    final db = await openDB();
    final now = DateTime.now();
    double finalAmount = amount;

    await db.insert('payments', {
      'student_id': studentId,
      'amount': finalAmount,
      'month': month,
      'date': now.toIso8601String(),
      'is_paid': 1,
    });
  }

  static Future<List<Map<String, dynamic>>> getAllStudents() async {
    final db = await openDB();
    return await db.query('students');
  }

  static Future<void> deleteStudent(int id) async {
    final db = await openDB();
    await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  static Future<bool> hasPaidBefore(int studentId) async {
    final db = await openDB();
    final now = DateTime.now();
    final currentMonth = "${now.year}-${now.month}";

    final result = await db.query(
      'payments',
      where: 'student_id = ? AND month = ?',
      whereArgs: [studentId, currentMonth],
    );

    return result.isNotEmpty;
  }

  static Future<Map<String, dynamic>> fetchPaymentsSummary() async {
    final db = await openDB();

    final paidResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT s.id) as count
      FROM students s
      LEFT JOIN payments p ON s.id = p.student_id AND p.is_paid = 1
      WHERE p.id IS NOT NULL
    ''');

    final totalStudentsResult =
        await db.rawQuery('SELECT COUNT(*) as total FROM students');

    final totalAmountResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM payments WHERE is_paid = 1');

    final paid = paidResult.first['count'] as int? ?? 0;
    final totalStudents = totalStudentsResult.first['total'] as int? ?? 0;
    final unpaid = totalStudents - paid;
    final totalPaidAmount =
        (totalAmountResult.first['total'] as num?)?.toInt() ?? 0;

    return {
      'paid': paid,
      'unpaid': unpaid,
      'total': totalPaidAmount,
    };
  }

  static Future<Map<String, int>> fetchTodayPaymentsSummary() async {
  final db = await openDB();
  final today = DateTime.now().toIso8601String().substring(0, 10);

  final paidToday = await db.rawQuery(
    'SELECT COUNT(*) as count FROM payments WHERE date LIKE ? AND is_paid = 1',
    ['$today%'],
  );

  final amountToday = await db.rawQuery(
    'SELECT SUM(amount) as total FROM payments WHERE date LIKE ? AND is_paid = 1',
    ['$today%'],
  );

  return {
    'paidToday': (paidToday.first['count'] as int?) ?? 0,
    'amountToday': (amountToday.first['total'] as num?)?.toInt() ?? 0,
  };
}

  static Future<List<Map<String, dynamic>>> fetchAttendanceByDate() async {
    final db = await openDB();
    final result = await db.rawQuery('''
      SELECT 
        date(date) as attendance_date,
        COUNT(DISTINCT student_id) as student_count
      FROM attendance
      GROUP BY attendance_date
      ORDER BY attendance_date DESC
    ''');
    return result;
  }

  static Future<List<String>> getAttendanceDates() async {
    final db = await openDB();
    final result = await db.rawQuery('''
      SELECT DISTINCT date(date) as attendance_day
      FROM attendance
      ORDER BY attendance_day DESC
    ''');
    return result.map((row) => row['attendance_day'] as String).toList();
  }

  static Future<List<Map<String, dynamic>>> getAttendanceForDate(
      String date) async {
    final db = await openDB();
    final result = await db.rawQuery('''
      SELECT s.name, s.year, a.date
      FROM attendance a
      JOIN students s ON a.student_id = s.id
      WHERE date(a.date) = ?
      ORDER BY a.date ASC
    ''', [date]);
    return result;
  }

  static Future<List<String>> getYearsForDate(String date) async {
    final db = await DBHelper.openDB();
    final result = await db.rawQuery('''
    SELECT DISTINCT students.year
    FROM attendance
    JOIN students ON attendance.student_id = students.id
    WHERE attendance.date LIKE ?
    ORDER BY students.year
  ''', ['$date%']);
    return result.map((row) => row['year'].toString()).toList();
  }

  static Future<List<Map<String, dynamic>>> getStudentsByDateAndYear(
      String date, String year) async {
    final db = await DBHelper.openDB();
    return await db.rawQuery('''
    SELECT students.name, students.year, attendance.date
    FROM attendance
    JOIN students ON attendance.student_id = students.id
    WHERE attendance.date LIKE ? AND students.year = ?
  ''', ['$date%', year]);
  }

  static Future<void> insertRecitation({
    required int studentId,
    required String date,
    int? sessionNumber,
    double score = 0,
    String? notes,
    required String year,
    int? maxScore,
  }) async {
    final db = await openDB();

    await db.insert('recitations', {
      'student_id': studentId,
      'date': date,
      'session_number': sessionNumber,
      'max_score': maxScore,
      'score': score,
      'notes': notes,
    });
  }

// جلب السنوات الدراسية (مختلفة)
  static Future<List<String>> getAllYears() async {
    final db = await openDB();
    final result =
        await db.rawQuery('SELECT DISTINCT year FROM students ORDER BY year');
    return result.map((row) => row['year'] as String).toList();
  }

// جلب أرقام التسميع (رقم الحلقة) حسب السنة
  static Future<List<int>> getSessionNumbersByYear(String year) async {
    final db = await DBHelper.openDB();
    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT DISTINCT r.session_number 
    FROM recitations r
    JOIN students s ON r.student_id = s.id
    WHERE s.year = ?
    ORDER BY r.session_number
  ''', [year]);

    return result.map((row) => row['session_number'] as int).toList();
  }

// جلب درجات الطلاب حسب السنة ورقم التسميع
  static Future<List<Map<String, dynamic>>> getGradesByYearAndSession(
      String year, int sessionNumber) async {
    final db = await openDB();
    final result = await db.rawQuery('''
    SELECT s.name, r.score, r.notes
    FROM recitations r
    JOIN students s ON r.student_id = s.id
    WHERE s.year = ? AND r.session_number = ?
  ''', [year, sessionNumber]);
    return result;
  }

  static Future<List<Map<String, dynamic>>> getAllSessions() async {
    final db = await openDB();
    return await db.query('sessions');
  }

  static Future<int> addSession(String year, String date) async {
    final db = await openDB();

    // احسب رقم الحصة الجديد
    final result = await db.rawQuery('''
    SELECT MAX(session_number) as last_number
    FROM sessions
    WHERE year = ?
  ''', [year]);

    int nextNumber = (result.first['last_number'] as int? ?? 0) + 1;

    // سجل الحصة
    return await db.insert('sessions', {
      'year': year,
      'date': date,
      'session_number': nextNumber,
    });
  }

  static Future<List<Map<String, dynamic>>> getPresentStudents(
      int sessionId) async {
    final db = await DBHelper.openDB();
    return await db.rawQuery('''
    SELECT students.id, students.name, students.code
    FROM attendance
    JOIN students ON attendance.student_id = students.id
    WHERE attendance.session_id = ?
  ''', [sessionId]);
  }

  static Future<List<Map<String, dynamic>>> getAbsentStudents(
      String year, int sessionId) async {
    final db = await DBHelper.openDB();
    return await db.rawQuery('''
    SELECT students.id, students.name, students.code, students.parent_phone
    FROM students
    WHERE students.year = ?
    AND students.id NOT IN (
      SELECT student_id FROM attendance WHERE session_id = ?
    )
  ''', [year, sessionId]);
  }

  static Future<Map<String, dynamic>?> getStudentByCodeAndYear(
      String code, String year) async {
    final db = await DBHelper.openDB();

    // جلب كل الطلاب في السنة المطلوبة
    final students = await db.query(
      'students',
      where: 'year = ?',
      whereArgs: [year],
    );

    // تطابق يدوي بعد إزالة الأصفار من اليسار
    for (var student in students) {
      final dbCode =
          student['code'].toString().replaceFirst(RegExp(r'^0+'), '');
      final inputCode = code.replaceFirst(RegExp(r'^0+'), '');
      if (dbCode == inputCode) {
        return student;
      }
    }

    return null;
  }

  static Future<int> getSessionsCountByYear(String year) async {
    final db = await openDB();
    final result = await db.rawQuery('''
    SELECT COUNT(*) as count
    FROM sessions
    WHERE year = ?
  ''', [year]);

    return result.first['count'] as int? ?? 0;
  }

  static Future<List<Map<String, dynamic>>> getSessionsByYear(
      String year) async {
    final db = await DBHelper.openDB();
    return await db.query(
      'sessions',
      where: 'year = ?',
      whereArgs: [year],
      orderBy: 'id ASC', // أو حسب التاريخ لو تحب
    );
  }

  static Future<List<Map<String, dynamic>>>
      fetchPaymentsByYearWithToday() async {
    final db = await DBHelper.openDB();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final result = await db.rawQuery('''
    SELECT s.year,
           SUM(CASE WHEN p.id IS NOT NULL THEN p.amount ELSE 0 END) AS totalPaid,
           SUM(CASE WHEN substr(p.date, 1, 10) = ? THEN p.amount ELSE 0 END) AS todayPaid
    FROM students s
    LEFT JOIN payments p ON s.id = p.student_id
    GROUP BY s.year
  ''', [today]);

    return result;
  }

  static Future<List<Map<String, dynamic>>>
      fetchStudentsPaidUnpaidByYear() async {
    final db = await DBHelper.openDB();

    final result = await db.rawQuery('''
    SELECT 
      s.year,
      SUM(CASE WHEN p.is_paid = 1 THEN 1 ELSE 0 END) as paidCount,
      SUM(CASE WHEN p.is_paid = 0 OR p.is_paid IS NULL THEN 1 ELSE 0 END) as unpaidCount
    FROM students s
    LEFT JOIN payments p ON s.id = p.student_id
    GROUP BY s.year
    ORDER BY s.year
  ''');

    return result
        .map((row) => {
              'year': row['year'],
              'paidCount': row['paidCount'] ?? 0,
              'unpaidCount': row['unpaidCount'] ?? 0,
            })
        .toList();
  }

  static Future<List<Map<String, dynamic>>> fetchStudentsWithPayments() async {
    final db = await openDB();

    final result = await db.rawQuery('''
    SELECT 
      s.id,
      s.name,
      s.code,
      s.phone,
      s.parent_phone,
      s.year,
      IFNULL(SUM(p.amount), 0) AS totalPaid
    FROM students s
    LEFT JOIN payments p ON s.id = p.student_id AND p.is_paid = 1
    GROUP BY s.id
    ORDER BY s.year, s.name
  ''');

    return result;
  }

// حفظ / تحديث مصاريف السنة
  static Future<void> saveFee(String year, int amount) async {
    final db = await openDB();

    // لو في صف للسنة، نعمل update، وإلا نعمل insert
    final existing =
        await db.query('fees', where: 'year = ?', whereArgs: [year]);
    if (existing.isEmpty) {
      await db.insert('fees', {'year': year, 'amount': amount});
    } else {
      await db.update('fees', {'amount': amount},
          where: 'year = ?', whereArgs: [year]);
    }
  }

  static Future<List<Map<String, dynamic>>> getStudentsByYear(String year,
      {String? month}) async {
    final db = await openDB();
    final selectedMonth =
        month ?? "${DateTime.now().year}-${DateTime.now().month}";

    final result = await db.rawQuery('''
    SELECT s.*, IFNULL(p.is_paid, 0) as isPaid, IFNULL(p.amount, 0) as paidAmount
    FROM students s
    LEFT JOIN payments p ON s.id = p.student_id AND p.month = ?
    WHERE s.year = ?
    ORDER BY s.name ASC
  ''', [selectedMonth, year]);

    return result;
  }

  static Future<bool> hasPaidBeforeMonth(
      int studentId, String year, String month) async {
    final db = await openDB();
    final result = await db.query(
      'payments',
      where: 'student_id = ? AND month = ?',
      whereArgs: [studentId, month],
    );
    return result.isNotEmpty;
  }

// جلب مصاريف السنة (راجع عدد صحيح)
  static Future<int> getYearFee(String year) async {
    final db = await openDB();
    final result = await db.query(
      'fees',
      where: 'year = ?',
      whereArgs: [year],
      limit: 1,
    );

    if (result.isNotEmpty) {
      final val = result.first['amount'];
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    } else {
      return 0;
    }
  }

  static Future<void> resetAllPayments() async {
    final db = await openDB();
    // نمسح كل المدفوعات من جدول payments
    await db.delete('payments');
  }

  static Future<void> resetMonthlyPayments() async {
    final db = await openDB();
    final now = DateTime.now();
    final currentMonth = "${now.year}-${now.month}";

    // نمسح فقط مدفوعات الشهر الحالي
    await db.delete(
      'payments',
      where: 'month = ?',
      whereArgs: [currentMonth],
    );
  }

  static Future<bool> loginUser(
      {required String username,
      required String password,
      required String role}) async {
    final db = await openDB();

    final result = await db.query(
      'users',
      where: 'username = ? AND password = ? AND role = ?',
      whereArgs: [username, password, role],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  static Future<int?> getLastSessionNumberByYear(String year) async {
    final db = await openDB();

    final result = await db.rawQuery('''
    SELECT MAX(r.session_number) as lastSession
    FROM recitations r
    JOIN students s ON r.student_id = s.id
    WHERE s.year = ?
  ''', [year]);

    return result.first['lastSession'] as int?;
  }

  static Future<Map<String, dynamic>> getStudentTotalScore(
      int studentId) async {
    final db = await openDB();

    final result = await db.rawQuery('''
    SELECT 
      SUM(score) as totalScore,
      SUM(max_score) as totalMax
    FROM recitations
    WHERE student_id = ?
  ''', [studentId]);

    return {
      'score': result.first['totalScore'] ?? 0,
      'max': result.first['totalMax'] ?? 0,
    };
  }

  // جلب كل الصفوف الدراسية (distinct)
  static Future<List<String>> getAllClasses() async {
    final db = await openDB();
    final result = await db.rawQuery('''
    SELECT DISTINCT year 
    FROM students
    ORDER BY year
  ''');
    return result.map((row) => row['year'] as String).toList();
  }

// جلب الطلاب حسب الصف الدراسي والسنة
  static Future<List<Map<String, dynamic>>> getStudentsByClassAndYear(
      String className, String year) async {
    final db = await openDB();
    final result = await db.query(
      'students',
      where: 'year = ?',
      whereArgs: [className],
      orderBy: 'name ASC',
    );
    return result;
  }

  static Future<bool> addUser({
    required String username,
    required String password,
    required String role,
  }) async {
    final db = await openDB();

    // التحقق من التكرار
    final existing = await db.query(
      'users',
      where: 'username = ? AND role = ?',
      whereArgs: [username, role],
    );
    if (existing.isNotEmpty) return false;

    await db.insert('users', {
      'username': username,
      'password': password,
      'role': role,
    });
    return true;
  }

  static Future<Map<String, double>> getMonthlyIncome() async {
    final db = await openDB();

    final result = await db.rawQuery('''
    SELECT strftime('%Y-%m', date) as month, SUM(amount) as total
    FROM payments
    WHERE is_paid = 1
    GROUP BY month
    ORDER BY month ASC
  ''');

    Map<String, double> income = {};

    for (var row in result) {
      Object monthKey = row['month'] ?? '';
      double total =
          row['total'] != null ? double.parse(row['total'].toString()) : 0.0;

      // تحويل الشهر من 2026-01 إلى يناير 2026 بالعربي
      DateTime dt = DateTime.parse('$monthKey-01');
      String monthName = '${_arabicMonth(dt.month)} ${dt.year}';
      income[monthName] = total;
    }

    return income;
  }

  static String _arabicMonth(int month) {
    const months = [
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
    return months[month - 1];
  }

  static Future<void> insertDiscount(double amount, String reason) async {
    final db = await openDB();
    await db.insert('discounts', {
      'amount': amount,
      'reason': reason,
      'date': DateTime.now().toString().substring(0, 10),
    });
  }

  static Future<List<Map<String, dynamic>>> getDiscounts() async {
    final db = await openDB();
    return await db.query('discounts', orderBy: 'id DESC');
  }

  static Future<int> fetchTotalDiscounts() async {
    final db = await openDB();
    final result =
        await db.rawQuery('SELECT SUM(amount) as total FROM discounts');
    final total = result.first['total'];

    if (total == null) return 0;

    // لو double، نحوله لـ int (يمكن تقريب)
    return (total as num).toInt();
  }
}
