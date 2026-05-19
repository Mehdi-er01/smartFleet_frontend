import 'package:flutter/material.dart';

class ClientSpace extends StatefulWidget {
  const ClientSpace({super.key});

  @override
  State<ClientSpace> createState() => _ClientSpaceState();
}

class _ClientSpaceState extends State<ClientSpace> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text("client space")));
  }
}
