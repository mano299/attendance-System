import 'package:attendance/db_helper.dart';
import 'package:attendance/screens/activation_view.dart';
import 'package:attendance/screens/login.dart';
import 'package:attendance/services/license_service.dart';
import 'package:flutter/material.dart';

class LicenseGate extends StatefulWidget {
  const LicenseGate({super.key});

  @override
  State<LicenseGate> createState() => _LicenseGateState();
}

class _LicenseGateState extends State<LicenseGate> {

  @override
  void initState() {
    super.initState();
    checkLicense();
  }

  Future<void> checkLicense() async {
    final saved = await DBHelper.getLicense();

    if (saved == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ActivationView(),
        ),
      );
      return;
    }

    final valid =
        await LicenseService.verify(saved);

    if (valid) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginView(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ActivationView(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}