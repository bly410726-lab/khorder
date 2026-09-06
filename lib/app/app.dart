import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'routes/app_pages.dart';
import 'theme/app_theme.dart';

class KhOrderApp extends StatefulWidget {
  const KhOrderApp({super.key});

  @override
  State<KhOrderApp> createState() => _KhOrderAppState();
}

class _KhOrderAppState extends State<KhOrderApp> {
  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KhOrder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppPages.initialRoute,
      routes: AppPages.routes,
    );
  }
}