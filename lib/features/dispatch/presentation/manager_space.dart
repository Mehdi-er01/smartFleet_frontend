import 'package:flutter/material.dart';
import 'package:smartfleet_frontend/features/dispatch/presentation/home_page.dart';

class ManagerSpace extends StatefulWidget {
  const ManagerSpace({super.key});

  @override
  State<ManagerSpace> createState() => _ManagerSpaceState();
}

class _ManagerSpaceState extends State<ManagerSpace> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: HomePage());
  }
}
