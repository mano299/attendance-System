import 'package:attendance/db_helper.dart';
import 'package:flutter/material.dart';

class MessageTemplatesPage extends StatefulWidget {
  const MessageTemplatesPage({super.key});

  @override
  State<MessageTemplatesPage> createState() => _MessageTemplatesPageState();
}

class _MessageTemplatesPageState extends State<MessageTemplatesPage> {
  String selectedType = 'recitation';

  final TextEditingController messageController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  final Map<String, String> messageTypes = {
    'recitation': 'رسالة درجة التسميع',
    'absence': 'رسالة الغياب',
  };

  final Map<String, List<String>> placeholders = {
    'recitation': [
      '{student_name}',
      '{session_number}',
      '{score}',
      '{max_score}',
    ],
    'absence': [
      '{student_name}',
      '{date}',
    ],
  };

  final Map<String, String> placeholderLabels = {
    '{student_name}': 'اسم الطالب',
    '{session_number}': 'رقم التسميع',
    '{score}': 'الدرجة',
    '{max_score}': 'الدرجة النهائية',
    '{date}': 'التاريخ',
  };

  final Map<String, String> defaultMessages = {
    'recitation': '''
السلام عليكم

نحيطكم علماً بأن درجة الطالب:
{student_name}

في التسميع رقم:
{session_number}

هي:
{score} / {max_score}

مستر محمود الشهاوي || أستاذ الكيمياء
''',
    'absence': '''
السلام عليكم

نحيطكم علماً بأن الطالب:
{student_name}

متغيب عن الحصة بتاريخ:
{date}

مستر محمود الشهاوي || أستاذ الكيمياء
''',
  };

  @override
  void initState() {
    super.initState();
    loadMessage();
  }

  Future<void> loadMessage() async {
    setState(() {
      isLoading = true;
    });

    final message = await DBHelper.getMessageTemplate(selectedType);

    messageController.text =
        message ?? defaultMessages[selectedType]!;

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> changeMessageType(String type) async {
    if (type == selectedType) return;

    setState(() {
      selectedType = type;
      isLoading = true;
    });

    final message = await DBHelper.getMessageTemplate(type);

    messageController.text =
        message ?? defaultMessages[type]!;

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveMessage() async {
    final message = messageController.text.trim();

    if (message.isEmpty) {
      showSnackBar(
        'برجاء كتابة الرسالة أولاً',
        Colors.red,
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await DBHelper.updateMessageTemplate(
        type: selectedType,
        message: message,
      );

      if (mounted) {
        showSnackBar(
          'تم حفظ الرسالة بنجاح',
          Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          'حدث خطأ أثناء حفظ الرسالة',
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void restoreDefault() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('استعادة الرسالة الافتراضية'),
          content: const Text(
            'هل أنت متأكد من استعادة الرسالة الافتراضية؟\n'
            'سيتم استبدال الرسالة الحالية.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                messageController.text =
                    defaultMessages[selectedType]!;

                Navigator.pop(context);

                showSnackBar(
                  'تمت استعادة الرسالة الافتراضية',
                  Colors.blue,
                );
              },
              child: const Text('استعادة'),
            ),
          ],
        );
      },
    );
  }

  void insertPlaceholder(String placeholder) {
    final text = messageController.text;
    final selection = messageController.selection;

    final start = selection.start >= 0
        ? selection.start
        : text.length;

    final end = selection.end >= 0
        ? selection.end
        : text.length;

    final newText = text.replaceRange(
      start,
      end,
      placeholder,
    );

    messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: start + placeholder.length,
      ),
    );
  }

  void showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String getPreview() {
    String preview = messageController.text;

    final values = {
      '{student_name}': 'أحمد محمد',
      '{session_number}': '5',
      '{score}': '18',
      '{max_score}': '20',
      '{date}': '26/08/2026',
    };

    values.forEach((key, value) {
      preview = preview.replaceAll(key, value);
    });

    return preview;
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildHeader(),

                  const SizedBox(height: 24),

                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: buildEditor(),
                        ),

                        const SizedBox(width: 24),

                        Expanded(
                          flex: 4,
                          child: buildPreview(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.message,
            color: Colors.green,
            size: 28,
          ),
        ),

        const SizedBox(width: 12),

        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إدارة الرسائل',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'قم بتعديل الرسائل التي يتم إرسالها لأولياء الأمور',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),

        const Spacer(),

        OutlinedButton.icon(
          onPressed: restoreDefault,
          icon: const Icon(Icons.restore),
          label: const Text('استعادة الافتراضي'),
        ),

        const SizedBox(width: 12),

        ElevatedButton.icon(
          onPressed: isSaving ? null : saveMessage,
          icon: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save),
          label: Text(
            isSaving ? 'جاري الحفظ...' : 'حفظ الرسالة',
          ),
        ),
      ],
    );
  }

  Widget buildEditor() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'نوع الرسالة',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: messageTypes.entries.map((entry) {
                final selected = selectedType == entry.key;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => changeMessageType(entry.key),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? Colors.green
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: selected
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(entry.value),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            const Text(
              'محتوى الرسالة',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: TextField(
                controller: messageController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'اكتب محتوى الرسالة هنا...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'العناصر المتاحة',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: placeholders[selectedType]!
                  .map(
                    (placeholder) => ActionChip(
                      avatar: const Icon(
                        Icons.add,
                        size: 16,
                      ),
                      label: Text(
                        placeholderLabels[placeholder]!,
                      ),
                      onPressed: () {
                        insertPlaceholder(placeholder);
                      },
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 8),

            Text(
              'اضغط على أي عنصر لإضافته في مكان المؤشر داخل الرسالة.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPreview() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.visibility,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                const Text(
                  'معاينة الرسالة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              'هكذا ستظهر الرسالة لولي الأمر',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xffe9f7ef),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.2),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    getPreview(),
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.7,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'استخدم العناصر المتاحة لإظهار بيانات الطالب تلقائياً داخل الرسالة.',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}