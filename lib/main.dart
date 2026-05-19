import 'package:flutter/material.dart';
import 'package:smartfleet_frontend/login_page.dart';

void main() {
  runApp(const smartFleet());
}

class smartFleet extends StatelessWidget {
  const smartFleet({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}