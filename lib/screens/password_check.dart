import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordCheckPage extends StatefulWidget {
  final VoidCallback onCorrect;
  const PasswordCheckPage({super.key, required this.onCorrect});

  @override
  State<PasswordCheckPage> createState() => _PasswordCheckPageState();
}

class _PasswordCheckPageState extends State<PasswordCheckPage> {
  final _passwordController = TextEditingController();

  Future<String?> _getSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('attendance_password');
  }

  void _checkPassword() async {
    String? savedPw = await _getSavedPassword();
    if (savedPw == _passwordController.text.trim()) {
      widget.onCorrect();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('كلمة المرور غير صحيحة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('أدخل كلمة المرور')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _checkPassword, child: Text('دخول')),
          ],
        ),
      ),
    );
  }
}
