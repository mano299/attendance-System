import 'package:flutter/material.dart';
import 'package:attendance/db_helper.dart';
import 'package:attendance/services/license_service.dart';
import 'login.dart';

class ActivationView extends StatefulWidget {
  const ActivationView({super.key});

  @override
  State<ActivationView> createState() => _ActivationViewState();
}

class _ActivationViewState extends State<ActivationView> {
  final controller = TextEditingController();

  String deviceId = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadDeviceId();
  }

  Future<void> loadDeviceId() async {
    final id = await LicenseService.getDeviceId();

    setState(() {
      deviceId = id;
      loading = false;
    });
  }

  Future<void> activate() async {
    final valid =
        await LicenseService.verify(controller.text.trim());

    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('مفتاح التفعيل غير صحيح'),
        ),
      );
      return;
    }

    await DBHelper.saveLicense(
      controller.text.trim(),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginView(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفعيل البرنامج'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'أرسل رقم الجهاز للمطور للحصول على مفتاح التفعيل',
            ),

            const SizedBox(height: 20),

            SelectableText(deviceId),

            const SizedBox(height: 20),

            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'License Key',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: activate,
              child: const Text('تفعيل'),
            ),
          ],
        ),
      ),
    );
  }
}