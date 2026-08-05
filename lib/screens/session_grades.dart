import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SessionGradesPage extends StatefulWidget {
  final int sessionNumber;
  final List<Map<String, dynamic>> grades;
  final String sessionDate;

  const SessionGradesPage({
    super.key,
    required this.sessionNumber,
    required this.grades,
    required this.sessionDate,
  });

  @override
  State<SessionGradesPage> createState() => _SessionGradesPageState();
}

class _SessionGradesPageState extends State<SessionGradesPage> {
  late List<Map<String, dynamic>> sortedGrades;
  String searchQuery = '';
  String maxScore = '';

  @override
  void initState() {
    super.initState();
    sortedGrades = List.from(widget.grades)
      ..sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
    loadMaxScore();
  }

  Future<void> loadMaxScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      maxScore = prefs.getString('maxScore') ?? '';
    });
  }

  void _filterGrades(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);

    const days = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];

    return '${days[date.weekday - 1]} - ${date.year}/${date.month}/${date.day}';
  }

  Future<void> sendWhatsAppMessage(
    String phone,
    String studentName,
    dynamic score,
  ) async {
    final message = '''
السلام عليكم

نحيطكم علماً بأن درجة الطالب:
$studentName

في التسميع رقم ${widget.sessionNumber}

هي:
$score / $maxScore

جزاكم الله خيراً
''';

    final cleanPhone = phone.replaceAll('+', '');

    final url = Uri.parse(
      'https://wa.me/+2$cleanPhone?text=${Uri.encodeComponent(message)}',
    );

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    var filteredGrades = sortedGrades.where((grade) {
      String name = (grade['name'] ?? '').toLowerCase();
      String code = (grade['code']?.toString() ?? '').toLowerCase();
      return name.contains(searchQuery) || code.contains(searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'درجات التسميع رقم ${widget.sessionNumber}',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            Text(
              _formatDate(widget.sessionDate),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.teal[700],
        actions: [
          SizedBox(
            width: 150,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'بحث',
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _filterGrades,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: filteredGrades.isEmpty
            ? Center(child: Text('لا توجد درجات'))
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: DataTable(
                    headingRowColor: WidgetStateColor.resolveWith(
                        (states) => Colors.teal.shade100),
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(label: Text('الاسم')),
                      DataColumn(label: Text('الدرجة')),
                      DataColumn(label: Text('ملاحظات')),
                      DataColumn(label: Text('إرسال')),
                    ],
                    rows: filteredGrades.map((grade) {
                      return DataRow(cells: [
                        DataCell(Text(grade['name'] ?? '')),
                        DataCell(
                          Text(
                            grade['score'] != null
                                ? '${double.parse(grade['score'].toString()).toStringAsFixed(1)} / $maxScore'
                                : '-',
                          ),
                        ),
                        DataCell(Text(grade['notes'] ?? '')),
                        DataCell(
                          IconButton(
                            icon: const Icon(
                              Icons.message,
                              color: Colors.green,
                            ),
                            onPressed: () async {
                              final phone = grade['parent_phone'];

                              if (phone == null ||
                                  phone.toString().trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('لا يوجد رقم ولي أمر لهذا الطالب'),
                                  ),
                                );
                                return;
                              }

                              await sendWhatsAppMessage(
                                phone,
                                grade['name'] ?? '',
                                grade['score'],
                              );
                            },
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
      ),
    );
  }
}
