import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/medical_theme.dart';
import 'providers/cdss_provider.dart';
import 'screens/workstation_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent storage for Google Play CDSS disclaimer & server configuration
  final storageService = await StorageService.init();

  final cdssProvider = CdssProvider(storageService: storageService);
  await cdssProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CdssProvider>.value(value: cdssProvider),
      ],
      child: const BmiCxrApp(),
    ),
  );
}

class BmiCxrApp extends StatelessWidget {
  const BmiCxrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMI CXR-AI v2 - Clinical Decision Support System',
      debugShowCheckedModeBanner: false,
      theme: MedicalTheme.darkTheme,
      home: const WorkstationScreen(),
    );
  }
}
