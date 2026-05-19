import 'package:flutter/material.dart';

class ManagerSpace extends StatefulWidget {
  const ManagerSpace({super.key});

  @override
  State<ManagerSpace> createState() => _ManagerSpaceState();
}

class _ManagerSpaceState extends State<ManagerSpace> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("manager space"),
      ),
    );
  }
}