import 'package:flutter/material.dart';

class DriverSpace extends StatefulWidget {
  const DriverSpace({super.key});

  @override
  State<DriverSpace> createState() => _DriverSpaceState();
}

class _DriverSpaceState extends State<DriverSpace> {
  @override
  Widget build(BuildContext context) {
  return Scaffold(body: Center(child: Text("driver space")));
  }
}
