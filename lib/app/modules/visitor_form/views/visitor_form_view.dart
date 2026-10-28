import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/controllers/visitor_controller.dart';
import '../../../data/models/visitor_model.dart';

class VisitorFormView extends StatefulWidget {
  const VisitorFormView({super.key, this.visitor});

  final Visitor? visitor;

  @override
  State<VisitorFormView> createState() => _VisitorFormViewState();
}

class _VisitorFormViewState extends State<VisitorFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  VisitorType _visitorType = VisitorType.customer;
  String _project = VisitorProjects.values.first;
  bool _isSaving = false;

  bool get _isEditing => widget.visitor != null;

  @override
  void initState() {
    super.initState();
    final visitor = widget.visitor;
    if (visitor == null) return;

    _nameController.text = visitor.name;
    _mobileController.text = visitor.mobile;
    _emailController.text = visitor.email ?? '';
    _purposeController.text = visitor.purpose;
    _visitorType = visitor.visitorType;
    _project = visitor.project;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    FocusManager.instance.primaryFocus?.unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final existing = widget.visitor;
    final email = _emailController.text.trim();
    final visitor = Visitor(
      id: existing?.id,
      name: _nameController.text.trim(),
      mobile: _mobileController.text.trim(),
      email: email.isEmpty ? null : email,
      visitorType: _visitorType,
      project: _project,
      purpose: _purposeController.text.trim(),
      status: existing?.status ?? VisitorStatus.registered,
      createdAt: existing?.createdAt ?? DateTime.now(),
      checkInTime: existing?.checkInTime,
      checkOutTime: existing?.checkOutTime,
    );

    setState(() => _isSaving = true);
    final controller = Get.find<VisitorController>();

    try {
      final saved = existing == null
          ? await controller.create(visitor)
          : await controller.updateVisitor(visitor);

      if (!mounted) return;
      AppSnackbar.success(
        context,
        existing == null ? 'Visitor registered' : 'Visitor updated',
        existing == null
            ? '${saved.name} is now registered for ${saved.project}.'
            : '${saved.name}\'s details have been updated.',
      );
      Navigator.of(context).pop(saved);
    } on ApiException catch (error) {
      if (mounted) {
        AppSnackbar.error(context, 'Could not save visitor', error.message);
      }
    } catch (error) {
      if (mounted) {
        AppSnackbar.error(
          context,
          'Could not save visitor',
          error.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Visitor' : 'Register Visitor'),
        leading: IconButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          tooltip: 'Cancel',
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            Text(
              _isEditing
                  ? 'Update the visitor information below.'
                  : 'Capture the visitor details and project for this visit.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            _FormSection(
              title: 'Visitor details',
              icon: Icons.person_outline_rounded,
              children: <Widget>[
                CustomTextField(
                  controller: _nameController,
                  label: 'Visitor name',
                  hint: 'e.g. Priya Sharma',
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  validator: AppValidators.name,
                ),
                CustomTextField(
                  controller: _mobileController,
                  label: 'Mobile number',
                  hint: '10-digit number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: AppValidators.mobile,
                ),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email address',
                  hint: 'Optional',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: AppValidators.optionalEmail,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FormSection(
              title: 'Visit details',
              icon: Icons.event_note_outlined,
              children: <Widget>[
                DropdownButtonFormField<VisitorType>(
                  initialValue: _visitorType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Visitor type',
                    prefixIcon: Icon(Icons.badge_outlined, size: 20),
                  ),
                  items: VisitorType.values
                      .map(
                        (type) => DropdownMenuItem<VisitorType>(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _visitorType = value);
                          }
                        },
                ),
                DropdownButtonFormField<String>(
                  initialValue: _project,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Project',
                    prefixIcon: Icon(Icons.apartment_rounded, size: 20),
                  ),
                  items: VisitorProjects.values
                      .map(
                        (project) => DropdownMenuItem<String>(
                          value: project,
                          child: Text(project),
                        ),
                      )
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _project = value);
                          }
                        },
                  validator: AppValidators.project,
                ),
                CustomTextField(
                  controller: _purposeController,
                  label: 'Purpose of visit',
                  hint: 'e.g. Client meeting',
                  prefixIcon: Icons.work_outline_rounded,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  validator: AppValidators.purpose,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.qr_code_2_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'A QR pass is generated automatically from the visitor ID once this record is saved.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
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
          child: Row(
            children: <Widget>[
              Expanded(
                child: CustomButton(
                  label: 'Cancel',
                  variant: CustomButtonVariant.outlined,
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: CustomButton(
                  label: _isEditing ? 'Save Changes' : 'Register Visitor',
                  icon: _isEditing
                      ? Icons.check_rounded
                      : Icons.person_add_alt_1_rounded,
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: theme.colorScheme.primary),
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
            const SizedBox(height: 16),
            for (var index = 0; index < children.length; index++) ...<Widget>[
              children[index],
              if (index != children.length - 1) const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}
