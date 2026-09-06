import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String? status;

  Color get _color {
    switch (status?.toLowerCase()) {
      case 'delivered':
      case 'completed':
      case 'success':
        return AppColors.success;
      case 'cancelled':
      case 'canceled':
      case 'failed':
      case 'rejected':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
      case 'processing':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _label {
    final value = status ?? 'unknown';
    return value[0].toUpperCase() + value.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.status});

  final String? status;

  Color get _color {
    switch (status?.toLowerCase()) {
      case 'delivered':
      case 'completed':
      case 'success':
        return AppColors.success;
      case 'cancelled':
      case 'canceled':
      case 'failed':
      case 'rejected':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
      case 'processing':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
      ),
    );
  }
}
