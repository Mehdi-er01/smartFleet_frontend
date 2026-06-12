// import 'package:flutter/material.dart';

// // --- STOCKAGE PERSISTANT (Pendant que l'application tourne) ---
// // En plaçant cette liste ICI (en dehors de la classe State), elle ne sera PLUS jamais réinitialisée quand tu quittes la page.
// final List<Map<String, String>> _stockageCartesGlobal = [
//   {
//     "type": "Visa",
//     "lastFour": "4321",
//     "expiry": "12/28",
//     "holderName": "Amine"
//   },
//   {
//     "type": "Mastercard",
//     "lastFour": "8899",
//     "expiry": "05/27",
//     "holderName": "Amine"
//   },
// ];

// class PaiementPage extends StatefulWidget {
//   const PaiementPage({super.key});

//   @override
//   State<PaiementPage> createState() => _PaiementPageState();
// }

// class _PaiementPageState extends State<PaiementPage> {
//   final _formKey = GlobalKey<FormState>();

//   final TextEditingController _cardNumberController = TextEditingController();
//   final TextEditingController _expiryController = TextEditingController();
//   final TextEditingController _holderController = TextEditingController();

//   String _selectedCardType = 'Visa';

//   @override
//   void dispose() {
//     _cardNumberController.dispose();
//     _expiryController.dispose();
//     _holderController.dispose();
//     super.dispose();
//   }

//   void _ouvrirFormulaireAjout() {
//     _cardNumberController.clear();
//     _expiryController.clear();
//     _holderController.clear();
    
//     setState(() {
//       _selectedCardType = 'Visa';
//     });

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       builder: (context) => StatefulBuilder(
//         builder: (context, setPopupState) => Padding(
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).viewInsets.bottom,
//             top: 24, left: 24, right: 24,
//           ),
//           child: SingleChildScrollView(
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     "Ajouter une carte",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 24),

//                   // Sélecteur de type
//                   const Text(
//                     "Type de carte",
//                     style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: GestureDetector(
//                           onTap: () => setPopupState(() => _selectedCardType = 'Visa'),
//                           child: Container(
//                             height: 48,
//                             decoration: BoxDecoration(
//                               color: _selectedCardType == 'Visa' ? Colors.black : const Color(0xFFF7F8FA),
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(color: _selectedCardType == 'Visa' ? Colors.black : Colors.grey.shade200),
//                             ),
//                             child: Center(
//                               child: Text(
//                                 "VISA",
//                                 style: TextStyle(
//                                   color: _selectedCardType == 'Visa' ? Colors.white : Colors.black87,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: GestureDetector(
//                           onTap: () => setPopupState(() => _selectedCardType = 'Mastercard'),
//                           child: Container(
//                             height: 48,
//                             decoration: BoxDecoration(
//                               color: _selectedCardType == 'Mastercard' ? Colors.black : const Color(0xFFF7F8FA),
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(color: _selectedCardType == 'Mastercard' ? Colors.black : Colors.grey.shade200),
//                             ),
//                             child: Center(
//                               child: Text(
//                                 "MASTERCARD",
//                                 style: TextStyle(
//                                   color: _selectedCardType == 'Mastercard' ? Colors.white : Colors.black87,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),

//                   _buildPopupField(
//                     label: "Numéro de carte",
//                     controller: _cardNumberController,
//                     icon: Icons.credit_card,
//                     keyboardType: TextInputType.number,
//                     hint: "•••• •••• •••• 1234",
//                     validator: (v) => v!.length < 4 ? "Numéro invalide" : null,
//                   ),
//                   const SizedBox(height: 16),

