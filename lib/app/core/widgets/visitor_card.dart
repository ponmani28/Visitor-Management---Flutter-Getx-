import 'package:flutter/material.dart';

import '../../data/models/visitor_model.dart';
import '../values/app_colors.dart';
import 'status_chip.dart';

class VisitorCard extends StatelessWidget {
  const VisitorCard({
    super.key,
    required this.visitor,
    this.onTap,
    this.compact = false,
    this.showChevron = true,
  });

  final Visitor visitor;
  final VoidCallback? onTap;
  final bool compact;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _avatarColor(visitor.name);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: theme.colorScheme.outline.withValues(alpha: 0.75),
      ),
    );

    return Material(
      color: theme.colorScheme.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: compact ? 40 : 46,
                height: compact ? 40 : 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(compact ? 12 : 14),
                ),
                child: Text(
                  visitor.initials,
                  style: TextStyle(
                    color: accent,
                    fontSize: compact ? 13 : 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            visitor.name.isEmpty
                                ? 'Unnamed visitor'
                                : visitor.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(status: visitor.status, compact: true),
                      ],
                    ),
                    const SizedBox(height: 3),
                    _MetaItem(
                      icon: Icons.phone_outlined,
                      label: visitor.mobile,
                    ),
                    SizedBox(height: compact ? 6 : 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _MetaItem(
                            icon: Icons.apartment_rounded,
                            label: visitor.project,
                          ),
                        ),
                        if (!compact) ...<Widget>[
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MetaItem(
                              icon: Icons.badge_outlined,
                              label: visitor.visitorType.label,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (showChevron && onTap != null) ...<Widget>[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 19,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _avatarColor(String name) {
    final hash = name.codeUnits.fold<int>(0, (sum, code) => sum + code);
    return AppColors.avatarPalette[hash % AppColors.avatarPalette.length];
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 13, color: color.withValues(alpha: 0.9)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
