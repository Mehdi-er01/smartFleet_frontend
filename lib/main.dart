import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfleet_frontend/login_page.dart';
import 'package:smartfleet_frontend/service/snackbar_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() {
  runApp(const ProviderScope(child: smartFleet()));
}

class smartFleet extends StatelessWidget {
  const smartFleet({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: SnackbarService.scaffoldMessengerKey,
      home: LoginPage(),
    );
  }
}
