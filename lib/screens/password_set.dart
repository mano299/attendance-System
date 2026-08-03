import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final TextEditingController _controller = TextEditingController();
  final String correctPassword = "manotheone29"; 
  String errorMessage = "";

  Future<void> _checkPassword() async {
    if (_controller.text == correctPassword) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLogged', true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } else {
      setState(() {
        errorMessage = "❌ الباسورد غلط";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("🔒 أدخل الباسورد", style: TextStyle(fontSize: 22)),
              SizedBox(height: 20),
              TextField(
                controller: _controller,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Password",
                ),
              ),
              SizedBox(height: 10),
              Text(errorMessage, style: TextStyle(color: Colors.red)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkPassword,
                child: Text("دخول"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
