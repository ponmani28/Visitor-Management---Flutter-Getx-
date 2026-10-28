import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/utils/app_date_formatter.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/qr_payload_parser.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/controllers/visitor_controller.dart';
import '../../../data/models/visitor_model.dart';
import '../../../routes/app_routes.dart';

enum ScanAction { scanAgain, register, openDetails, checkIn, checkOut }

class ScanOutcome {
  const ScanOutcome({required this.rawValue, this.visitor, this.errorMessage});

  final String rawValue;
  final Visitor? visitor;
  final String? errorMessage;

  bool get isRecognized => visitor != null;
}

class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key});

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView>
    with WidgetsBindingObserver {
  final MobileScannerController _scannerController = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
  );

  bool _requestingPermission = true;
  bool _authorized = false;
  bool _processing = false;
  bool _isAppActive = true;
  bool _isClosed = false;
  PermissionStatus? _permissionStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
  }

  @override
  void dispose() {
    _isClosed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposeCamera());
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;
    setState(() => _requestingPermission = true);

    try {
      final status = await Permission.camera.request();
      if (!mounted) return;
      setState(() {
        _permissionStatus = status;
        _authorized = status.isGranted;
      });

      if (status.isGranted && _isAppActive && !_isClosed) {
        await _startCamera();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _authorized = false;
        _permissionStatus = PermissionStatus.denied;
      });
    } finally {
      if (mounted) setState(() => _requestingPermission = false);
    }
  }

  Future<void> _refreshPermission() async {
    try {
      final status = await Permission.camera.status;
      if (!mounted) return;
      setState(() {
        _permissionStatus = status;
        _authorized = status.isGranted;
      });

      if (status.isGranted && _isAppActive && !_isClosed) {
        await _startCamera();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _authorized = false);
    }
  }

  Future<void> _startCamera() async {
    if (_isClosed || !_isAppActive || !_authorized || _processing || !mounted) {
      return;
    }

    try {
      await _scannerController.start();
    } catch (_) {
      // MobileScanner surfaces camera failures through its error builder.
    }
  }

  Future<void> _stopCamera() async {
    try {
      await _scannerController.stop();
    } catch (_) {
      // The camera may already be stopped or uninitialized.
    }
  }

  Future<void> _restartCamera() async {
    if (_isClosed) return;
    if (!_authorized) {
      await _refreshPermission();
      return;
    }

    await _stopCamera();
    await _startCamera();
  }

  Future<void> _toggleTorch() async {
    final state = _scannerController.value;
    if (!state.isInitialized || !state.isRunning) return;

    try {
      await _scannerController.toggleTorch();
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(
        context,
        'Torch unavailable',
        'Unable to toggle the flashlight.',
      );
    }
  }

  Future<void> _handleCapture(BarcodeCapture capture) async {
    if (_processing || !_authorized || !mounted) return;

    String? rawValue;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        rawValue = value;
        break;
      }
    }
    if (rawValue == null) return;

    final provider = Get.find<VisitorController>();
    setState(() => _processing = true);
    await _stopCamera();

    try {
      final visitorId = extractVisitorId(rawValue);
      ScanOutcome outcome;

      if (visitorId.isEmpty) {
        outcome = ScanOutcome(
          rawValue: rawValue,
          errorMessage: 'This QR code does not contain a visitor ID.',
        );
      } else {
        try {
          final visitor = await provider.fetchById(visitorId);
          outcome = ScanOutcome(rawValue: visitorId, visitor: visitor);
        } on ApiException catch (error) {
          if (error.statusCode == 404) {
            outcome = ScanOutcome(
              rawValue: visitorId,
              errorMessage: 'No visitor record matches this QR code.',
            );
          } else {
            if (mounted) {
              AppSnackbar.error(context, 'Unable to verify QR', error.message);
            }
            return;
          }
        }
      }

      if (!mounted) return;

      final action = await showModalBottomSheet<ScanAction>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        builder: (sheetContext) => _ScanResultSheet(outcome: outcome),
      );

      if (!mounted || action == null) return;
      await _performAction(action, outcome);
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(
          context,
          'Unable to verify QR',
          'Something went wrong while checking this visitor pass.',
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
      if (!_isClosed && _isAppActive) {
        await _startCamera();
      }
    }
  }

  Future<void> _performAction(ScanAction action, ScanOutcome outcome) async {
    final visitor = outcome.visitor;

    switch (action) {
      case ScanAction.scanAgain:
        return;
      case ScanAction.register:
        await AppNavigator.openVisitorForm(context);
        return;
      case ScanAction.openDetails:
        if (visitor != null) {
          await AppNavigator.openVisitorDetails(context, visitor);
        }
        return;
      case ScanAction.checkIn:
        if (visitor == null) return;
        try {
          final updated = await Get.find<VisitorController>().checkIn(
            visitor,
          );
          if (!mounted) return;
          AppSnackbar.success(
            context,
            'Checked in',
            '${updated.name} is now checked in.',
          );
        } on ApiException catch (error) {
          if (mounted) {
            AppSnackbar.error(context, 'Check-in failed', error.message);
          }
        } catch (error) {
          if (mounted) {
            AppSnackbar.error(
              context,
              'Check-in failed',
              error.toString().replaceAll('Exception: ', ''),
            );
          }
        }
        return;
      case ScanAction.checkOut:
        if (visitor == null) return;
        try {
          final updated = await Get.find<VisitorController>().checkOut(
            visitor,
          );
          if (!mounted) return;
          AppSnackbar.success(
            context,
            'Checked out',
            '${updated.name} has completed the visit.',
          );
        } on ApiException catch (error) {
          if (mounted) {
            AppSnackbar.error(context, 'Check-out failed', error.message);
          }
        } catch (error) {
          if (mounted) {
            AppSnackbar.error(
              context,
              'Check-out failed',
              error.toString().replaceAll('Exception: ', ''),
            );
          }
        }
        return;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppActive = true;
        if (!_authorized) {
          unawaited(_refreshPermission());
        } else if (!_processing) {
          unawaited(_startCamera());
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _isAppActive = false;
        unawaited(_stopCamera());
        break;
    }
  }

  Future<void> _disposeCamera() async {
    await _stopCamera();
    await _scannerController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'Scan Visitor QR',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_requestingPermission) {
      return const _PermissionLoading();
    }

    if (!_authorized) {
      return _PermissionState(
        status: _permissionStatus,
        onRequest: () => unawaited(_initializeCamera()),
        onOpenSettings: () => unawaited(openAppSettings()),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) => unawaited(_handleCapture(capture)),
          placeholderBuilder: (context, child) => const ColoredBox(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: Colors.white,
              ),
            ),
          ),
          errorBuilder: (context, error, child) => _CameraErrorState(
            onRetry: () => unawaited(_restartCamera()),
            onOpenSettings: () => unawaited(openAppSettings()),
          ),
        ),
        const _ScannerOverlay(),
        Positioned(
          top: 16,
          left: 24,
          right: 24,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.qr_code_rounded, color: Colors.white70, size: 16),
                  SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      'Align the visitor QR code inside the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(24, 0, 24, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _TorchButton(
                  controller: _scannerController,
                  onToggle: _toggleTorch,
                ),
                const SizedBox(height: 14),
                const Text(
                  'The camera scans automatically.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_processing) const Positioned.fill(child: _ProcessingOverlay()),
      ],
    );
  }
}

