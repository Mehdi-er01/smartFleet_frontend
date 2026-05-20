import 'package:flutter/material.dart';
import 'package:smartfleet_frontend/spaces/driver/home_page.dart';

class DriverSpace extends StatefulWidget {
  const DriverSpace({super.key});

  @override
  State<DriverSpace> createState() => _DriverSpaceState();
}

class _DriverSpaceState extends State<DriverSpace> {
  @override
  Widget build(BuildContext context) {
  return Scaffold(body: HomePage());
  }
}
