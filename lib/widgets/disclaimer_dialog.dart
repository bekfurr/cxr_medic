import 'package:flutter/material.dart';
import '../core/constants/cdss_disclaimer.dart';
import '../core/theme/medical_theme.dart';

class DisclaimerDialog extends StatefulWidget {
  final bool isMandatory;
  final VoidCallback onAccept;

  const DisclaimerDialog({
    super.key,
    this.isMandatory = true,
    required this.onAccept,
  });

  static Future<void> showMandatory(BuildContext context, VoidCallback onAccept) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: DisclaimerDialog(
          isMandatory: true,
          onAccept: () {
            Navigator.of(ctx).pop();
            onAccept();
          },
        ),
      ),
    );
  }

  static Future<void> showInfo(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DisclaimerDialog(
        isMandatory: false,
        onAccept: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<DisclaimerDialog> createState() => _DisclaimerDialogState();
}

class _DisclaimerDialogState extends State<DisclaimerDialog> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: MedicalColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: MedicalColors.border, width: 1.5),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: MedicalColors.primaryCyan.withValues(alpha: 0.3)),
            ),
            child: Image.asset(
              'assets/icons/app_icon.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.health_and_safety_rounded,
                color: MedicalColors.primaryCyan,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CdssDisclaimer.dialogTitleUz,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: MedicalColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Google Play Medical App Policy Compliance (CDSS)',
                  style: TextStyle(
                    fontSize: 11,
                    color: MedicalColors.primaryCyan,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: MedicalColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: MedicalColors.border),
                ),
                child: const Text(
                  CdssDisclaimer.fullDisclaimerUz,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: MedicalColors.textSecondary,
                  ),
                ),
              ),
              if (widget.isMandatory) ...[
                const SizedBox(height: 14),
                InkWell(
                  onTap: () {
                    setState(() {
                      _agreed = !_agreed;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _agreed,
                          activeColor: MedicalColors.primaryCyan,
                          checkColor: Colors.black,
                          onChanged: (val) {
                            setState(() {
                              _agreed = val ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            "Men tibbiyot xodimiman, CDSS qoidalarini o'qidim va to'liq roziman.",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: MedicalColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (!widget.isMandatory)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Yopish', style: TextStyle(color: MedicalColors.textSecondary)),
          )
        else
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _agreed ? MedicalColors.primaryCyan : Colors.grey.shade800,
                foregroundColor: _agreed ? Colors.black : Colors.grey.shade500,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _agreed ? widget.onAccept : null,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: const Text(
                'Tasdiqlash va Tizimga Kirish',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
      ],
    );
  }
}