class _PermissionLoading extends StatelessWidget {
  const _PermissionLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Preparing camera...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionState extends StatelessWidget {
  const _PermissionState({
    required this.status,
    required this.onRequest,
    required this.onOpenSettings,
  });

  final PermissionStatus? status;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBlocked =
        (status?.isPermanentlyDenied ?? false) ||
        (status?.isRestricted ?? false);

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isBlocked
                          ? Icons.no_photography_outlined
                          : Icons.photo_camera_outlined,
                      size: 34,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isBlocked
                        ? 'Camera access blocked'
                        : 'Camera access needed',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isBlocked
                        ? 'Camera permission is disabled. Enable it in system settings, then return here to scan visitor passes.'
                        : 'Allow camera access to scan visitor QR codes and manage check-ins.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!isBlocked) ...<Widget>[
                    CustomButton(
                      label: 'Allow camera access',
                      icon: Icons.photo_camera_outlined,
                      expanded: true,
                      onPressed: onRequest,
                    ),
                    const SizedBox(height: 10),
                  ],
                  CustomButton(
                    label: 'Open settings',
                    icon: Icons.settings_outlined,
                    variant: CustomButtonVariant.outlined,
                    expanded: true,
                    onPressed: onOpenSettings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TorchButton extends StatelessWidget {
  const _TorchButton({required this.controller, required this.onToggle});

  final MobileScannerController controller;
  final Future<void> Function() onToggle;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (context, state, child) {
        final isReady = state.isInitialized && state.isRunning;
        final isUnavailable = state.torchState == TorchState.unavailable;
        final isOn = state.torchState == TorchState.on;
        final enabled = isReady && !isUnavailable;

        return Material(
          color: Colors.black.withValues(alpha: enabled ? 0.55 : 0.3),
          shape: const CircleBorder(side: BorderSide(color: Colors.white24)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? () => unawaited(onToggle()) : null,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(
                isOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: enabled ? Colors.white : Colors.white38,
                size: 23,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Verifying visitor QR...',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraErrorState extends StatelessWidget {
  const _CameraErrorState({
    required this.onRetry,
    required this.onOpenSettings,
  });

  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam_off_outlined,
                  color: Colors.white70,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Camera unavailable',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The camera could not be started. Check camera permissions and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 19),
                label: const Text('Try again'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: onOpenSettings,
                child: const Text(
                  'Open settings',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth * 0.72, 280.0);
        final frame = Rect.fromCenter(
          center: Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight / 2 - 24,
          ),
          width: side,
          height: side,
        );

        return IgnorePointer(
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: CustomPaint(painter: _ScannerFramePainter(frame)),
          ),
        );
      },
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  const _ScannerFramePainter(this.frame);

  final Rect frame;

  @override
  void paint(Canvas canvas, Size size) {
    final rounded = RRect.fromRectAndRadius(frame, const Radius.circular(28));
    final maskPath = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rounded)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      maskPath,
      Paint()..color = Colors.black.withValues(alpha: 0.58),
    );

    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(rounded, border);

    final accent = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    const length = 28.0;
    const inset = 2.0;

    final left = frame.left + inset;
    final right = frame.right - inset;
    final top = frame.top + inset;
    final bottom = frame.bottom - inset;

    canvas.drawLine(Offset(left, top + length), Offset(left, top), accent);
    canvas.drawLine(Offset(left, top), Offset(left + length, top), accent);
    canvas.drawLine(Offset(right - length, top), Offset(right, top), accent);
    canvas.drawLine(Offset(right, top), Offset(right, top + length), accent);
    canvas.drawLine(
      Offset(left, bottom - length),
      Offset(left, bottom),
      accent,
    );
    canvas.drawLine(
      Offset(left, bottom),
      Offset(left + length, bottom),
      accent,
    );
    canvas.drawLine(
      Offset(right - length, bottom),
      Offset(right, bottom),
      accent,
    );
    canvas.drawLine(
      Offset(right, bottom),
      Offset(right, bottom - length),
      accent,
    );
  }

  @override
  bool shouldRepaint(_ScannerFramePainter oldDelegate) {
    return oldDelegate.frame != frame;
  }
}

class _ScanResultSheet extends StatelessWidget {
  const _ScanResultSheet({required this.outcome});

  final ScanOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visitor = outcome.visitor;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (visitor == null)
                _UnknownPass(outcome: outcome)
              else
                _RecognizedPass(visitor: visitor),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecognizedPass extends StatelessWidget {
  const _RecognizedPass({required this.visitor});

  final Visitor visitor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = StatusChip.colorFor(visitor.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                visitor.initials,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    visitor.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${visitor.visitorType.label} - ${visitor.project}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusChip(status: visitor.status, compact: true),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: statusColor.withValues(alpha: 0.18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                StatusChip.iconFor(visitor.status),
                color: statusColor,
                size: 19,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _statusMessage(visitor.status),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SheetDetailRow(
          icon: Icons.phone_outlined,
          label: 'Mobile',
          value: visitor.mobile,
        ),
        const SizedBox(height: 8),
        _SheetDetailRow(
          icon: Icons.work_outline_rounded,
          label: 'Purpose',
          value: visitor.purpose,
        ),
        const SizedBox(height: 8),
        _SheetDetailRow(
          icon: Icons.schedule_rounded,
          label: 'Registered',
          value: AppDateFormatter.dateTime(visitor.createdAt),
        ),
        if (visitor.checkInTime != null) ...<Widget>[
          const SizedBox(height: 8),
          _SheetDetailRow(
            icon: Icons.login_rounded,
            label: 'Checked in',
            value: AppDateFormatter.dateTime(visitor.checkInTime),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.qr_code_rounded,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  visitor.qrPayload,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_primaryAction(visitor.status) != null) ...<Widget>[
          CustomButton(
            label: _primaryActionLabel(visitor.status),
            icon: _primaryActionIcon(visitor.status),
            expanded: true,
            height: 50,
            onPressed: () =>
                Navigator.of(context).pop(_primaryAction(visitor.status)),
          ),
          const SizedBox(height: 10),
        ],
        CustomButton(
          label: 'Open Visitor Details',
          icon: Icons.open_in_new_rounded,
          variant: CustomButtonVariant.outlined,
          expanded: true,
          height: 50,
          onPressed: () => Navigator.of(context).pop(ScanAction.openDetails),
        ),
      ],
    );
  }
}

class _UnknownPass extends StatelessWidget {
  const _UnknownPass({required this.outcome});

  final ScanOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_2_rounded,
              color: theme.colorScheme.error,
              size: 31,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Invalid QR code',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          outcome.errorMessage ??
              'This code does not match any visitor record.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.55),
            ),
          ),
          child: Text(
            outcome.rawValue,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 20),
        CustomButton(
          label: 'Scan Again',
          icon: Icons.qr_code_scanner_rounded,
          expanded: true,
          height: 50,
          onPressed: () => Navigator.of(context).pop(ScanAction.scanAgain),
        ),
        const SizedBox(height: 10),
        CustomButton(
          label: 'Register Visitor',
          icon: Icons.person_add_alt_1_rounded,
          variant: CustomButtonVariant.outlined,
          expanded: true,
          height: 50,
          onPressed: () => Navigator.of(context).pop(ScanAction.register),
        ),
      ],
    );
  }
}

