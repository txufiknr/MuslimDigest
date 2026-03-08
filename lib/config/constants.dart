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
final APP_USER_AGENT = dotenv.env['APP_USER_AGENT'] ?? "MuslimDigestApp";

// App assets
const APP_ASSETS_LOGO = "assets/images/icons/logo.png";
const APP_FONT_FAMILY = "SourceSans3";
// const APP_FONT_FAMILY = "Outfit";
// const APP_FONT_FAMILY = "LeagueSpartan";

// App languages
const APP_LOCALE = Locale('en', 'US');
const APP_LANGUAGE = 'en';

const PROMO_MESSAGE = 'Check out $APP_NAME and level up your Islamic knowledge';
const SHARE_MESSAGE = '$PROMO_MESSAGE with daily high-quality digests:\n$APP_URL_PLAYSTORE';
const GREETINGS = "As-salamu alaykum";
const MESSAGES = [
  "May this knowledge benefit you.",
  "May Allah increase you in understanding.",
  "May it be a source of light.",
  "Consistency builds clarity.",
  "Small daily steps lead to lasting knowledge.",
  "One day closer to stronger understanding.",
  "Seeking knowledge is an act of worship.",
  "May your intention be sincere.",
];

const NOTIFICATIONS = [
  "A moment of learning can be a form of worship 📖",
  "Angels lower their wings for the seeker of knowledge 🌺",
  "The seeking of knowledge is obligatory for every Muslim 🕌",
  "Knowledge illuminates the path to wisdom ✨",
  "Read in the name of your Lord who created 📚",
  "Seek knowledge from the cradle to the grave 🌅",
  "The ink of the scholar is more sacred than the blood of the martyr 🖋️",
  "He who travels seeking knowledge, Allah makes his path to Paradise easy 🛤️",
  "Knowledge is a treasure, but practice is the key to it 🔑",
  "The best of people are those who are most beneficial to others 🤝",
  "A single verse of the Quran is better than a thousand prayers 💎",
  "Learning in youth is like engraving on stone 🗿",
  "The pursuit of knowledge is a journey to Allah 🕋",
  "Wisdom is the lost property of the believer 💡",
  "Teach others what you have learned, and you will truly understand 🎓",
  "Every act of kindness is charity, including sharing knowledge 🌟",
  "The more you know, the more you realize how much you need to learn 🌊",
  "Patience in seeking knowledge brings abundant rewards ⏳",
  "A day without learning is a day wasted ⏰",
  "The Quran is a guide for those who reflect 🧠",
];

// Debug configurations
const APP_IS_PRODUCTION = kReleaseMode;
const APP_IS_DEVELOPMENT = kDebugMode;
const APP_USE_PRODUCTION_API = true;