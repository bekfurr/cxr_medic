import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/medical_theme.dart';
import '../providers/cdss_provider.dart';

class ServerConfigSheet extends StatefulWidget {
  const ServerConfigSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ServerConfigSheet(),
    );
  }

  @override
  State<ServerConfigSheet> createState() => _ServerConfigSheetState();
}

class _ServerConfigSheetState extends State<ServerConfigSheet> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<CdssProvider>();
    _urlController = TextEditingController(text: provider.serverUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CdssProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: MedicalColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: MedicalColors.border, width: 1.5)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.dns_rounded, color: MedicalColors.primaryCyan, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Flask CXRNetV2 Server Sozlamalari',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: MedicalColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: MedicalColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Offline Demo Mode Switch
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Oflayn Demo Rejimi',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Server ulanmasdan turib 14 ta patologiya va Grad-CAM++ simulyatsiyasi',
              style: TextStyle(fontSize: 12, color: MedicalColors.textSecondary),
            ),
            value: provider.offlineDemoMode,
            activeThumbColor: MedicalColors.primaryCyan,
            onChanged: (val) {
              provider.setOfflineDemoMode(val);
            },
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Server URL Input
          TextField(
            controller: _urlController,
            enabled: !provider.offlineDemoMode,
            style: const TextStyle(fontSize: 14, color: MedicalColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Flask Server URL (app.py)',
              hintText: 'http://127.0.0.1:5000',
              prefixIcon: const Icon(Icons.link, color: MedicalColors.primaryCyan),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: MedicalColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: MedicalColors.primaryCyan),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Quick Preset Buttons
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('Localhost (5000)', style: TextStyle(fontSize: 11)),
                onPressed: () => _urlController.text = 'http://127.0.0.1:5000',
              ),
              ActionChip(
                label: const Text('Android Emulator (10.0.2.2:5000)', style: TextStyle(fontSize: 11)),
                onPressed: () => _urlController.text = 'http://10.0.2.2:5000',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Connection status card
          if (!provider.offlineDemoMode)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MedicalColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: MedicalColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        provider.isConnected ? Icons.check_circle : Icons.error_outline,
                        color: provider.isConnected ? MedicalColors.riskNormal : MedicalColors.riskHigh,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        provider.isConnected
                            ? 'Server Faol: ${provider.healthStatus?.version ?? "OK"}'
                            : 'Serverga Ulanib Bo‘lmadi',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: provider.isConnected ? MedicalColors.riskNormal : MedicalColors.riskHigh,
                        ),
                      ),
                    ],
                  ),
                  if (provider.healthStatus != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Qurilma: ${provider.healthStatus!.device.toUpperCase()} • '
                      'Kirish o‘lchami: ${provider.healthStatus!.imgSize}x${provider.healthStatus!.imgSize} • '
                      'Patologiyalar soni: ${provider.healthStatus!.pathologies.length}',
                      style: const TextStyle(fontSize: 11, color: MedicalColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: MedicalColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: provider.isCheckingConnection
                      ? null
                      : () async {
                          await provider.setServerUrl(_urlController.text);
                        },
                  child: provider.isCheckingConnection
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Aloqani Tekshirish', style: TextStyle(color: MedicalColors.primaryCyan)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: MedicalColors.primaryCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    provider.setServerUrl(_urlController.text);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Saqlash va Yopish', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
