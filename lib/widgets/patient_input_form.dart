import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme/medical_theme.dart';
import '../providers/cdss_provider.dart';
import 'server_config_sheet.dart';

class PatientInputForm extends StatelessWidget {
  const PatientInputForm({super.key});

  Future<void> _pickImage(BuildContext context, CdssProvider provider) async {
    try {
      final PlatformFile? picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'bmp', 'webp'],
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        provider.setImageBytes(bytes, picked.name);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tasvir tanlashda xatolik: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CdssProvider>();

    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Server Status & Settings Header
            Row(
              children: [
                // Server status indicator pill
                InkWell(
                  onTap: () => ServerConfigSheet.show(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: provider.offlineDemoMode
                          ? MedicalColors.riskModerateLow.withValues(alpha: 0.15)
                          : (provider.isConnected
                              ? MedicalColors.riskNormal.withValues(alpha: 0.15)
                              : MedicalColors.riskHigh.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: provider.offlineDemoMode
                            ? MedicalColors.riskModerateLow
                            : (provider.isConnected
                                ? MedicalColors.riskNormal
                                : MedicalColors.riskHigh),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: provider.offlineDemoMode
                                ? MedicalColors.riskModerateLow
                                : (provider.isConnected
                                    ? MedicalColors.riskNormal
                                    : MedicalColors.riskHigh),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          provider.offlineDemoMode
                              ? 'Oflayn Demo'
                              : (provider.isConnected ? 'Server Aloqada' : 'Ulanmagan'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: provider.offlineDemoMode
                                ? MedicalColors.riskModerateLow
                                : (provider.isConnected
                                    ? MedicalColors.riskNormal
                                    : MedicalColors.riskHigh),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.settings, size: 14, color: MedicalColors.textSecondary),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Device indicator badge (CUDA / CPU)
                if (provider.healthStatus != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: MedicalColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: MedicalColors.border),
                    ),
                    child: Text(
                      provider.healthStatus!.device.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: MedicalColors.primaryCyan,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Section: X-Ray Image Upload / Dropzone
            const Text(
              'RENTGENOGRAMMA',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: MedicalColors.primaryCyan,
              ),
            ),
            const SizedBox(height: 8),

            // Dropzone container
            InkWell(
              onTap: () => _pickImage(context, provider),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                decoration: BoxDecoration(
                  color: MedicalColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: provider.selectedImageBytes != null
                        ? MedicalColors.primaryCyan.withValues(alpha: 0.5)
                        : MedicalColors.border,
                    style: BorderStyle.solid,
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      provider.selectedImageBytes != null
                          ? Icons.check_circle_rounded
                          : Icons.cloud_upload_outlined,
                      size: 36,
                      color: provider.selectedImageBytes != null
                          ? MedicalColors.primaryCyan
                          : MedicalColors.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.selectedImageBytes != null
                          ? provider.selectedImageName
                          : "Faylni tanlang (PNG / JPG / DICOM)",
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: MedicalColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Uint8List xotira orqali barcha platformalarda xavfsiz",
                      style: TextStyle(fontSize: 10, color: MedicalColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 1-tap Sample demo load button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: MedicalColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () => provider.loadSampleRadiograph(),
              icon: const Icon(Icons.science_outlined, size: 16, color: MedicalColors.primaryCyan),
              label: const Text(
                'Namuna Rentgenni Yuklash',
                style: TextStyle(fontSize: 12, color: MedicalColors.primaryCyan),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Section: Clinical Patient Metadata (view_pos, age, gender)
            const Text(
              'KLINIK METAMA’LUMOTLAR',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: MedicalColors.primaryCyan,
              ),
            ),
            const SizedBox(height: 10),

            // View Position (PA vs AP)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Proyeksiya (View Pos):',
                  style: TextStyle(fontSize: 12, color: MedicalColors.textSecondary),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'PA', label: Text('PA')),
                      ButtonSegment(value: 'AP', label: Text('AP')),
                    ],
                    selected: {provider.viewPos},
                    onSelectionChanged: (set) {
                      provider.setPatientMeta(viewPos: set.first);
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return MedicalColors.primaryCyan;
                        }
                        return MedicalColors.surface;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.black;
                        }
                        return MedicalColors.textPrimary;
                      }),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Gender (M vs F)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bemor Jinsi (Gender):',
                  style: TextStyle(fontSize: 12, color: MedicalColors.textSecondary),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'M', label: Text('Erkak (M)')),
                      ButtonSegment(value: 'F', label: Text('Ayol (F)')),
                    ],
                    selected: {provider.gender},
                    onSelectionChanged: (set) {
                      provider.setPatientMeta(gender: set.first);
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return MedicalColors.primaryCyan;
                        }
                        return MedicalColors.surface;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.black;
                        }
                        return MedicalColors.textPrimary;
                      }),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Age Input (Slider + value label)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Bemor Yoshi (Age):',
                    style: TextStyle(fontSize: 12.5, color: MedicalColors.textPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: MedicalColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: MedicalColors.border),
                  ),
                  child: Text(
                    '${provider.age} yosh',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: MedicalColors.primaryCyan,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              value: provider.age.toDouble(),
              min: 1,
              max: 100,
              divisions: 99,
              onChanged: (val) {
                provider.setPatientMeta(age: val.round());
              },
            ),

            const SizedBox(height: 18),

            // Run Diagnosis Action Button
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: MedicalColors.primaryCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                onPressed: provider.isLoading ? null : () => provider.runDiagnosis(),
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                      )
                    : const Icon(Icons.online_prediction_rounded, size: 22),
                label: Text(
                  provider.isLoading ? 'Multimodal Tahlil Qilinmoqda...' : 'Tahlilni Boshlash (CDSS)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),

            if (provider.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MedicalColors.riskHigh.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MedicalColors.riskHigh.withValues(alpha: 0.4)),
                ),
                child: Text(
                  provider.errorMessage!,
                  style: const TextStyle(fontSize: 11.5, color: MedicalColors.riskHigh),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
