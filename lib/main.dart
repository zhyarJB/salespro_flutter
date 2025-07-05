import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'salesrep_login.dart';
import 'home_screen.dart';

void main() {
  runApp(const SalesProApp());
}

class SalesProApp extends StatelessWidget {
  const SalesProApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SalesPro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SalesRepLoginScreen(),
      // home: HomeScreen(),
    );
  }
}