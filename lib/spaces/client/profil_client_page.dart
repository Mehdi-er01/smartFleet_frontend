import 'package:flutter/material.dart';

class ProfilClientPage extends StatelessWidget {
  const ProfilClientPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 45,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=33'),
            ),
            const SizedBox(height: 12),
            const Text("Amine", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("amine.client@smartfleet.ma", style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 32),
            _buildProfileTile(Icons.person_outline, "Informations personnelles"),
            _buildProfileTile(Icons.location_on_outlined, "Mes adresses enregistrées"),
            _buildProfileTile(Icons.logout, "Se déconnecter", isCritical: true),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, {bool isCritical = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        leading: Icon(icon, color: isCritical ? Colors.red : Colors.black87),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: isCritical ? Colors.red : Colors.black87)),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }
}