import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:muslimdigest/config/constants.dart';
import 'package:muslimdigest/config/themes.dart';
import 'package:muslimdigest/config/router.dart';
import 'package:muslimdigest/utils/variables.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';

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
      allowList: <String>{ 'user_id', 'theme' },
    ),
  );
  
  // Run the app
  runApp(const MyApp());
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
        AppTheme(id: APP_UI_THEME_LIGHT, description: "Light Theme", data: AppThemes.lightTheme),
        AppTheme(id: APP_UI_THEME_DARK, description: "Dark Theme", data: AppThemes.darkTheme),
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