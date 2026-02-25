import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// App informations
const APP_NAME = "Muslim Digest";
const APP_TAGLINE = "Your daily Muslim digest";
const APP_DESCRIPTION = "Your daily window into the Muslim world";
const APP_COPYRIGHT = "Taufik Nur Rahmanda";
const APP_COMPANY = "TARRA Soft";
const APP_COMPANY_EMAIL = "flias.test@gmail.com";

// App URLs
const APP_URL_PLAYSTORE = "https://play.google.com/store/apps/details?id=com.tarra.muslimdigest";
const APP_URL_PRIVACY = "https://www.termsfeed.com/live/f42c0040-062b-46d8-b070-ddcf8df1bdb4";
const APP_URL_DONATE = "https://sociabuzz.com/txufiknr/donate";

// API URLs from environment variables
final APP_URL_API = dotenv.env['APP_URL_API']!;
final APP_URL_API_DEV = dotenv.env['APP_URL_API_DEV']!;

// App assets
const APP_ASSETS_LOGO = "assets/images/icons/logo.png";
const APP_FONT_FAMILY = "SourceSans3";

// App languages
const APP_LOCALE = Locale('en', 'US');
const GREETINGS = "As-salamu alaykum";
const MESSAGES = [
  "May this knowledge benefit you.",
  "May Allah increase you in understanding.",
  "May it be a source of light.",
  "Consistency builds clarity.",
  "Small daily steps lead to lasting knowledge.",
  "One day closer to stronger understanding.",
  "Seeking knowledge is an act of worship.",
  "Angels lower their wings for the seeker of knowledge.",
  "May your intention be sincere.",
];

// Debug configurations
const APP_IS_PRODUCTION = kReleaseMode;
const APP_IS_DEVELOPMENT = kDebugMode;
const APP_USE_PRODUCTION_API = true;