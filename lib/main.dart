import 'package:flutter/material.dart';
import 'db/db_provider.dart';
import 'screens/home_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/import_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DbProvider.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'myShop', // Internal App Title
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => HomeScreen(),
        '/customers': (_) => CustomersScreen(),
        '/import': (_) => ImportScreen(),
      },
    );
  }
}