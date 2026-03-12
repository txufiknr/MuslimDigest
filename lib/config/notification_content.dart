/// Enhanced notification content for Islamic daily reminders
/// 
/// Each notification contains a title, body, and emoji to provide
/// meaningful and encouraging content for Muslim users worldwide.
/// All content is designed to be respectful, kind, and motivating.
enum IslamicNotificationContent {
  // Knowledge & Learning (1-6)
  dailyWisdom("Daily Wisdom 📖", "Start your day with Islamic knowledge. Open Muslim Digest for today's inspirational content.", "📖"),
  seekingKnowledge("Seek Knowledge 🌺", "Angels lower their wings for seekers of knowledge. Continue your learning journey with us.", "🌺"),
  obligatoryLearning("Path of Knowledge 🕌", "The seeking of knowledge is obligatory for every Muslim. Discover more insights today.", "🕌"),
  quranGuidance("Quranic Reflection ✨", "The Quran is a guide for those who reflect. Find your daily inspiration in Muslim Digest.", "✨"),
  readInHisName("Read in His Name 📚", "Read in the name of your Lord who created. Begin your spiritual journey today.", "📚"),
  quranicWisdom("Sacred Verses 💎", "A single verse of Quran is better than a thousand prayers. Explore more divine wisdom.", "💎"),
  
  // Personal Development (7-12)
  characterBuilding("Character Matters 🤝", "The best of people are those who are most beneficial to others. Be a blessing today.", "🤝"),
  patienceReward("Patience & Rewards ⏳", "Patience in seeking knowledge brings abundant rewards. Stay steadfast in your journey.", "⏳"),
  dailyLearning("Never Stop Learning 🌅", "Seek knowledge from cradle to grave. Every day is an opportunity to grow.", "🌅"),
  sincereIntention("Pure Intentions 💡", "May your intention be sincere. Find content that nourishes your soul in Muslim Digest.", "💡"),
  spiritualJourney("Journey to Allah 🕋", "The pursuit of knowledge is a journey to Allah. Take another step forward today.", "🕋"),
  wisdomTreasure("Wisdom is Treasure 🔑", "Knowledge is a treasure, but practice is the key. Apply what you learn today.", "🔑"),
  
  // Community & Sharing (13-18)
  sharingKnowledge("Share & Grow 🎓", "Teach others what you have learned, and you will truly understand. Spread wisdom.", "🎓"),
  actsOfKindness("Kindness is Charity 🌟", "Every act of kindness is charity, including sharing knowledge. Be a light for others.", "🌟"),
  beneficialToOthers("Be a Blessing 🤝", "The most complete believers are those who are best to others. Start with kindness today.", "🤝"),
  humbleService("Serve with Humility 🙏", "The best among you are those who serve others humbly. Find ways to help today.", "🙏"),
  unityStrength("Unity is Strength 🤲", "Believers are like a single body. Strengthen your community bonds today.", "🤲"),
  compassionHeart("Compassion Heart ❤️", "Show compassion to all creatures. Let kindness guide your actions today.", "❤️"),
  
  // Motivation & Encouragement (19-24)
  learningEngraving("Lasting Knowledge 🗿", "Learning in youth is like engraving on stone. Make your mark today.", "🗿"),
  scholarsInk("Sacred Knowledge 🖋️", "The ink of scholar is more sacred than blood of martyr. Value true wisdom.", "🖋️"),
  pathToParadise("Easy Path 🛤️", "He who travels seeking knowledge, Allah makes his path to Paradise easy.", "🛤️"),
  knowingMore("Humble Wisdom 🌊", "The more you know, the more you realize how much you need to learn. Stay humble.", "🌊"),
  dayNotWasted("Make It Count ⏰", "A day without learning is a day wasted. Invest your time wisely today.", "⏰"),
  reflectionTime("Time to Reflect 🧠", "The Quran is a guide for those who reflect. Take a moment for contemplation.", "🧠"),
  
  // Morning & Daily Inspiration (25-30)
  morningBlessing("Blessed Morning ☀️", "Start your day with gratitude and purpose. Muslim Digest has your daily inspiration.", "☀️"),
  spiritualNourishment("Soul Food 🍃", "Feed your soul with Islamic wisdom. Open Muslim Digest for spiritual nourishment.", "🍃"),
  gratefulHeart("Grateful Heart 🌹", "Begin each day counting your blessings. Gratitude opens doors to more blessings.", "🌹"),
  peacefulMind("Peaceful Mind 🕊️", "Find tranquility in remembrance. Let your heart find peace today.", "🕊️"),
  guidedSteps("Guided Steps 🌟", "Allah guides those who seek guidance. Trust in His divine plan today.", "🌟"),
  eternalWisdom("Eternal Wisdom 📿", "Timeless Islamic wisdom for modern life. Discover insights that transform.", "📿");

  const IslamicNotificationContent(this.title, this.body, this.emoji);

  final String title;
  final String body;
  final String emoji;

  /// Get a random notification content
  static IslamicNotificationContent getRandom() {
    final values = IslamicNotificationContent.values;
    return values[DateTime.now().millisecond % values.length];
  }

  /// Get daily notification content based on current date
  /// This ensures different content each day while being consistent for the same day
  static IslamicNotificationContent getDailyContent() {
    final values = IslamicNotificationContent.values;
    final now = DateTime.now();
    // Use day of year as seed for consistent daily rotation
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return values[dayOfYear % values.length];
  }

  /// Get rotating notification content for long-term scheduling
  /// This method ensures content rotates through all available options
  /// and repeats every N days where N is the total number of content items
  static IslamicNotificationContent getRotatingContent([DateTime? date]) {
    final values = IslamicNotificationContent.values;
    final targetDate = date ?? DateTime.now();
    // Use day of year modulo total content count for infinite rotation
    final dayOfYear = targetDate.difference(DateTime(targetDate.year, 1, 1)).inDays;
    return values[dayOfYear % values.length];
  }

  /// Get content for specific day of month (1-30)
  /// Used for monthly rotation scheduling
  static IslamicNotificationContent getContentForDay(int dayOfMonth) {
    final values = IslamicNotificationContent.values;
    // Ensure day is within 1-30 range
    final safeDay = (dayOfMonth - 1) % values.length;
    return values[safeDay];
  }

  /// Get the rotation period in days (total number of content items)
  static int get rotationPeriod => IslamicNotificationContent.values.length;

  /// Get all notification contents for testing
  static List<IslamicNotificationContent> get allValues => IslamicNotificationContent.values;
}