class _SheetDetailRow extends StatelessWidget {
  const _SheetDetailRow({
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            icon,
            size: 15,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 12.3,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

String _statusMessage(VisitorStatus status) {
  return switch (status) {
    VisitorStatus.registered =>
      'This visitor is registered and ready for check-in.',
    VisitorStatus.checkedIn => 'This visitor is currently checked in.',
    VisitorStatus.checkedOut =>
      'This visit is complete. The visitor has checked out.',
  };
}

ScanAction? _primaryAction(VisitorStatus status) {
  return switch (status) {
    VisitorStatus.registered => ScanAction.checkIn,
    VisitorStatus.checkedIn => ScanAction.checkOut,
    VisitorStatus.checkedOut => null,
  };
}

String _primaryActionLabel(VisitorStatus status) {
  return switch (status) {
    VisitorStatus.registered => 'Check In Visitor',
    VisitorStatus.checkedIn => 'Check Out Visitor',
    VisitorStatus.checkedOut => '',
  };
}

IconData _primaryActionIcon(VisitorStatus status) {
  return switch (status) {
    VisitorStatus.registered => Icons.login_rounded,
    VisitorStatus.checkedIn => Icons.logout_rounded,
    VisitorStatus.checkedOut => Icons.qr_code_scanner_rounded,
  };
}
