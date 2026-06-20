class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8080/api'; // use localhost for web/desktop

  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String categories = '$baseUrl/categories';
  static const String items = '$baseUrl/items';
}
