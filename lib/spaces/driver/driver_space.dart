// Dans lib/spaces/driver/driver_space.dart
import 'package:flutter/material.dart';
import 'home_page.dart';

class DriverSpace extends StatelessWidget {
  final String driverEmail;
  final int driverId;
  final String jwtToken; // <-- Doit être récupéré ici

  const DriverSpace({
    super.key, 
    required this.driverEmail, 
    required this.driverId,
    required this.jwtToken, // <-- Déclaration requise
  });

  @override
  Widget build(BuildContext context) {
    // Transmission du jeton vers la HomePage
    return Scaffold(
      body: HomePage(
        driverEmail: driverEmail,
        driverId: driverId,
        jwtToken: jwtToken, // <-- Correction : Passer le token
      ),
    );
  }
}