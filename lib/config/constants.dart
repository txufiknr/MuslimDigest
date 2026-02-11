import 'package:flutter_dotenv/flutter_dotenv.dart';

const APP_NAME = "Muslim Digest";
const APP_TAGLINE = "Your daily Muslim digest.";
const APP_DESCRIPTION = "Your daily window into the Muslim world.";
const APP_COPYRIGHT = "Taufik Nur Rahmanda";
const APP_COMPANY = "TARRA Soft";

const APP_UI_THEME_LIGHT = "light_theme";
const APP_UI_THEME_DARK = "dark_theme";

const APP_URL_PLAYSTORE = "https://play.google.com/store/apps/details?id=com.tarra.muslimdigest";
const APP_URL_PRIVACY = "https://www.termsfeed.com/live/4dcaac7c-a1ba-479c-b8c6-5874e7528f51";
const APP_URL_DONATE = "https://sociabuzz.com/txufiknr/donate";

// API URLs from environment variables
final APP_URL_API = dotenv.env['APP_URL_API']!;
final APP_URL_API_DEV = dotenv.env['APP_URL_API_DEV']!;
