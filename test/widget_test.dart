import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:cxr_medic/main.dart';
import 'package:cxr_medic/providers/cdss_provider.dart';
import 'package:cxr_medic/services/storage_service.dart';

void main() {
  testWidgets('BMI CXR-AI v2 disclaimer acceptance flow test', (WidgetTester tester) async {
    // Set screen size
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({'cxr_disclaimer_accepted': false});
    final storageService = await StorageService.init();
    final cdssProvider = CdssProvider(storageService: storageService);
    await cdssProvider.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CdssProvider>.value(value: cdssProvider),
        ],
        child: const BmiCxrApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Google Play CDSS disclaimer dialog is shown
    expect(find.text('Google Play Medical App Policy Compliance (CDSS)'), findsOneWidget);

    // Tap checkbox
    final checkboxFinder = find.byType(Checkbox);
    expect(checkboxFinder, findsOneWidget);
    await tester.tap(checkboxFinder);
    await tester.pumpAndSettle();

    // Tap "Tasdiqlash va Tizimga Kirish" button
    final acceptButton = find.text('Tasdiqlash va Tizimga Kirish');
    expect(acceptButton, findsOneWidget);
    await tester.tap(acceptButton);
    await tester.pumpAndSettle();

    // Now main workstation is visible
    expect(find.text('BMI CXR-AI v2'), findsOneWidget);
    expect(find.text('14 Ta Patologiya Ehtimolligi'), findsOneWidget);
  });

  testWidgets('BMI CXR-AI v2 diagnosis offline simulation test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({
      'cxr_disclaimer_accepted': true,
      'cxr_offline_mode': true,
    });
    final storageService = await StorageService.init();
    final cdssProvider = CdssProvider(storageService: storageService);
    await cdssProvider.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CdssProvider>.value(value: cdssProvider),
        ],
        child: const BmiCxrApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Run diagnosis button
    final runButton = find.text('Tahlilni Boshlash (CDSS)');
    expect(runButton, findsOneWidget);
    await tester.ensureVisible(runButton);
    await tester.pumpAndSettle();
    await tester.tap(runButton);
    await tester.pumpAndSettle();

    // Verify findings are displayed with calibrated thresholds
    expect(find.textContaining('Emfizema'), findsAtLeast(1));
    expect(find.textContaining('Grad-CAM++: Emfizema'), findsOneWidget);
  });
}
