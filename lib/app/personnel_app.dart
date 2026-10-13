import 'package:adwas_personnel/core/config/project_info.dart';
import 'package:adwas_personnel/features/foundation/presentation/foundation_screen.dart';
import 'package:flutter/material.dart';

class PersonnelApp extends StatelessWidget {
  const PersonnelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: ProjectInfo.nameArabic,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF124A77),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F5F9),
        fontFamily: 'Segoe UI',
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: FoundationScreen(),
      ),
    );
  }
}
