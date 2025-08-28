class Environment {
  // Configure via: --dart-define=API_BASE_URL=https://your-api.onrender.com
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}

