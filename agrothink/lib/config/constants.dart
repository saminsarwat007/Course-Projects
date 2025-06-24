class AppConstants {
  // App information
  static const String appName = 'Agrothink';
  static const String appTagline = 'Your AI Farming Assistant';

  // Onboarding information
  static const List<Map<String, String>> onboardingData = [
    {
      'title': 'Welcome to Agrothink',
      'description': 'Your AI Farming Assistant',
    },
    {
      'title': 'AGROX',
      'description': 'Your ultimate agriculture knowledge helper',
    },
    {
      'title': 'AI-Powered Disease Detection',
      'description':
          'Upload images to let our AI identify and manage crop diseases',
    },
    {
      'title': 'AI Planting Guide',
      'description':
          'Get an AI-generated planting guide for your seeds with a proper timeline.',
    },
    {
      'title': 'AI-Powered To-Do List',
      'description':
          'Let our AI help you manage and schedule your farming tasks.',
    },
    {
      'title': 'AI Crop Monitoring',
      'description':
          'Monitor your crops with IoT devices and get AI-driven insights.',
    },
    {
      'title': 'AI-Curated Updates',
      'description':
          'Get AI-curated updates on food prices, weather warnings, and agricultural news',
    },
  ];

  // Government user
  static const String governmentEmailDomain = '@graduate.utm.my';
  static const String governmentPassword = '12345678';

  // API endpoints (mock for frontend)
  static const String chatbotEndpoint = 'api/chatbot';
  static const String diseaseDetectionEndpoint = 'api/disease-detection';
  static const String newsFeedEndpoint = 'api/news';

  // Error messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError =
      'Network error. Please check your connection.';
  static const String authError = 'Authentication failed. Please try again.';

  // Success messages
  static const String loginSuccess = 'Login successful!';
  static const String signupSuccess = 'Account created successfully!';
  static const String formSubmitSuccess = 'Form submitted successfully!';

  // Feature titles
  static const String chatbotTitle = 'AGROX';
  static const String diseaseDetectionTitle = 'Crop Disease Detection';
  static const String newsFeedTitle = 'News Feed';
  static const String plantingGuideTitle = 'Planting Guide';
  static const String foodPriceTitle = 'Food Price Alerts';
  static const String weatherWarningTitle = 'Weather Warnings';
  static const String agricultureNewsTitle = 'Agriculture News';
}
