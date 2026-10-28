import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/utils/app_date_formatter.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/controllers/visitor_controller.dart';
import '../../../data/models/visitor_model.dart';
import '../../../routes/app_routes.dart';

class VisitorDetailsView extends StatefulWidget {
  const VisitorDetailsView({super.key, required this.visitor});

  final Visitor visitor;

  @override
  State<VisitorDetailsView> createState() => _VisitorDetailsViewState();
}

class _VisitorDetailsViewState extends State<VisitorDetailsView> {
  bool _isBusy = false;

  Visitor _current(VisitorController controller) {
    return controller.findById(widget.visitor.id) ?? widget.visitor;
  }

  Future<void> _edit() async {
    if (_isBusy) return;
    await AppNavigator.openVisitorForm(
      context,
      visitor: _current(Get.find<VisitorController>()),
    );
  }

  Future<void> _checkIn() async {
    final visitor = _current(Get.find<VisitorController>());
    await _runStatusAction(
      () => Get.find<VisitorController>().checkIn(visitor),
      successTitle: 'Checked in',
      successMessage: '${visitor.name} is now checked in.',
    );
  }

  Future<void> _checkOut() async {
    final visitor = _current(Get.find<VisitorController>());
    await _runStatusAction(
      () => Get.find<VisitorController>().checkOut(visitor),
      successTitle: 'Checked out',
      successMessage: '${visitor.name} has completed the visit.',
    );
  }

  Future<void> _runStatusAction(
    Future<Visitor> Function() action, {
    required String successTitle,
    required String successMessage,
  }) async {
    if (_isBusy) return;

    setState(() => _isBusy = true);
    try {
      await action();
      if (!mounted) return;
      AppSnackbar.success(context, successTitle, successMessage);
    } on ApiException catch (error) {
      if (mounted) {
        AppSnackbar.error(context, 'Status update failed', error.message);
      }
    } catch (error) {
      if (mounted) {
        AppSnackbar.error(
          context,
          'Status update failed',
          error.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _delete() async {
    if (_isBusy) return;
    final visitor = _current(Get.find<VisitorController>());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete visitor?'),
        content: Text(
          'This will permanently remove ${visitor.name} and the visitor QR pass. This action cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Visitor'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      final id = visitor.id;
      if (id == null || id.isEmpty) return;
      await Get.find<VisitorController>().delete(id);
      if (!mounted) return;
      AppSnackbar.success(
        context,
        'Visitor deleted',
        '${visitor.name} was removed from the visitor log.',
      );
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (mounted) {
        AppSnackbar.error(context, 'Could not delete visitor', error.message);
      }
    } catch (error) {
      if (mounted) {
        AppSnackbar.error(
          context,
          'Could not delete visitor',
          error.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _copyVisitorId() async {
    final id = _current(Get.find<VisitorController>()).id;
    if (id == null || id.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: id));
    if (!mounted) return;
    AppSnackbar.info(
      context,
      'Visitor ID copied',
      'The QR payload was copied to the clipboard.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<VisitorController>();

    return Obx(() {
      final visitor = _current(controller);

      return Scaffold(
        appBar: AppBar(
          title: const Text('Visitor Details'),
          actions: <Widget>[
            IconButton(
              onPressed: _isBusy ? null : _edit,
              tooltip: 'Edit visitor',
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: _isBusy ? null : _delete,
              tooltip: 'Delete visitor',
              icon: Icon(
                Icons.delete_outline_rounded,
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: <Widget>[
            _ProfileHeader(visitor: visitor),
            const SizedBox(height: 16),
            _QrPassCard(visitor: visitor, onCopy: _copyVisitorId),
            const SizedBox(height: 16),
            _InfoSection(
              title: 'Visit information',
              icon: Icons.event_note_outlined,
              rows: <Widget>[
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Type',
                  value: visitor.visitorType.label,
                ),
                _InfoRow(
                  icon: Icons.apartment_rounded,
                  label: 'Project',
                  value: visitor.project,
                ),
                _InfoRow(
                  icon: Icons.work_outline_rounded,
                  label: 'Purpose',
                  value: visitor.purpose,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InfoSection(
              title: 'Contact',
              icon: Icons.contact_phone_outlined,
              rows: <Widget>[
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Mobile',
                  value: visitor.mobile,
                ),
                _InfoRow(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  value: visitor.displayEmail,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InfoSection(
              title: 'Visitor activity',
              icon: Icons.timeline_rounded,
              rows: <Widget>[
                _InfoRow(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'Registered',
                  value: AppDateFormatter.dateTime(visitor.createdAt),
                ),
                _InfoRow(
                  icon: Icons.login_rounded,
                  label: 'Checked in',
                  value: AppDateFormatter.dateTime(visitor.checkInTime),
                ),
                _InfoRow(
                  icon: Icons.logout_rounded,
                  label: 'Checked out',
                  value: AppDateFormatter.dateTime(visitor.checkOutTime),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomAction(theme, visitor),
      );
    });
  }

  Widget _buildBottomAction(ThemeData theme, Visitor visitor) {
    final Widget? action = switch (visitor.status) {
      VisitorStatus.registered => CustomButton(
        label: 'Check In Visitor',
        icon: Icons.login_rounded,
        isLoading: _isBusy,
        expanded: true,
        height: 50,
        onPressed: _checkIn,
      ),
      VisitorStatus.checkedIn => CustomButton(
        label: 'Check Out Visitor',
        icon: Icons.logout_rounded,
        isLoading: _isBusy,
        expanded: true,
        height: 50,
        onPressed: _checkOut,
      ),
      VisitorStatus.checkedOut => null,
    };

    if (action == null) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        child: action,
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.visitor});

  final Visitor visitor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            alignment: Alignment.center,
            child: Text(
              visitor.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  visitor.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${visitor.visitorType.label} - ${visitor.project}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(100)),
                  ),
                  child: StatusChip(status: visitor.status, compact: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrPassCard extends StatelessWidget {
  const _QrPassCard({required this.visitor, required this.onCopy});

  final Visitor visitor;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payload = visitor.qrPayload;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.qr_code_2_rounded,
                  size: 19,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Visitor QR pass',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: payload.isEmpty ? null : onCopy,
                  tooltip: 'Copy visitor ID',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.6),
                ),
              ),
              child: payload.isEmpty
                  ? const SizedBox(
                      width: 168,
                      height: 168,
                      child: Center(child: Text('No visitor ID available')),
                    )
                  : QrImageView(
                      data: payload,
                      version: QrVersions.auto,
                      size: 168,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              payload,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'The QR code contains the visitor ID and can be presented at reception.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (var index = 0; index < rows.length; index++) ...<Widget>[
              if (index > 0) const Divider(height: 1),
              rows[index],
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              icon,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 12.8,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
