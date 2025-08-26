
class Validators {
  /// Validates that a string is not empty.
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates that a string is a valid email address.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$");

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates that a string can be parsed as a number and is within a given range.
  static String? validateNumber(String? value, String fieldName, {num? min, num? max}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final n = num.tryParse(value);
    if (n == null) {
      return 'Please enter a valid number';
    }
    if (min != null && n < min) {
      return '$fieldName must be at least $min';
    }
    if (max != null && n > max) {
      return '$fieldName must be no more than $max';
    }
    return null;
  }
}