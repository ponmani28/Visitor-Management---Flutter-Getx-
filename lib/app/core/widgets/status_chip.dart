import 'package:flutter/material.dart';

import '../../data/models/visitor_model.dart';
import '../values/app_colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.compact = false});

  final VisitorStatus status;
  final bool compact;

  static Color colorFor(VisitorStatus status) {
    return switch (status) {
      VisitorStatus.registered => AppColors.statusPending,
      VisitorStatus.checkedIn => AppColors.statusCheckedIn,
      VisitorStatus.checkedOut => AppColors.statusCheckedOut,
    };
  }

  static IconData iconFor(VisitorStatus status) {
    return switch (status) {
      VisitorStatus.registered => Icons.person_add_alt_1_rounded,
      VisitorStatus.checkedIn => Icons.login_rounded,
      VisitorStatus.checkedOut => Icons.logout_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: compact ? 5 : 6,
            height: compact ? 5 : 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: compact ? 4 : 5),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