//                   Row(
//                     children: [
//                       Expanded(
//                         child: _buildPopupField(
//                           label: "Expiration",
//                           controller: _expiryController,
//                           icon: Icons.calendar_today_outlined,
//                           keyboardType: TextInputType.datetime,
//                           hint: "MM/AA",
//                           validator: (v) => v!.isEmpty ? "Invalide" : null,
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: _buildPopupField(
//                           label: "Titulaire",
//                           controller: _holderController,
//                           icon: Icons.person_outline,
//                           hint: "Ex: Amine",
//                           validator: (v) => v!.isEmpty ? "Obligatoire" : null,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 32),

//                   SizedBox(
//                     width: double.infinity,
//                     height: 54,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.black,
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                         elevation: 0,
//                       ),
//                       onPressed: () {
//                         if (_formKey.currentState!.validate()) {
//                           String num = _cardNumberController.text;
//                           String quatreDerniers = num.substring(num.length - 4);

//                           // AJOUT DANS LA LISTE GLOBALE
//                           setState(() {
//                             _stockageCartesGlobal.add({
//                               "type": _selectedCardType,
//                               "lastFour": quatreDerniers,
//                               "expiry": _expiryController.text,
//                               "holderName": _holderController.text,
//                             });
//                           });

//                           Navigator.pop(context);
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(content: Text("Carte ajoutée !"), backgroundColor: Colors.green),
//                           );
//                         }
//                       },
//                       child: const Text("Enregistrer la carte", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F8FA),
//       appBar: AppBar(
//         title: const Text("Méthodes de paiement", style: TextStyle(fontWeight: FontWeight.bold)),
//         backgroundColor: Colors.white,
//         elevation: 0.5,
//         foregroundColor: Colors.black,
//       ),
//       // LECTURE DEPUIS LA LISTE GLOBALE
//       body: _stockageCartesGlobal.isEmpty
//           ? const Center(child: Text("Aucune carte enregistrée."))
//           : ListView.builder(
//               padding: const EdgeInsets.all(24),
//               itemCount: _stockageCartesGlobal.length,
//               itemBuilder: (context, index) {
//                 final card = _stockageCartesGlobal[index];
//                 final isVisa = card["type"] == "Visa";

//                 return Container(
//                   margin: const EdgeInsets.only(bottom: 16),
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: isVisa 
//                           ? [const Color(0xFF1A1B4B), const Color(0xFF292C6D)] 
//                           : [const Color(0xFF2B2B2B), const Color(0xFF111111)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(card["type"]!.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,)),
//                           const Icon(Icons.contactless, color: Colors.white70, size: 26),
//                         ],
//                       ),
//                       const SizedBox(height: 32),
//                       Text("••••  ••••  ••••  ${card["lastFour"]}", style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 1.5)),
//                       const SizedBox(height: 24),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text("TITULAIRE", style: TextStyle(color: Colors.white54, fontSize: 10)),
//                               const SizedBox(height: 4),
//                               Text(card["holderName"]!, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
//                             ],
//                           ),
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text("EXPIRE", style: TextStyle(color: Colors.white54, fontSize: 10)),
//                               const SizedBox(height: 4),
//                               Text(card["expiry"]!, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
//                             ],
//                           ),
//                         ],
//                       )
//                     ],
//                   ),
//                 );
//               },
//             ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: _ouvrirFormulaireAjout,
//         backgroundColor: Colors.black,
//         icon: const Icon(Icons.add, color: Colors.white),
//         label: const Text("Ajouter une carte", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
//       ),
//     );
//   }

//   Widget _buildPopupField({
//     required String label,
//     required TextEditingController controller,
//     required IconData icon,
//     String? hint,
//     TextInputType keyboardType = TextInputType.text,
//     required String? Function(String?)? validator,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
//         const SizedBox(height: 6),
//         Container(
//           decoration: BoxDecoration(
//             color: const Color(0xFFF7F8FA),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: TextFormField(
//             controller: controller,
//             keyboardType: keyboardType,
//             validator: validator,
//             decoration: InputDecoration(
//               hintText: hint,
//               hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
//               prefixIcon: Icon(icon, color: Colors.black54, size: 20),
//               border: InputBorder.none,
//               contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }