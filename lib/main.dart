import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config/constants.dart';
import 'config/themes.dart';
import 'config/router.dart';
import 'variables/app.dart';
import 'package:theme_provider/theme_provider.dart';
import 'providers/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Set preferred orientation to portrait
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Hide status bar
  if (kDebugMode) SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);

  // Initialize shared preferences with cache
  prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: <String>{
        'user', // User data (JSON string with uuid v7)
        'preferences', // App preferences (JSON string)
        'theme', // Theme preference ("dark" or "light")
        'read_last_date', // Last read date (YYYY-MM-DD)
        'read_count', // Daily read count (number)
        'read_count_states', // Daily read count states (JSON string)
        'settings', // User settings data (JSON string)
        'streaks', // User streaks data (JSON string)
        'ingest_last_date', // Last feed ingestion date (YYYY-MM-DD)
        'topic', // Selected feed topic (string)
        'topics', // List of available topics (JSON string)
        'feed_type', // Active feed type (string)
        'notification_type', // Active notification type (string)
      },
    ),
  );

  // Initialize secure storage for feed cache
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      // encryptedSharedPreferences: true, // Deprecated - using custom ciphers
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  // Run the app
  runApp(
    // Override the provider with the actual instance
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        secureStorageProvider.overrideWithValue(secureStorage),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    // Provide custom themes to choose at runtime
    return ThemeProvider(
      saveThemesOnChange: true,
      loadThemeOnInit: true,
      defaultThemeId: prefs.getString('theme') ?? defaultTheme,
      onThemeChanged: (_, newTheme) => prefs.setString('theme', newTheme.id),
      themes: [
        AppTheme(id: Brightness.light.name, description: "Light Theme", data: AppThemes.lightTheme),
        AppTheme(id: Brightness.dark.name, description: "Dark Theme", data: AppThemes.darkTheme),
      ],
      child: ThemeConsumer(
        child: Builder(
          builder: (themeContext) => MaterialApp.router(
            title: APP_NAME,
            theme: ThemeProvider.themeOf(themeContext).data,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      ),
    );
  }
}