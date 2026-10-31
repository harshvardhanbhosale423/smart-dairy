class Validators {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'हे फील्ड आवश्यक आहे / This field is required';
    }
    return null;
  }

  static String? phone(String? value) => validatePhone(value);

  static String? upiId(String? value) => validateUpiId(value);

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'कृपया मोबाईल नंबर टाका / Please enter mobile number';
    }
    final cleanPhone = value.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length != 10) {
      return '१० अंकी मोबाईल नंबर टाका / Enter valid 10-digit number';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName आवश्यक आहे / $fieldName is required';
    }
    return null;
  }

  static String? validateNumber(String? value, String fieldName, {bool allowZero = true}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName टाका / Enter $fieldName';
    }
    final numVal = double.tryParse(value);
    if (numVal == null) {
      return 'योग्य संख्या टाका / Enter valid number';
    }
    if (!allowZero && numVal <= 0) {
      return '$fieldName शून्यापेक्षा जास्त असावे / Must be greater than 0';
    }
    if (numVal < 0) {
      return 'संख्या ऋण असू शकत नाही / Cannot be negative';
    }
    return null;
  }

  static String? validateUpiId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'UPI ID टाका (उदा. yourname@oksbi)';
    }
    final regExp = RegExp(r'^[\w.\-_]{2,256}@[a-zA-Z]{2,64}$');
    if (!regExp.hasMatch(value.trim())) {
      return 'योग्य UPI ID टाका (उदा. 9822000000@paytm)';
    }
    return null;
  }
}

