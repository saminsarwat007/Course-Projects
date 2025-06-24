import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:agrothink/config/routes.dart';
import 'package:agrothink/config/theme.dart';
import 'package:agrothink/providers/auth_provider.dart';
import 'package:agrothink/providers/chatbot_provider.dart';
import 'package:agrothink/providers/disease_detection_provider.dart';
import 'package:agrothink/providers/news_provider.dart';
import 'package:agrothink/providers/planting_guide_provider.dart';
import 'package:agrothink/providers/location_provider.dart';
import 'package:agrothink/providers/todo_provider.dart';
import 'package:agrothink/providers/saved_guides_provider.dart';
import 'package:agrothink/screens/onboarding/onboarding_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:agrothink/providers/admin_provider.dart';
import 'package:agrothink/providers/feature_toggle_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agrothink/providers/iot_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase
  await Firebase.initializeApp();

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
    cacheSizeBytes: 10000000,
  );

  // Activate Firebase App Check
  await FirebaseAppCheck.instance.activate(
    // You can also use a `ReCaptchaEnterpriseProvider` provider based on your platform needs:
    // appleProvider: AppleProvider.debug,
    // androidProvider: AndroidProvider.debug,
    // webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ChatbotProvider>(
          create: (_) => ChatbotProvider(null),
          update: (_, auth, __) => ChatbotProvider(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, DiseaseDetectionProvider>(
          create: (_) => DiseaseDetectionProvider(null),
          update: (_, auth, __) => DiseaseDetectionProvider(auth),
        ),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProxyProvider<AuthProvider, TodoProvider>(
          create: (_) => TodoProvider(null),
          update: (_, auth, __) => TodoProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SavedGuidesProvider>(
          create: (_) => SavedGuidesProvider(null),
          update: (_, auth, __) => SavedGuidesProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AdminProvider>(
          create:
              (context) => AdminProvider(
                Provider.of<AuthProvider>(context, listen: false),
              ),
          update: (context, auth, previous) => previous!..updateAuth(auth),
        ),
        ChangeNotifierProvider(create: (_) => FeatureToggleProvider()),
        ChangeNotifierProxyProvider<AuthProvider, PlantingGuideProvider>(
          create: (_) => PlantingGuideProvider(null),
          update: (_, auth, __) => PlantingGuideProvider(auth),
        ),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => IotProvider()),
      ],
      child: MaterialApp(
        title: 'Agrothink',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        routes: AppRoutes.getRoutes(),
        initialRoute: AppRoutes.onboarding,
      ),
    );
  }
}
