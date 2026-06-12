// import 'package:flutter/material.dart';

// class InformationsPersonnellesPage extends StatefulWidget {
//   const InformationsPersonnellesPage({super.key});

//   @override
//   State<InformationsPersonnellesPage> createState() => _InformationsPersonnellesPageState();
// }

// class _InformationsPersonnellesPageState extends State<InformationsPersonnellesPage> {
//   // Clé globale pour valider le formulaire (ex: vérifier si l'email est correct)
//   final _formKey = GlobalKey<FormState>();

//   // Les contrôleurs contiennent et gèrent le texte de chaque champ
//   final TextEditingController _nameController = TextEditingController(text: "Amine");
//   final TextEditingController _emailController = TextEditingController(text: "amine@gmail.com");
//   final TextEditingController _phoneController = TextEditingController(text: "+212 6 12 34 56 78");
//   final TextEditingController _cityController = TextEditingController(text: "Casablanca");

//   @override
//   void dispose() {
//     // Très important : libérer la mémoire des contrôleurs quand on quitte la page
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _cityController.dispose();
//     super.dispose();
//   }

//   void _sauvegarderProfil() {
//     // Si tous les champs sont correctement remplis
//     if (_formKey.currentState!.validate()) {
//       // Message de succès en bas de l'écran
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Modifications enregistrées avec succès !"),
//           backgroundColor: Colors.green,
//         ),
//       );
//       // Retour automatique à l'écran de profil précédent
//       Navigator.pop(context);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F8FA),
//       appBar: AppBar(
//         title: const Text(
//           "Informations personnelles",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0.5,
//         foregroundColor: Colors.black,
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   "Modifiez vos coordonnées",
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   "Ces détails sont utilisés pour planifier vos livraisons.",
//                   style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
//                 ),
//                 const SizedBox(height: 28),

//                 // 1. Champ Nom
//                 _buildInputField(
//                   label: "Nom complet",
//                   controller: _nameController,
//                   icon: Icons.person_outline,
//                   validator: (value) => value!.isEmpty ? "Veuillez saisir votre nom" : null,
//                 ),

//                 // 2. Champ Email
//                 _buildInputField(
//                   label: "Adresse e-mail",
//                   controller: _emailController,
//                   icon: Icons.mail_outline,
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) {
//                     if (value!.isEmpty) return "Veuillez saisir votre e-mail";
//                     if (!value.contains('@')) return "Veuillez saisir un e-mail valide";
//                     return null;
//                   },
//                 ),

//                 // 3. Champ Téléphone
//                 _buildInputField(
//                   label: "Numéro de téléphone",
//                   controller: _phoneController,
//                   icon: Icons.phone_android_outlined,
//                   keyboardType: TextInputType.phone,
//                   validator: (value) => value!.isEmpty ? "Veuillez saisir votre numéro" : null,
//                 ),

//                 // 4. Champ Ville
//                 _buildInputField(
//                   label: "Ville",
//                   controller: _cityController,
//                   icon: Icons.location_city_outlined,
//                   validator: (value) => value!.isEmpty ? "Veuillez spécifier votre ville" : null,
//                 ),

//                 const SizedBox(height: 40),

//                 // Bouton Noir Premium pour Enregistrer
//                 SizedBox(
//                   width: double.infinity,
//                   height: 56,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.black,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       elevation: 0,
//                     ),
//                     onPressed: _sauvegarderProfil,
//                     child: const Text(
//                       "Enregistrer les modifications",
//                       style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // Design générique pour créer des champs de saisie propres et uniformes
//   Widget _buildInputField({
//     required String label,
//     required TextEditingController controller,
//     required IconData icon,
//     TextInputType keyboardType = TextInputType.text,
//     required String? Function(String?)? validator,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
//           ),
//           const SizedBox(height: 8),
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(14),
//               border: Border.all(color: Colors.grey.shade200),
//             ),
//             child: TextFormField(
//               controller: controller,
//               keyboardType: keyboardType,
//               validator: validator,
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//               decoration: InputDecoration(
//                 prefixIcon: Icon(icon, color: Colors.black54),
//                 border: InputBorder.none,
//                 contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }