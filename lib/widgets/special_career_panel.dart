import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../utils/theme_colors.dart';
import '../models/special_career_eligibility.dart';
import '../services/special_career_service.dart';
import 'app_ui.dart';

/// Hiển thị kết quả sơ tuyển ngành đặc thù (Công an, Quân đội…).
class SpecialCareerPanel extends StatelessWidget {
  final SpecialCareerEligibility eligibility;

  const SpecialCareerPanel({super.key, required this.eligibility});

  @override
  Widget build(BuildContext context) {
    final t = eligibility.track;
    final color = _statusColor(eligibility.status);

    return AppSurfaceCard(
      color: color.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon(eligibility.status), color: color, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngành đặc thù: ${t.name}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      eligibility.statusLabel,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            t.summary,
            style: context.tc.textStyleCaption().copyWith(height: 1.35),
          ),
          const SizedBox(height: 10),
          ...eligibility.messages.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      m,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              SpecialCareerService.disclaimer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    height: 1.35,
                  ),
            ),
          ),
          if (t.portalUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _openUrl(t.portalUrl),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(t.portalLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(SpecialEligibilityStatus s) {
    switch (s) {
      case SpecialEligibilityStatus.pass:
        return AppColors.success;
      case SpecialEligibilityStatus.warning:
        return AppColors.warning;
      case SpecialEligibilityStatus.fail:
        return AppColors.error;
    }
  }

  IconData _statusIcon(SpecialEligibilityStatus s) {
    switch (s) {
      case SpecialEligibilityStatus.pass:
        return Icons.check_circle_rounded;
      case SpecialEligibilityStatus.warning:
        return Icons.warning_amber_rounded;
      case SpecialEligibilityStatus.fail:
        return Icons.cancel_rounded;
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
