class ApiConfig {
  static const String serverBase = 'https://mangetout.onrender.com';
  static const String baseUrl = '$serverBase/api';

  static String resolveImageUrl(String url) =>
      url.replaceFirst(RegExp(r'https?://[^/]+'), serverBase);

  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';

  static const String categories = '$baseUrl/categories';
  static const String items = '$baseUrl/items';

  static const String profile = '$baseUrl/users/me';

  static const String inviteStatus   = '$baseUrl/invite/status';
  static const String inviteGenerate = '$baseUrl/invite/generate';
  static const String inviteQr       = '$baseUrl/invite/qr';

  static const String upload = '$baseUrl/files/upload';
}
