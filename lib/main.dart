import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'Welcome.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    print("[INFO] Firebase initialized successfully.");
  } catch (e) {
    print("[ERROR] Firebase initialization failed: $e");
  }

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: 'https://avbrdsoyyewgqenccnko.supabase.co',
      anonKey:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF2YnJkc295eWV3Z3FlbmNjbmtvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE3NzY4MjgsImV4cCI6MjA0NzM1MjgyOH0.y02J4ot-QtthI_H3-rC-lAWoSNJq4MqaAUwh0mIyetQ',
    );
    print("[INFO] Supabase initialized successfully.");
  } catch (e) {
    print("[ERROR] Supabase initialization failed: $e");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static final ValueNotifier<Locale> localeNotifier =
  ValueNotifier<Locale>(const Locale('en'));

  const MyApp({super.key}); // Default locale

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, child) {
        return MaterialApp(
          title: 'Flutter Demo',
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const Welcome(),
        );
      },
    );
  }

  static void changeLocale(String languageCode) {
    localeNotifier.value = Locale(languageCode);
    print("[INFO] Locale changed to: $languageCode");
  }
}
