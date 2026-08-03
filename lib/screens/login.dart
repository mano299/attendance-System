import 'package:attendance/screens/home_page.dart';
import 'package:attendance/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final usernameFocus = FocusNode();
  final passwordFocus = FocusNode();

  String role = 'teacher';

  // دالة تسجيل الدخول
  void _login() async {
    final isValid = await DBHelper.loginUser(
      username: usernameController.text.trim(),
      password: passwordController.text.trim(),
      role: role,
    );

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('بيانات الدخول غير صحيحة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLogged', true);
    await prefs.setBool('isTeacher', role == 'teacher');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage()),
    );
  }

  Widget roleItem({
    required String value,
    required String title,
    required IconData icon,
  }) {
    final bool selected = role == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => role = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xff2563EB) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  selected ? const Color(0xff2563EB) : const Color(0xffE5E7EB),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : Colors.grey,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    usernameFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF8FAFC),
        body: Row(
          children: [
            Expanded(
              flex: 5,
              child: Center(
                child: Container(
                  width: 420,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .06),
                        blurRadius: 25,
                        offset: const Offset(0, 12),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'اهلا بيك ، جاهز ؟؟👋',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'من فضلك أدخل بياناتك للمتابعة',
                        style: TextStyle(color: Color(0xff6B7280)),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: usernameController,
                        focusNode: usernameFocus,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'اسم المستخدم',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onSubmitted: (_) {
                          FocusScope.of(context).requestFocus(passwordFocus);
                        },
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: passwordController,
                        focusNode: passwordFocus,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onSubmitted: (_) {
                          _login(); // تنفيذ تسجيل الدخول عند الضغط على Enter
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'تسجيل الدخول كـ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          roleItem(
                            value: 'teacher',
                            title: 'مدرس',
                            icon: Icons.school,
                          ),
                          const SizedBox(width: 12),
                          roleItem(
                            value: 'secretary',
                            title: 'سكرتير',
                            icon: Icons.admin_panel_settings,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff2563EB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'دخول',
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(40),
                color: const Color(0xff2563EB),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.school, color: Colors.white, size: 72),
                    SizedBox(height: 20),
                    Text(
                      'نظام إدارة الطلاب',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'إدارة الحضور، الدرجات والمصروفات\nفي مكان واحد بشكل احترافي',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
