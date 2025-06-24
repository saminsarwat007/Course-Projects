import 'package:flutter/material.dart';
import 'package:agrothink/screens/onboarding/onboarding_screen.dart';
import 'package:agrothink/screens/auth/login_screen.dart';
import 'package:agrothink/screens/auth/signup_screen.dart';
import 'package:agrothink/screens/auth/forgot_password_screen.dart';
import 'package:agrothink/screens/user/user_dashboard_screen.dart';
import 'package:agrothink/screens/user/chatbot_screen.dart';
import 'package:agrothink/screens/user/disease_detection_screen.dart';
import 'package:agrothink/screens/user/news_feed_screen.dart';
import 'package:agrothink/screens/government/government_dashboard_screen.dart';
import 'package:agrothink/screens/government/food_price_form_screen.dart';
import 'package:agrothink/screens/government/weather_warning_form_screen.dart';
import 'package:agrothink/screens/government/news_form_screen.dart';
import 'package:agrothink/screens/profile/profile_screen.dart';
import 'package:agrothink/screens/user/planting_guide_screen.dart';
import 'package:agrothink/screens/user/saved_guides_screen.dart';
import 'package:agrothink/screens/user/todo_list_screen.dart';
import 'package:agrothink/screens/government/government_controls_screen.dart';
import 'package:agrothink/screens/iot/iot_device_screen.dart';
import 'package:agrothink/screens/iot/data_dashboard_screen.dart';
// import 'package:agrothink/screens/iot/manual_input_screen.dart';

class AppRoutes {
  static const String onboarding = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String userDashboard = '/user/dashboard';
  static const String chatbot = '/user/chatbot';
  static const String diseaseDetection = '/user/disease-detection';
  static const String newsFeed = '/user/news-feed';
  static const String plantingGuide = '/user/planting-guide';
  static const String savedGuides = '/user/saved-guides';
  static const String todoList = '/user/todo-list';
  static const String governmentDashboard = '/government/dashboard';
  static const String foodPriceForm = '/government/food-price-form';
  static const String weatherWarningForm = '/government/weather-warning-form';
  static const String newsForm = '/government/news-form';
  static const String profile = ProfileScreen.routeName;
  static const String governmentControls = GovernmentControlsScreen.routeName;
  static const String iotDevice = IotDeviceScreen.routeName;
  static const String dataDashboard = DataDashboardScreen.routeName;
  // static const String manualInput = ManualInputScreen.routeName;

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      onboarding: (context) => const OnboardingScreen(),
      login: (context) => const LoginScreen(),
      signup: (context) => const SignupScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      userDashboard: (context) => const UserDashboardScreen(),
      chatbot: (context) => const ChatbotScreen(),
      diseaseDetection: (context) => const DiseaseDetectionScreen(),
      newsFeed: (context) => const NewsFeedScreen(),
      plantingGuide: (context) => const PlantingGuideScreen(),
      savedGuides: (context) => const SavedGuidesScreen(),
      todoList: (context) => const TodoListScreen(),
      governmentDashboard: (context) => const GovernmentDashboardScreen(),
      foodPriceForm: (context) => const FoodPriceFormScreen(),
      weatherWarningForm: (context) => const WeatherWarningFormScreen(),
      newsForm: (context) => const NewsFormScreen(),
      profile: (context) => const ProfileScreen(),
      governmentControls: (context) => const GovernmentControlsScreen(),
      iotDevice: (context) => const IotDeviceScreen(),
      dataDashboard: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return DataDashboardScreen(cropName: args['cropName']);
      },
      // manualInput: (context) {
      //   final cropName = ModalRoute.of(context)!.settings.arguments as String;
      //   return ManualInputScreen(cropName: cropName);
      // },
    };
  }
}
