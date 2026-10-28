abstract final class AppValidators {
  static final RegExp _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );
  static final RegExp _mobilePattern = RegExp(r'^[0-9]{10}$');

  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? name(String? value) {
    final requiredError = required(value, label: 'Name');
    if (requiredError != null) return requiredError;
    if (value!.trim().length < 2) {
      return 'Enter a valid visitor name';
    }
    return null;
  }

  static String? mobile(String? value) {
    final requiredError = required(value, label: 'Mobile number');
    if (requiredError != null) return requiredError;
    if (!_mobilePattern.hasMatch(value!.trim())) {
      return 'Enter exactly 10 digits';
    }
    return null;
  }

  static String? optionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!_emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? purpose(String? value) {
    return required(value, label: 'Purpose');
  }

  static String? project(String? value) {
    return required(value, label: 'Project');
  }
}
