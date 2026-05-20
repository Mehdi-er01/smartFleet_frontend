import 'package:flutter/material.dart';

class SearchWidget extends StatefulWidget {
  const SearchWidget({Key? key}) : super(key: key);

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  // 1. Define the controller internally
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // 2. Initialize it when the widget is created
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    // 3. IMPORTANT: Dispose of the controller when the widget is destroyed
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Track your shipment',
        hintStyle: TextStyle(color: Colors.grey.shade600),
        
        prefixIcon: const Icon(
          size: 32,
          Icons.search,
          color: Colors.black87,
        ),
        
        // suffixIcon: Padding(
        //   padding: const EdgeInsets.only(right: 6.0, top: 6.0, bottom: 6.0),
        //   child: Container(
        //     decoration: BoxDecoration(
        //       color: const Color(0xFF5DB061), 
        //       borderRadius: BorderRadius.circular(12), 
        //     ),
        //     child: IconButton(
        //       icon: const Icon(
        //         Icons.qr_code_scanner, 
        //         color: Colors.white,
        //       ),
        //       onPressed: () {
        //         // You can access the text directly here using _controller.text
        //         print('Scan button pressed. Current text: ${_controller.text}');
        //       },
        //     ),
        //   ),
        // ),

        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18.0),
        
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 1.0,
          ),
        ),
        
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(
            color: Colors.grey,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}