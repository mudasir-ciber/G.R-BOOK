/// Master Administrator / Founder Configuration for G.R. BOOK.
/// Grants unrestricted super-admin powers and instant authentication to Founder Mudasir Ahmed.
class MasterAdminConfig {
  MasterAdminConfig._();

  static const String founderName = 'Mudasir Ahmed';
  static const String founderTitle = 'Admin';
  static const String founderPhone = '923368456907';
  static const String founderPhoneLocal = '03368456907';
  static const String founderFormattedPhone = '+92 336 8456907';
  static const String founderEmail = 'mudasirghanghro25@gmail.com';
  static const String founderPassword = '7091';

  /// Maximum allowed offline time without an online heartbeat before app temporarily locks for verification
  static const Duration offlineGracePeriod = Duration(days: 3); // 72 hours

  /// Returns true if [contactOrEmail] matches Founder credentials
  static bool isFounderIdentifier(String contactOrEmail) {
    final trimmed = contactOrEmail.trim().toLowerCase();
    if (trimmed == founderEmail) return true;
    final digits = contactOrEmail.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits == founderPhone || digits == founderPhoneLocal || digits == '3368456907') {
      return true;
    }
    return false;
  }

  /// Returns true if credentials match Founder's master login
  static bool isFounderCredentials(String contactOrEmail, String password) {
    return isFounderIdentifier(contactOrEmail) && password == founderPassword;
  }
}
