import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/cdss_disclaimer.dart';
import '../core/theme/medical_theme.dart';
import '../providers/cdss_provider.dart';
import '../widgets/disclaimer_dialog.dart';
import '../widgets/server_config_sheet.dart';
import 'desktop_layout.dart';
import 'mobile_layout.dart';

class WorkstationScreen extends StatefulWidget {
  const WorkstationScreen({super.key});

  @override
  State<WorkstationScreen> createState() => _WorkstationScreenState();
}

class _WorkstationScreenState extends State<WorkstationScreen> {
  bool _disclaimerChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_disclaimerChecked) {
      _disclaimerChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkMandatoryDisclaimer();
      });
    }
  }

  void _checkMandatoryDisclaimer() {
    final provider = context.read<CdssProvider>();
    if (!provider.isDisclaimerAccepted) {
      DisclaimerDialog.showMandatory(context, () {
        provider.setDisclaimerAccepted(true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CdssProvider>();
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width >= 1050;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: MedicalColors.primaryCyan.withValues(alpha: 0.4)),
              ),
              child: Image.asset(
                'assets/icons/app_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.medical_services_rounded,
                  color: MedicalColors.primaryCyan,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    CdssDisclaimer.appTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'DenseNet-121 Multimodal CDSS (Macro-AUROC 0.777)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: MedicalColors.primaryCyan.withValues(alpha: 0.85),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Connection pill in AppBar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: provider.offlineDemoMode
                      ? MedicalColors.riskModerateLow
                      : (provider.isConnected ? MedicalColors.riskNormal : MedicalColors.riskHigh),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () => ServerConfigSheet.show(context),
              icon: Icon(
                Icons.circle,
                size: 10,
                color: provider.offlineDemoMode
                    ? MedicalColors.riskModerateLow
                    : (provider.isConnected ? MedicalColors.riskNormal : MedicalColors.riskHigh),
              ),
              label: Text(
                provider.offlineDemoMode
                    ? 'Oflayn Demo'
                    : (provider.isConnected ? 'Server Aloqada' : 'Aloqa Yo‘q'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: provider.offlineDemoMode
                      ? MedicalColors.riskModerateLow
                      : (provider.isConnected ? MedicalColors.riskNormal : MedicalColors.riskHigh),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Medical Policy / Legal Disclaimer info dialog
          IconButton(
            tooltip: 'Tibbiy Ogohlantirish (CDSS)',
            icon: const Icon(Icons.info_outline, color: MedicalColors.textSecondary),
            onPressed: () => DisclaimerDialog.showInfo(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: isDesktop ? const DesktopLayout() : const MobileLayout(),
      ),
    );
  }
}
