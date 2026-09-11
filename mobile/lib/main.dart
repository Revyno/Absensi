import 'package:flutter/material.dart';

import 'api/api.dart';
import 'screens/login.dart';
import 'screens/shell.dart';
import 'services/location.dart';
import 'services/notifications.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.i.init();
  await LocationService.i.init();
  await NotificationService.i.init();
  runApp(const HrisApp());
}

class HrisApp extends StatelessWidget {
  const HrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NUSATEK HRIS',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: Api.i.isLoggedIn ? const Shell() : const LoginScreen(),
    );
  }
}
