enum MoreApp {
  // adhan('adhan', 'Adhan Notifier'),
  alquran('alquran', 'Quran Recite'),
  tasbih('tasbih', 'Dhikr Counter'),
  qibla('qibla', 'Qibla Locator'),
  zakat('zakat', 'Zakat Calculator');

  const MoreApp(this.id, this.title);

  String get image => 'assets/images/more/$id.png';

  final String id;
  final String title;
}
