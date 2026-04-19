class InputValidators {
  InputValidators._();

  static final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  static final RegExp _phoneRegex = RegExp(r'^\+?[0-9\s()-]{7,20}$');
  static final RegExp _passwordHasLetter = RegExp(r'[A-Za-z]');
  static final RegExp _passwordHasNumber = RegExp(r'[0-9]');

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required.';
    }
    if (!_emailRegex.hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? signInPassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) {
      return 'Password is required.';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  static String? signUpPassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) {
      return 'Password is required.';
    }
    if (password.length < 8) {
      return 'Use at least 8 characters.';
    }
    if (!_passwordHasLetter.hasMatch(password) ||
        !_passwordHasNumber.hasMatch(password)) {
      return 'Use a mix of letters and numbers.';
    }
    return null;
  }

  static String? displayName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Name is required.';
    }
    if (name.length < 2) {
      return 'Name must be at least 2 characters.';
    }
    return null;
  }

  static String? phone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) {
      return null;
    }
    if (!_phoneRegex.hasMatch(phone)) {
      return 'Enter a valid phone number.';
    }
    return null;
  }
}
