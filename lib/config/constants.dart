import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// App informations
const APP_NAME = "Muslim Digest";
const APP_TAGLINE = "Your daily Muslim digest.";
const APP_DESCRIPTION = "Your daily window into the Muslim world.";
const APP_COPYRIGHT = "Taufik Nur Rahmanda";
const APP_COMPANY = "TARRA Soft";
const APP_COMPANY_EMAIL = "flias.test@gmail.com";

// App URLs
// TODO: Update these URLs with actual values
const APP_URL_APPSTORE = null; // "https://apps.apple.com/id/app/foom-now/id6470125134";
const APP_URL_PLAYSTORE = "https://play.google.com/store/apps/details?id=com.tarra.muslimdigest";
const APP_URL_PRIVACY = "https://www.termsfeed.com/live/4dcaac7c-a1ba-479c-b8c6-5874e7528f51";

const APP_URL_DONATE = "https://sociabuzz.com/txufiknr/donate";

// API URLs from environment variables
final APP_URL_API = dotenv.env['APP_URL_API']!;
final APP_URL_API_DEV = dotenv.env['APP_URL_API_DEV']!;

// App assets
const APP_ASSETS_LOGO = "assets/images/icons/logo.png";
const APP_FONT_FAMILY = "SourceSans3";

// App languages
const GREETINGS = "As-salamu alaykum";

// Debug configurations
const APP_IS_PRODUCTION = kReleaseMode;
const APP_IS_DEVELOPMENT = kDebugMode;
const APP_USE_PRODUCTION_API = false;