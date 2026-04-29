import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const PomocatApp());

// ── App ────────────────────────────────────────────────────────────────────────

class PomocatApp extends StatelessWidget {
  const PomocatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flororo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7BC67E)),
        textTheme: GoogleFonts.nunitoTextTheme(),
      ),
      home: const _StartupScreen(),
    );
  }
}

// ── Models ─────────────────────────────────────────────────────────────────────

class Flower {
  final String name;
  final String label;
  final List<String> stages;
  final String description;
  final bool hasSeedAsset;
  final bool hasMidAsset;
  final List<String> traits;
  final String latinName;
  const Flower({required this.name, required this.label, required this.stages,
      this.description = '', this.traits = const [], this.latinName = '',
      this.hasSeedAsset = false, this.hasMidAsset = false});
  String get emoji => stages.last;
  String stage(int level) => stages[level.clamp(0, stages.length - 1)];
  String? get assetPath => name != 'mystery' ? 'assets/flowers/$name.png' : null;

  String? assetForLevel(int level) {
    if (name == 'mystery') return null;
    if (level >= 3) return 'assets/flowers/$name.png';
    if (level >= 1 && hasMidAsset) return 'assets/flowers/${name}_mid.png';
    if (level == 0 && hasSeedAsset) return 'assets/flowers/${name}_seed.png';
    return null;
  }

  String? get fullAsset => name != 'mystery' ? 'assets/flowers/$name.png' : null;
}

class MarketItem {
  final String id;
  final String name;
  final String emoji;
  final int price;
  final String description;
  final bool isTreat;
  final int growthBonus;
  const MarketItem({
    required this.id, required this.name, required this.emoji,
    required this.price, required this.description,
    this.isTreat = false, this.growthBonus = 0,
  });
}

class Achievement {
  final String id;
  final String emoji;
  final String title;
  final String description;
  const Achievement({required this.id, required this.emoji,
      required this.title, required this.description});
}

class CraftingPotion {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final Map<String, int> recipe; // flower name → count
  final String effectType;
  final int effectValue;
  const CraftingPotion({
    required this.id, required this.name, required this.emoji,
    required this.description, required this.recipe,
    required this.effectType, this.effectValue = 0,
  });
}

class DailyTask {
  final String id;
  final String text;
  final String type; // 'sessions' | 'minutes' | 'water'
  final int target;
  final int reward;
  const DailyTask({required this.id, required this.text,
      required this.type, required this.target, required this.reward});
}

// ── Data ───────────────────────────────────────────────────────────────────────

const List<Flower> flowers = [
  Flower(
    name: 'rose', label: 'Gül', stages: ['🌱', '🌿', '🌸', '🌹'],
    description: 'Aşkın ve güzelliğin simgesi. Binlerce yıldır şairlere ilham vermiştir. Dikenleri onu korur, kokusu ise herkesi büyüler.',
    latinName: 'Rosa × hybrida',
    traits: ['☀️ Güneşli günlerde +%50 büyür', '🌧️ Yağmurda otomatik sulanır, yavaş büyür'],
    hasSeedAsset: true, hasMidAsset: true,
  ),
  Flower(
    name: 'sunflower', label: 'Ayçiçeği', stages: ['🌱', '🌿', '🌸', '🌻'],
    description: 'Her zaman güneşe döner. Umut ve neşenin sembolü. Tohumları hem kuşlar hem de insanlar için küçük bir hazinedir.',
    latinName: 'Helianthus annuus',
    traits: ['☀️ Güneşli günlerde +%50 büyür', '🌧️ Yağmurda otomatik sulanır, yavaş büyür'],
    hasSeedAsset: true, hasMidAsset: true,
  ),
  Flower(
    name: 'tulip', label: 'Lale', stages: ['🌱', '🌿', '🌸', '🌷'],
    description: 'Osmanlı\'dan dünyaya yayılan zariflik. Kısa ömrüne rağmen baharın en parlak müjdecisidir.',
    latinName: 'Tulipa gesneriana',
    traits: ['☀️ Güneşli günlerde +%50 büyür', '🌧️ Yağmurda otomatik sulanır, yavaş büyür'],
  ),
  Flower(
    name: 'cactus', label: 'Kaktüs', stages: ['🌱', '🌵', '🌵', '🌵'],
    description: 'En zorlu koşullarda bile dimdik durur. Susuzluğa meydan okur, içinde su saklar. Sessiz ama güçlüdür.',
    latinName: 'Opuntia ficus-indica',
    traits: ['💧 5 güne kadar susuz dayanır', '🌧️ Yağmurda büyümesi yavaşlar'],
  ),
  Flower(
    name: 'lotus', label: 'Lotus', stages: ['🌱', '🌿', '🌸', '🪷'],
    description: 'Çamurdan doğar, tertemiz açılır. Budizm\'de aydınlanmanın simgesi. Su üzerinde süzülen bir mucizedir.',
    latinName: 'Nelumbo nucifera',
    traits: ['🌧️ Yağmuru sever, yağmurda +%50 büyür', '☀️ Güneşli günlerde +%50 büyür'],
    hasSeedAsset: true, hasMidAsset: true,
  ),
  Flower(
    name: 'orchid', label: 'Orkide', stages: ['🌱', '🌿', '🌸', '🌸'],
    description: 'Egzotik güzelliğin simgesi. Binlerce türüyle dünyanın her köşesinde yetişir. İnce yapısı ve uzun ömrüyle eşsizdir.',
    latinName: 'Phalaenopsis amabilis',
    traits: ['☀️ Güneşli günlerde +%50 büyür', '🌧️ Yağmurda otomatik sulanır, yavaş büyür'],
    hasSeedAsset: true, hasMidAsset: true,
  ),
  Flower(
    name: 'mystery', label: 'Karışık Tohum', stages: ['🌱', '🌿', '🌸', '❓'],
    description: 'Ne çıkacağı belli olmaz. Sürprizleri seven bahçıvanlar için özel bir tohum.',
  ),
];

const List<String> _realFlowers = ['rose', 'sunflower', 'tulip', 'cactus', 'lotus', 'orchid'];

const List<CraftingPotion> potionRecipes = [
  CraftingPotion(
    id: 'sun_elixir', name: 'Güneş İksiri', emoji: '☀️',
    description: 'Bugünün havasını güneşli yapar — büyüme hızlanır',
    recipe: {'rose': 1, 'sunflower': 1}, effectType: 'weather_sunny',
  ),
  CraftingPotion(
    id: 'bug_shield', name: 'Böcek Kalkanı', emoji: '🛡️',
    description: '3 gün boyunca böcek gelmez',
    recipe: {'cactus': 1, 'lotus': 1}, effectType: 'bug_shield', effectValue: 3,
  ),
  CraftingPotion(
    id: 'speed_boost', name: 'Hız İksiri', emoji: '⚡',
    description: '30 dakika boyunca 3× sun kazanırsın',
    recipe: {'orchid': 1, 'rose': 1}, effectType: 'speed_boost', effectValue: 30,
  ),
  CraftingPotion(
    id: 'rain_elixir', name: 'Yağmur İksiri', emoji: '🌧️',
    description: 'Çiçeğini otomatik sular',
    recipe: {'tulip': 1, 'lotus': 1}, effectType: 'weather_rainy',
  ),
  CraftingPotion(
    id: 'light_burst', name: 'Işık Tufanı', emoji: '🌟',
    description: '+80 büyüme bonusu',
    recipe: {'sunflower': 2}, effectType: 'sun_bonus', effectValue: 80,
  ),
  CraftingPotion(
    id: 'wizards_brew', name: 'Büyücü İksiri', emoji: '🔮',
    description: 'Kurumayı iyileştirir, böcekleri temizler, +30 büyüme',
    recipe: {'tulip': 1, 'orchid': 1, 'rose': 1},
    effectType: 'full_restore', effectValue: 30,
  ),
  CraftingPotion(
    id: 'butterfly_dust', name: 'Kelebek Tozu', emoji: '🌈',
    description: 'Kelebeklerin büyüsüyle çiçeğine +100 ☀️ güneş kazandırır.',
    recipe: {'butterfly': 2},
    effectType: 'sun_bonus', effectValue: 100,
  ),
  CraftingPotion(
    id: 'spring_breeze', name: 'Bahar Rüzgarı', emoji: '🌺',
    description: 'Böcekleri temizler ve 2 gün boyunca böcek gelmez',
    recipe: {'butterfly': 1, 'tulip': 1},
    effectType: 'bug_shield', effectValue: 2,
  ),
  CraftingPotion(
    id: 'dawn_elixir', name: 'Şafak İksiri', emoji: '🌄',
    description: 'Çiçeği sular ve bugünü güneşli yapar',
    recipe: {'butterfly': 1, 'sunflower': 1},
    effectType: 'water_and_sunny',
  ),
  CraftingPotion(
    id: 'wing_whisper', name: 'Kanat Fısıltısı', emoji: '✨',
    description: '60 dakika boyunca 3× sun kazanırsın',
    recipe: {'butterfly': 2, 'orchid': 1},
    effectType: 'speed_boost', effectValue: 60,
  ),
  CraftingPotion(
    id: 'butterfly_swarm', name: 'Kelebek Sürüsü', emoji: '🦋',
    description: 'Üç kelebeğin gücüyle +150 ☀️ bonus',
    recipe: {'butterfly': 3},
    effectType: 'sun_bonus', effectValue: 150,
  ),
];

const List<DailyTask> taskPool = [
  DailyTask(id: 'p2',  text: '2 pomodoro tamamla',   type: 'sessions', target: 2,  reward: 35),
  DailyTask(id: 'p3',  text: '3 pomodoro tamamla',   type: 'sessions', target: 3,  reward: 55),
  DailyTask(id: 'm25', text: '25 dakika odaklan',     type: 'minutes',  target: 25, reward: 30),
  DailyTask(id: 'm50', text: '50 dakika odaklan',     type: 'minutes',  target: 50, reward: 50),
  DailyTask(id: 'w1',  text: 'Çiçeğini sula',         type: 'water',    target: 1,  reward: 20),
  DailyTask(id: 'p1',  text: '1 pomodoro tamamla',   type: 'sessions', target: 1,  reward: 20),
  DailyTask(id: 'm60', text: '1 saat odaklan',        type: 'minutes',  target: 60, reward: 65),
];

const List<MarketItem> marketItems = [
  MarketItem(id: 'water',      name: 'Su',            emoji: '💧', price: 20,  description: 'Çiçeğini suvala! +15 büyüme',  isTreat: true, growthBonus: 15),
  MarketItem(id: 'pesticide',    name: 'Böcek İlacı',       emoji: '🧪', price: 80,  description: 'Böcekleri temizle! Büyüme normale döner.', isTreat: true),
  MarketItem(id: 'revival',      name: 'Canlandırma İksiri', emoji: '🫧', price: 350, description: 'Kurumuş çiçeği anında canlandırır.', isTreat: true),
  MarketItem(id: 'streak_freeze',name: 'Dondurucu',          emoji: '❄️', price: 120, description: 'Bir günlük streak kaybını engeller!', isTreat: true),
  MarketItem(id: 'sprinkler',   name: 'Fıskiye',             emoji: '💦', price: 280, description: '3 gün boyunca çiçeğini otomatik sular.', isTreat: true),
  MarketItem(id: 'stone',        name: 'Dekoratif Taş',      emoji: '🪨', price: 50,  description: 'Saksına güzel bir dokunuş'),
  MarketItem(id: 'fertilizer',   name: 'Gübre',              emoji: '🌿', price: 150, description: 'Toprağı besle! +40 büyüme', growthBonus: 40),
  MarketItem(id: 'fancy_pot',    name: 'Süslü Saksı',        emoji: '🪴', price: 120, description: 'Çiçeğine özel saksı'),
];

const List<Achievement> achievements = [
  // Çiçek yetiştirme
  Achievement(id: 'first_sprout',    emoji: '🌿', title: 'İlk Filiz',          description: 'Bitkine can suyu ver'),
  Achievement(id: 'full_bloom',      emoji: '🌸', title: 'Tam Çiçek',          description: 'Bir çiçek yetiştir'),
  Achievement(id: 'gardener',        emoji: '🌻', title: 'Bahçıvan',            description: '5 çiçek yetiştir'),
  Achievement(id: 'master_gardener', emoji: '🏡', title: 'Usta Bahçıvan',       description: '20 çiçek yetiştir'),
  // Odaklanma
  Achievement(id: 'focused_1',       emoji: '⏱️', title: 'Odaklanan',           description: '60 dakika odaklan'),
  Achievement(id: 'focused_2',       emoji: '🔥', title: 'Azimli',              description: '600 dakika odaklan'),
  Achievement(id: 'focused_3',       emoji: '💎', title: 'Efsane Bahçıvan',     description: '6000 dakika odaklan'),
  // Sulama
  Achievement(id: 'water_1',         emoji: '💧', title: 'Sulayıcı',            description: 'Çiçeğini 1 kez sula'),
  Achievement(id: 'water_2',         emoji: '🚿', title: 'Sulama Ustası',       description: '10 kez sula'),
  Achievement(id: 'water_3',         emoji: '⛲', title: 'Sulama Şampiyonu',    description: '100 kez sula'),
  // Seri
  Achievement(id: 'streak_3',        emoji: '📅', title: 'Düzenli',             description: '3 gün seri yap'),
  Achievement(id: 'streak_7',        emoji: '🗓️', title: 'Haftalık Ritim',      description: '7 gün seri yap'),
  Achievement(id: 'streak_30',       emoji: '🏆', title: 'Aylık Alışkanlık',    description: '30 gün seri yap'),
  // Özel
  Achievement(id: 'mystery_grower',  emoji: '❓', title: 'Meraklı Bahçıvan',   description: 'Karışık tohum büyüt'),
];

class CollectedFlower {
  final String uid;
  final String name;
  final String customName;
  final String emoji;
  final String date;
  final int minutesWorked;
  CollectedFlower({
    String? uid,
    required this.name, required this.customName,
    required this.emoji, required this.date, this.minutesWorked = 0,
  }) : uid = uid ?? DateTime.now().millisecondsSinceEpoch.toString();

  String encode() => '$uid\x1f$name\x1f$customName\x1f$emoji\x1f$date\x1f$minutesWorked';

  factory CollectedFlower.decode(String s) {
    final p = s.split('\x1f');
    if (p.length >= 6) {
      // Yeni format: uid|name|customName|emoji|date|minutesWorked
      return CollectedFlower(
        uid: p[0], name: p[1], customName: p[2], emoji: p[3],
        date: p[4], minutesWorked: int.tryParse(p[5]) ?? 0,
      );
    }
    // Eski format: name|customName|emoji|date|minutesWorked — uid üret
    return CollectedFlower(
      uid: '${p[0]}_${p[3]}',
      name: p[0], customName: p[1], emoji: p[2], date: p[3],
      minutesWorked: p.length > 4 ? (int.tryParse(p[4]) ?? 0) : 0,
    );
  }

  CollectedFlower withName(String newName) =>
      CollectedFlower(uid: uid, name: name, customName: newName,
          emoji: emoji, date: date, minutesWorked: minutesWorked);
}

// ── Helpers ────────────────────────────────────────────────────────────────────

String currentSeason() {
  final m = DateTime.now().month;
  if (m >= 3 && m <= 5) return 'spring';
  if (m >= 6 && m <= 8) return 'summer';
  if (m >= 9 && m <= 11) return 'autumn';
  return 'winter';
}

String seasonEmoji(String season) => switch (season) {
  'spring' => '🌸',
  'summer' => '🌞',
  'autumn' => '🍂',
  'winter' => '❄️',
  _        => '',
};

String seasonalWeather(int month, int roll) {
  if (month >= 6 && month <= 8) // Yaz — çok güneşli
    return roll < 6 ? 'sunny' : roll < 8 ? 'cloudy' : 'rainy';
  if (month == 12 || month <= 2) // Kış — az güneş, çok yağmur
    return roll < 2 ? 'sunny' : roll < 5 ? 'cloudy' : 'rainy';
  if (month >= 9 && month <= 11) // Sonbahar
    return roll < 3 ? 'sunny' : roll < 6 ? 'cloudy' : 'rainy';
  // İlkbahar (varsayılan)
  return roll < 4 ? 'sunny' : roll < 7 ? 'cloudy' : 'rainy';
}


int sunToLevel(int totalSun) {
  if (totalSun >= 300) return 3;
  if (totalSun >= 150) return 2;
  if (totalSun >= 50)  return 1;
  return 0;
}

int nextLevelThreshold(int totalSun) {
  if (totalSun < 50)  return 50;
  if (totalSun < 150) return 150;
  if (totalSun < 300) return 300;
  return 300;
}

// Lojistik büyüme eğrisi: yavaş başla, ortada hızlan, sona doğru yavaşla.
// t ∈ [0,1] → [0,1], k steepness (6 iyi görünüyor)
double sigmoidProgress(double t, {double k = 6.0}) {
  final raw = 1.0 / (1.0 + exp(-k * (t - 0.5)));
  final lo  = 1.0 / (1.0 + exp( k * 0.5));
  final hi  = 1.0 / (1.0 + exp(-k * 0.5));
  return ((raw - lo) / (hi - lo)).clamp(0.0, 1.0);
}

String resolvedMysteryEmoji(String? resolved) {
  const emojis = {'rose': '🌹', 'sunflower': '🌻', 'tulip': '🌷', 'cactus': '🌵', 'lotus': '🪷'};
  return emojis[resolved] ?? '🌸';
}

String _todayStr() => _dateStr(DateTime.now());

String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

// ── Startup Router ────────────────────────────────────────────────────────────

class _StartupScreen extends StatefulWidget {
  const _StartupScreen();
  @override
  State<_StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<_StartupScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboardingDone') ?? false;
    final savedFlower = prefs.getString('selectedFlower');
    if (!mounted) return;
    if (!onboardingDone) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    } else if (savedFlower != null) {
      final flower = flowers.firstWhere((f) => f.name == savedFlower,
          orElse: () => flowers.first);
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => MainScreen(flower: flower)));
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const FlowerSelectScreen()));
    }
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(backgroundColor: Color(0xFFF4FBF4));
}

// ── Onboarding Screen ─────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingPage(
      emoji: '🌱',
      title: 'Flororo\'ya hoş geldin',
      body: 'Odaklanarak çiçek yetiştir. Ne kadar çok çalışırsan, çiçeğin o kadar çabuk açar.',
    ),
    _OnboardingPage(
      emoji: '⏱️',
      title: 'Nasıl çalışır?',
      body: 'Pomodoro seansını tamamla → ☀️ güneş kazan → çiçeğin büyür.\nHer gün sulamayı unutma, yoksa solar.',
    ),
    _OnboardingPage(
      emoji: '🧪',
      title: 'Simya atölyesi',
      body: 'Bir çiçek yetiştir, bahçenden hasat et, kazana at ve ne çıkacağını bekle.\nGizemli iksirler seni bekliyor ✨',
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingDone', true);
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const FlowerSelectScreen()));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF4),
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('geç', style: TextStyle(
                    color: Color(0xFF8CAF8E), fontSize: 13)),
              ),
            ),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _page == i ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _page == i
                      ? const Color(0xFF5AAE61)
                      : const Color(0xFFB2DFBB),
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            const SizedBox(height: 28),
            // Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _ScaleTap(
                onTap: _next,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5AAE61),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      _page == _pages.length - 1 ? 'Hadi başlayalım! 🌱' : 'İleri',
                      style: const TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;
  const _OnboardingPage({required this.emoji, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 32),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                  color: Color(0xFF2E6B45))),
          const SizedBox(height: 16),
          Text(body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Color(0xFF6B8F71),
                  height: 1.6)),
        ],
      ),
    );
  }
}

// ── Flower Select Screen ───────────────────────────────────────────────────────

class FlowerSelectScreen extends StatefulWidget {
  const FlowerSelectScreen({super.key});

  @override
  State<FlowerSelectScreen> createState() => _FlowerSelectScreenState();
}

class _FlowerSelectScreenState extends State<FlowerSelectScreen> {
  int _selected = 0;
  final _nameController = TextEditingController();

  @override
  void dispose() { _nameController.dispose(); super.dispose(); }

  Future<void> _start() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('flowerName', _nameController.text.trim());
    final flower = flowers[_selected];
    await prefs.setString('selectedFlower', flower.name);
    if (flower.name == 'mystery') {
      final resolved = _realFlowers[Random().nextInt(_realFlowers.length)];
      await prefs.setString('resolvedMystery', resolved);
      // Başarım: karışık tohum
      final earned = Set<String>.from(prefs.getStringList('achievements') ?? []);
      earned.add('mystery_grower');
      await prefs.setStringList('achievements', earned.toList());
    }
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => MainScreen(flower: flower)));
  }

  @override
  Widget build(BuildContext context) {
    final flower = flowers[_selected];
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text('flororo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                      color: Color(0xFF5AAE61), letterSpacing: 1.5)),
              const SizedBox(height: 4),
              const Text('yetiştireceğin çiçeği seç',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8CAF8E))),
              const SizedBox(height: 16),

              flower.fullAsset != null
                  ? Image.asset(flower.fullAsset!, width: 90, height: 90,
                      fit: BoxFit.contain, filterQuality: FilterQuality.none,
                      errorBuilder: (_, __, ___) => Text(flower.emoji,
                          style: const TextStyle(fontSize: 72)))
                  : Text(flower.emoji, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 6),
              Text(flower.label,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                      color: Color(0xFF3A5A3C))),
              if (flower.latinName.isNotEmpty)
                Text(flower.latinName,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF8CAF8E),
                        fontStyle: FontStyle.italic)),
              const SizedBox(height: 10),
              if (flower.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(flower.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8CAF8E), height: 1.4)),
                ),
              if (flower.traits.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6, runSpacing: 6,
                  children: flower.traits.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(t, style: const TextStyle(fontSize: 10, color: Color(0xFF4A7C59))),
                  )).toList(),
                ),
              ],

              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10, runSpacing: 10,
                children: List.generate(flowers.length, (i) {
                  final sel = i == _selected;
                  return _ScaleTap(
                    onTap: () => setState(() => _selected = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: sel ? 62 : 52, height: sel ? 62 : 52,
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFFD4EDDA) : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: sel ? const Color(0xFF5AAE61) : Colors.transparent, width: 2),
                      ),
                      child: Center(
                        child: flowers[i].fullAsset != null
                            ? Image.asset(flowers[i].fullAsset!,
                                width: sel ? 36 : 28, height: sel ? 36 : 28,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.none,
                                errorBuilder: (_, __, ___) => Text(flowers[i].emoji,
                                    style: TextStyle(fontSize: sel ? 30 : 24)))
                            : Text(flowers[i].emoji,
                                style: TextStyle(fontSize: sel ? 30 : 24)),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Color(0xFF3A5A3C)),
                decoration: InputDecoration(
                  hintText: 'çiçeğine bir isim ver 🌱',
                  hintStyle: const TextStyle(color: Color(0xFF8CAF8E), fontSize: 13),
                  filled: true, fillColor: const Color(0xFFE8F5E9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),

              const SizedBox(height: 16),
              _ScaleTap(
                onTap: _start,
                child: Container(
                  width: 180, height: 52,
                  decoration: BoxDecoration(color: const Color(0xFF5AAE61),
                      borderRadius: BorderRadius.circular(26)),
                  alignment: Alignment.center,
                  child: const Text('hadi büyütelim 🌱',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Main Screen ────────────────────────────────────────────────────────────────

class MainScreen extends StatefulWidget {
  final Flower flower;
  const MainScreen({super.key, required this.flower});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;
  int _balance = 0;
  int _totalSun = 0;
  Set<String> _purchased = {};
  String _flowerName = '';
  int _totalSecondsWorked = 0;
  String? _resolvedMystery;

  // İstatistik
  int _totalMinutesGlobal = 0;
  int _streak = 0;
  String _lastWorkDate = '';

  // Başarımlar
  Set<String> _earnedAchievements = {};
  int _totalWaterCount = 0;

  // Kuruma
  bool _isWilted = false;
  String _lastWateredDate = '';
  int _sprinklerDaysLeft = 0;

  // Bugünkü sulama
  int _watersTodayCount = 0;

  // Kutlama
  bool _showCelebration = false;
  int _lastLevel = 0;

  // Günlük hedef
  int _dailyGoalSessions = 3;
  int _sessionsToday = 0;

  // Seans bazlı arı sinyali
  int _pendingBeeSignal = 0;

  // Haftalık özet
  Map<String, int> _weeklyMinutes = {};

  // Hava durumu
  String _todayWeather = 'sunny'; // 'sunny', 'cloudy', 'rainy'

  // Böcek
  bool _hasBugs = false;

  // Crafting
  Map<String, int> _ingredients = {};
  Map<String, int> _craftedPotions = {};
  Set<String> _discoveredPotions = {};
  Map<String, int> _cauldronMix = {};
  int _brewStartMs = 0;
  int _brewDurationMs = 0;
  String _bugShieldUntil = '';   // ISO date string
  DateTime? _speedBoostEnd;

  // Streak dondurucu
  bool _hasStreakFreeze = false;

  // Günlük görev
  String _dailyTaskId = '';
  bool _dailyTaskDone = false;

  // Koleksiyon
  List<CollectedFlower> _collection = [];

  // Çiçek günlüğü — mevcut çiçek için harcanan dakika
  int _minutesThisFlower = 0;

  @override
  void initState() { super.initState(); _load(); }

  String get _flowerKey => widget.flower.name;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    final lastWatered = prefs.getString('lastWatered_$_flowerKey') ?? '';
    final daysSinceWater = lastWatered.isEmpty ? 999
        : DateTime.now().difference(DateTime.parse(lastWatered)).inDays;

    // Hava durumu — her gün bir kez üretilir
    String weather = prefs.getString('weather_$today') ?? '';
    if (weather.isEmpty) {
      final roll = Random().nextInt(10);
      weather = seasonalWeather(DateTime.now().month, roll);
      await prefs.setString('weather_$today', weather);
    }

    // Kuruma eşiği: yağmurluysa kurumaz, diğer durumlarda 2 gün (kaktüs 5)
    final isCactus = widget.flower.name == 'cactus';
    final wiltThreshold = isCactus ? 5
        : weather == 'rainy' ? 999
        : 2;

    // Fıskiye — her gün bir gün düşür, aktifse sula
    int sprinklerDaysLeft = prefs.getInt('sprinklerDaysLeft') ?? 0;
    final sprinklerLastTick = prefs.getString('sprinklerLastTick') ?? '';
    if (sprinklerDaysLeft > 0 && sprinklerLastTick != today) {
      sprinklerDaysLeft--;
      await prefs.setInt('sprinklerDaysLeft', sprinklerDaysLeft);
      await prefs.setString('sprinklerLastTick', today);
    }

    // Yağmurlu günde otomatik sulama (bir kez)
    final autoWatered = prefs.getString('autoWatered') ?? '';
    bool didAutoWater = false;
    final sprinklerActive = sprinklerDaysLeft > 0;
    if ((weather == 'rainy' || sprinklerActive) && autoWatered != today && lastWatered != today) {
      await prefs.setString('lastWatered_$_flowerKey', today);
      await prefs.setString('autoWatered', today);
      didAutoWater = true;
    }

    // Crafting — malzeme ve iksir envanteri
    final ingredientList = prefs.getStringList('ingredients') ?? [];
    final ingredientMap = <String, int>{};
    for (final s in ingredientList) {
      final parts = s.split(':');
      if (parts.length == 2) ingredientMap[parts[0]] = int.tryParse(parts[1]) ?? 0;
    }
    final craftedList = prefs.getStringList('craftedPotions') ?? [];
    final craftedMap = <String, int>{};
    for (final s in craftedList) {
      final parts = s.split(':');
      if (parts.length == 2) craftedMap[parts[0]] = int.tryParse(parts[1]) ?? 0;
    }
    final discoveredPotions = Set<String>.from(prefs.getStringList('discoveredPotions') ?? []);
    final cauldronList = prefs.getStringList('cauldronMix') ?? [];
    final cauldronMap = <String, int>{};
    for (final s in cauldronList) {
      final parts = s.split(':');
      if (parts.length == 2) cauldronMap[parts[0]] = int.tryParse(parts[1]) ?? 0;
    }
    final bugShieldUntil = prefs.getString('bugShieldUntil') ?? '';
    final bugShieldActive = bugShieldUntil.isNotEmpty &&
        DateTime.now().isBefore(DateTime.parse(bugShieldUntil));
    final speedBoostMs = prefs.getInt('speedBoostEndMs') ?? 0;
    final speedBoostEnd = speedBoostMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(speedBoostMs) : null;

    // Böcek sistemi — günde bir kez kontrol, level > 0 ise %30 ihtimalle böcek çıkar
    final savedTotalSun = prefs.getInt('totalSun_$_flowerKey') ?? 0;
    bool hasBugs = prefs.getBool('hasBugs_$_flowerKey') ?? false;
    if (bugShieldActive && hasBugs) {
      hasBugs = false;
      await prefs.setBool('hasBugs_$_flowerKey', false);
    }
    final bugCheckedDate = prefs.getString('bugChecked_$_flowerKey') ?? '';
    if (bugCheckedDate != today && sunToLevel(savedTotalSun) > 0 && !hasBugs && !bugShieldActive) {
      await prefs.setString('bugChecked_$_flowerKey', today);
      if (Random().nextInt(10) < 3) {
        hasBugs = true;
        await prefs.setBool('hasBugs_$_flowerKey', true);
      }
    }

    // Günlük görev — her gün tarihe göre belirli bir görev seçilir
    final taskIdx = today.hashCode.abs() % taskPool.length;
    final dailyTaskId = taskPool[taskIdx].id;
    final dailyTaskDone = prefs.getBool('dailyTask_done_$today') ?? false;

    setState(() {
      _balance             = prefs.getInt('balance') ?? 0;
      _totalSun            = prefs.getInt('totalSun_$_flowerKey') ?? 0;
      _purchased           = Set<String>.from(prefs.getStringList('purchased_$_flowerKey') ?? []);
      _flowerName          = prefs.getString('flowerName') ?? '';
      _totalSecondsWorked  = prefs.getInt('totalSecondsWorked') ?? 0;
      _resolvedMystery     = prefs.getString('resolvedMystery');
      _totalMinutesGlobal  = prefs.getInt('totalMinutesGlobal') ?? 0;
      _streak              = prefs.getInt('streak') ?? 0;
      _lastWorkDate        = prefs.getString('lastWorkDate') ?? '';
      _earnedAchievements  = Set<String>.from(prefs.getStringList('achievements') ?? []);
      _totalWaterCount     = prefs.getInt('totalWaterCount') ?? 0;
      _watersTodayCount    = prefs.getInt('watersToday_$today') ?? 0;
      _lastWateredDate     = didAutoWater ? today : lastWatered;
      _isWilted            = didAutoWater ? false : daysSinceWater > wiltThreshold;
      _lastLevel           = sunToLevel(_totalSun);
      _todayWeather        = weather;
      _hasBugs             = hasBugs;
      _ingredients         = ingredientMap;
      _craftedPotions      = craftedMap;
      _discoveredPotions   = discoveredPotions;
      _cauldronMix         = cauldronMap;
      _brewStartMs         = prefs.getInt('brewStartMs') ?? 0;
      _brewDurationMs      = prefs.getInt('brewDurationMs') ?? 0;
      _bugShieldUntil      = bugShieldUntil;
      _speedBoostEnd       = speedBoostEnd;
      _hasStreakFreeze     = prefs.getBool('streakFreeze') ?? false;
      _sprinklerDaysLeft   = prefs.getInt('sprinklerDaysLeft') ?? 0;
      _dailyTaskId         = dailyTaskId;
      _dailyTaskDone       = dailyTaskDone;
      _dailyGoalSessions   = prefs.getInt('dailyGoalSessions') ?? 3;
      _sessionsToday       = prefs.getInt('sessionsToday_$today') ?? 0;
      _weeklyMinutes       = {
        for (int i = 0; i < 60; i++) _dateStr(DateTime.now().subtract(Duration(days: i))):
          prefs.getInt('dayMinutes_${_dateStr(DateTime.now().subtract(Duration(days: i)))}') ?? 0,
      };
      _collection          = (prefs.getStringList('collection') ?? [])
          .map((s) => CollectedFlower.decode(s)).toList();
      _minutesThisFlower   = prefs.getInt('minutesThisFlower') ?? 0;
      _pendingBeeSignal    = prefs.getInt('pendingBeeSignal') ?? 0;
      // Backfill: eski kullanıcıların craftedPotions'ından keşif setini doldur
      if (discoveredPotions.isEmpty && craftedMap.isNotEmpty) {
        _discoveredPotions = craftedMap.keys.toSet();
      }
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();
    await prefs.setInt('balance', _balance);
    await prefs.setInt('totalSun_$_flowerKey', _totalSun);
    await prefs.setStringList('purchased_$_flowerKey', _purchased.toList());
    await prefs.setInt('totalSecondsWorked', _totalSecondsWorked);
    await prefs.setInt('totalMinutesGlobal', _totalMinutesGlobal);
    await prefs.setInt('streak', _streak);
    await prefs.setString('lastWorkDate', _lastWorkDate);
    await prefs.setStringList('achievements', _earnedAchievements.toList());
    await prefs.setInt('totalWaterCount', _totalWaterCount);
    await prefs.setString('lastWatered_$_flowerKey', _lastWateredDate);
    await prefs.setInt('watersToday_$today', _watersTodayCount);
    await prefs.setStringList('collection', _collection.map((c) => c.encode()).toList());
    await prefs.setInt('minutesThisFlower', _minutesThisFlower);
    await prefs.setBool('hasBugs_$_flowerKey', _hasBugs);
    await prefs.setStringList('ingredients',
        _ingredients.entries.map((e) => '${e.key}:${e.value}').toList());
    await prefs.setStringList('craftedPotions',
        _craftedPotions.entries.map((e) => '${e.key}:${e.value}').toList());
    await prefs.setStringList('discoveredPotions', _discoveredPotions.toList());
    await prefs.setStringList('cauldronMix',
        _cauldronMix.entries.map((e) => '${e.key}:${e.value}').toList());
    await prefs.setInt('brewStartMs', _brewStartMs);
    await prefs.setInt('brewDurationMs', _brewDurationMs);
    await prefs.setString('bugShieldUntil', _bugShieldUntil);
    await prefs.setInt('speedBoostEndMs',
        _speedBoostEnd?.millisecondsSinceEpoch ?? 0);
    await prefs.setBool('streakFreeze', _hasStreakFreeze);
    await prefs.setInt('sprinklerDaysLeft', _sprinklerDaysLeft);
    await prefs.setInt('pendingBeeSignal', _pendingBeeSignal);
    await prefs.setBool('dailyTask_done_$today', _dailyTaskDone);
    await prefs.setInt('dailyGoalSessions', _dailyGoalSessions);
    await prefs.setInt('sessionsToday_$today', _sessionsToday);
    for (final e in _weeklyMinutes.entries) {
      await prefs.setInt('dayMinutes_${e.key}', e.value);
    }
  }

  void _harvest() {
    if (sunToLevel(_totalSun) < 3) return;
    _doHarvest();
  }

  void _doHarvest() {
    HapticFeedback.mediumImpact();
    final isMystery = widget.flower.name == 'mystery';
    final flowerEmoji = (isMystery && _resolvedMystery != null)
        ? resolvedMysteryEmoji(_resolvedMystery)
        : widget.flower.emoji;
    final defaultName = _flowerName.isNotEmpty ? _flowerName : widget.flower.label;
    final newFlower = CollectedFlower(
      name: widget.flower.name,
      customName: defaultName,
      emoji: flowerEmoji,
      date: _todayStr(),
      minutesWorked: _minutesThisFlower,
    );
    setState(() {
      _collection = [..._collection, newFlower];
      _totalSun = 0;
      _lastLevel = 0;
      _lastWateredDate = '';
      _isWilted = false;
      _minutesThisFlower = 0;
      _tab = 1;
    });
    _persist();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$flowerEmoji bahçene eklendi! 🌟'),
      backgroundColor: const Color(0xFF5AAE61),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _showNextFlowerSheet();
    });
  }

  void _showNextFlowerSheet() {
    int selected = flowers.indexWhere((f) => f.name == widget.flower.name);
    if (selected < 0) selected = 0;
    final nameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final sel = flowers[selected];
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF4FBF4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                top: 20, left: 28, right: 28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFC8E6C9),
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  const Text('sıradaki çiçeğini seç',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                          color: Color(0xFF5AAE61), letterSpacing: 1)),
                  const SizedBox(height: 20),
                  // Önizleme
                  sel.fullAsset != null
                      ? Image.asset(sel.fullAsset!, width: 80, height: 80,
                          fit: BoxFit.contain, filterQuality: FilterQuality.none,
                          errorBuilder: (_, __, ___) => Text(sel.emoji,
                              style: const TextStyle(fontSize: 64)))
                      : Text(sel.emoji, style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 6),
                  Text(sel.label,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: Color(0xFF3A5A3C))),
                  if (sel.latinName.isNotEmpty)
                    Text(sel.latinName,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF8CAF8E),
                            fontStyle: FontStyle.italic)),
                  const SizedBox(height: 16),
                  // Seçim grid
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10, runSpacing: 10,
                    children: List.generate(flowers.length, (i) {
                      final isSel = i == selected;
                      return _ScaleTap(
                        onTap: () => setSheetState(() => selected = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: isSel ? 62 : 52, height: isSel ? 62 : 52,
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFFD4EDDA) : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: isSel ? const Color(0xFF5AAE61) : Colors.transparent,
                                width: 2),
                          ),
                          child: Center(
                            child: flowers[i].fullAsset != null
                                ? Image.asset(flowers[i].fullAsset!,
                                    width: isSel ? 36 : 28, height: isSel ? 36 : 28,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.none,
                                    errorBuilder: (_, __, ___) => Text(flowers[i].emoji,
                                        style: TextStyle(fontSize: isSel ? 30 : 24)))
                                : Text(flowers[i].emoji,
                                    style: TextStyle(fontSize: isSel ? 30 : 24)),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  // İsim alanı
                  TextField(
                    controller: nameCtrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF3A5A3C)),
                    decoration: InputDecoration(
                      hintText: 'çiçeğine bir isim ver 🌱',
                      hintStyle: const TextStyle(color: Color(0xFF8CAF8E), fontSize: 13),
                      filled: true, fillColor: const Color(0xFFE8F5E9),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ScaleTap(
                    onTap: () async {
                      final flower = flowers[selected];
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('selectedFlower', flower.name);
                      await prefs.setString('flowerName', nameCtrl.text.trim());
                      if (flower.name == 'mystery') {
                        final resolved = _realFlowers[Random().nextInt(_realFlowers.length)];
                        await prefs.setString('resolvedMystery', resolved);
                        final earned = Set<String>.from(prefs.getStringList('achievements') ?? []);
                        earned.add('mystery_grower');
                        await prefs.setStringList('achievements', earned.toList());
                      } else {
                        await prefs.remove('resolvedMystery');
                      }
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      if (!mounted) return;
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => MainScreen(flower: flower)));
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5AAE61),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text('hadi büyütelim 🌱',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _earnSun(int amount) {
    final isCactus = widget.flower.name == 'cactus';
    final isLotus  = widget.flower.name == 'lotus';
    double mult = 1.0;
    if (_todayWeather == 'sunny') mult = 1.5;
    if (_todayWeather == 'rainy') mult = isCactus ? 0.5 : isLotus ? 1.5 : 0.75;
    final effective = (amount * mult).round();
    final oldLevel = sunToLevel(_totalSun);
    setState(() {
      _balance += effective;
      _totalSun += effective;
    });
    final newLevel = sunToLevel(_totalSun);
    if (newLevel > oldLevel) {
      _onLevelUp(newLevel);
    }
    _persist();
  }

  void _onLevelUp(int newLevel) {
    _checkAchievements();
    if (newLevel >= 3) {
      setState(() => _showCelebration = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showCelebration = false);
      });
    }
  }

  void _onTimerTick() {
    final prevMinutes = _totalSecondsWorked ~/ 60;
    _totalSecondsWorked++;
    final newMinutes = _totalSecondsWorked ~/ 60;
    if (newMinutes > prevMinutes) {
      _totalMinutesGlobal++;
      _minutesThisFlower++;
      final today = _todayStr();
      _weeklyMinutes[today] = (_weeklyMinutes[today] ?? 0) + 1;
      _updateStreak();
      final baseSun = widget.flower.name == 'cactus' ? 2 : 1;
      final speedMult = (_speedBoostEnd != null &&
          DateTime.now().isBefore(_speedBoostEnd!)) ? 3 : 1;
      // Böcek varsa yarı hız
      final earnedSun = _hasBugs ? (newMinutes.isEven ? baseSun : 0) : baseSun * speedMult;
      if (earnedSun > 0) _earnSun(earnedSun);
      _checkDailyTask();
      _checkAchievements();
    }
    if (_totalSecondsWorked % (30 * 60) == 0) {
      _earnSun(5);
      _showBonusSnack();
    }
  }

  void _updateStreak() {
    final today = _todayStr();
    if (_lastWorkDate == today) return;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2,'0')}-${yesterday.day.toString().padLeft(2,'0')}';
    final continuing = _lastWorkDate == yStr;
    if (!continuing && _hasStreakFreeze && _streak > 0) {
      // Dondurucu devreye giriyor
      setState(() { _hasStreakFreeze = false; _lastWorkDate = today; });
      _persist();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('❄️ Dondurucu kullanıldı! Streak korundu: $_streak gün 🔥'),
        backgroundColor: const Color(0xFF42A5F5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ));
    } else {
      setState(() {
        _streak = continuing ? _streak + 1 : 1;
        _lastWorkDate = today;
      });
      _checkStreakMilestone();
    }
  }

  void _checkStreakMilestone() {
    const milestones = {7: 50, 30: 150, 100: 500};
    if (!milestones.containsKey(_streak)) return;
    final reward = milestones[_streak]!;
    setState(() => _balance += reward);
    _persist();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🏆 $_streak günlük seri! +$reward ☀️ ödül kazandın!'),
      backgroundColor: const Color(0xFFFF8F00),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 4),
    ));
  }

  void _showBonusSnack() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('30 dakika bonusu! +5 ☀️'),
      backgroundColor: const Color(0xFF5AAE61),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _purchase(MarketItem item) {
    if (_balance < item.price) return;
    if (item.id == 'streak_freeze' && _hasStreakFreeze) return; // zaten var
    HapticFeedback.lightImpact();
    setState(() {
      _balance -= item.price;
      _totalSun += item.growthBonus;
      if (!item.isTreat) _purchased.add(item.id);
      if (item.id == 'water') {
        _isWilted = false;
        _lastWateredDate = _todayStr();
        _totalWaterCount++;
        _watersTodayCount++;
      }
      if (item.id == 'pesticide') {
        _hasBugs = false;
      }
      if (item.id == 'revival') {
        _isWilted = false;
        _lastWateredDate = _todayStr();
      }
      if (item.id == 'streak_freeze') {
        _hasStreakFreeze = true;
      }
      if (item.id == 'sprinkler') {
        _sprinklerDaysLeft += 3;
        _isWilted = false;
        _lastWateredDate = _todayStr();
      }
    });
    final newLevel = sunToLevel(_totalSun);
    if (newLevel > _lastLevel) {
      _lastLevel = newLevel;
      _onLevelUp(newLevel);
    }
    _checkAchievements();
    _persist();
  }

  bool get _needsWater => _isWilted || _lastWateredDate.isEmpty;

  void _onWater() {
    setState(() {
      _isWilted = false;
      _lastWateredDate = _todayStr();
      _totalWaterCount++;
      _watersTodayCount++;
    });
    _checkDailyTask();
    _persist();
  }

  void _checkDailyTask() {
    if (_dailyTaskDone) return;
    final task = taskPool.firstWhere((t) => t.id == _dailyTaskId, orElse: () => taskPool[0]);
    final today = _todayStr();
    final progress = switch (task.type) {
      'sessions' => _sessionsToday,
      'minutes'  => _weeklyMinutes[today] ?? 0,
      'water'    => _watersTodayCount,
      _          => 0,
    };
    if (progress >= task.target) {
      setState(() {
        _dailyTaskDone = true;
        _balance += task.reward;
      });
      _persist();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🎯 Günlük görev tamamlandı! +${task.reward} ☀️'),
        backgroundColor: const Color(0xFF5AAE61),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  void _onSessionComplete(int sessionMinutes) {
    setState(() => _sessionsToday++);
    _checkDailyTask();
    // %50 ihtimalle kelebek ödülü
    if (Random().nextDouble() < 0.50) {
      setState(() {
        _ingredients = {..._ingredients, 'butterfly': (_ingredients['butterfly'] ?? 0) + 1};
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('🦋 Çiçeğin bir kelebek çekti! Simya tabında kullanabilirsin'),
        backgroundColor: const Color(0xFF7B5EA7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ));
    }
    // Seans tamamlanınca 1-3 arı bahçeye iner
    final beeCount = Random().nextInt(3) + 1;
    setState(() => _pendingBeeSignal += beeCount);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('🐝 Bahçeni kontrol et, arılar seni bekliyor!'),
      backgroundColor: const Color(0xFFFFB300),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
    // Simya kazanını hızlandır — her 3 odaklanma dk → 1 dk eksilme
    if (_brewStartMs > 0) {
      final endMs = _brewStartMs + _brewDurationMs;
      final remaining = endMs - DateTime.now().millisecondsSinceEpoch;
      if (remaining > 0) {
        final reduction = (sessionMinutes ~/ 3) * 60 * 1000;
        setState(() => _brewDurationMs = max(0, _brewDurationMs - reduction));
      }
    }
    _persist();
    if (_sessionsToday >= _dailyGoalSessions) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🎯 Günlük hedef tamamlandı! $_sessionsToday/$_dailyGoalSessions seans 🌟'),
        backgroundColor: const Color(0xFFFF8F00),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  void _openMarket() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55, minChildSize: 0.4, maxChildSize: 0.85, expand: false,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4FBF4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: sc,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFC8E6C9),
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Center(child: Text('market',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: Color(0xFF5AAE61), letterSpacing: 2))),
              if (_watersTodayCount > 0)
                Center(child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('bugün $_watersTodayCount x 💧 suladın',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8CAF8E))),
                )),
              const SizedBox(height: 16),
              ...marketItems.map((item) {
                final owned = _purchased.contains(item.id) ||
                    (item.id == 'streak_freeze' && _hasStreakFreeze) ||
                    (item.id == 'sprinkler' && _sprinklerDaysLeft > 0);
                final ownedLabel = item.id == 'sprinkler' && _sprinklerDaysLeft > 0
                    ? '$_sprinklerDaysLeft gün' : null;
                return _MarketCard(
                  item: item, owned: owned, ownedLabel: ownedLabel,
                  canAfford: _balance >= item.price,
                  onBuy: () {
                    if (_balance < item.price) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Yeterli güneş yok! (${item.price} ☀️ gerekli)'),
                        backgroundColor: const Color(0xFF5AAE61),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ));
                      return;
                    }
                    _purchase(item);
                    Navigator.of(ctx).pop();
                    _openMarket();
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _openSettings(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
        builder: (__, sc) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4FBF4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: sc,
            children: [
              // Ansiklopedi butonu
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                child: _ScaleTap(
                  onTap: () => _openEncyclopedia(ctx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: Row(children: [
                      const Text('📚', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Botanik Ansiklopedisi',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                                color: Color(0xFF2E6B45))),
                        Text('${_collection.map((c) => c.name).toSet().length}/${_realFlowers.length} tür keşfedildi',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF8CAF8E))),
                      ]),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFFA5D6A7)),
                    ]),
                  ),
                ),
              ),
              const Divider(indent: 24, endIndent: 24, height: 28, color: Color(0xFFD4EDDA)),
              StatsTab(
                scrollController: null,
                totalMinutes: _totalMinutesGlobal,
                totalSunEver: _totalSun,
                streak: _streak,
                earnedAchievements: _earnedAchievements,
                totalWaterCount: _totalWaterCount,
                dailyGoalSessions: _dailyGoalSessions,
                sessionsToday: _sessionsToday,
                weeklyMinutes: _weeklyMinutes,
                onGoalChange: (delta) {
                  setState(() {
                    _dailyGoalSessions = (_dailyGoalSessions + delta).clamp(1, 10);
                  });
                  _persist();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _openEncyclopedia(BuildContext ctx) {
    final unlocked = _collection.map((c) => c.name).toSet()
      ..add(widget.flower.name); // şu anki çiçek de açık
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
        builder: (__, sc) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4FBF4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: sc,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFC8E6C9),
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Botanik Ansiklopedisi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: Color(0xFF2E6B45), letterSpacing: 1)),
              const SizedBox(height: 4),
              const Text('yetiştirdiğin çiçeklerin detaylarını keşfet',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8CAF8E))),
              const SizedBox(height: 20),
              ...flowers.where((f) => f.name != 'mystery').map((f) =>
                  _EncyclopediaEntry(flower: f, locked: !unlocked.contains(f.name))),
              _EncyclopediaEntry(
                flower: flowers.firstWhere((f) => f.name == 'mystery'),
                locked: !unlocked.contains('mystery'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _makeIngredient(int gardenIndex) {
    if (gardenIndex >= _collection.length) return;
    HapticFeedback.lightImpact();
    final flower = _collection[gardenIndex];
    setState(() {
      _collection = [
        for (int j = 0; j < _collection.length; j++)
          if (j != gardenIndex) _collection[j],
      ];
      _ingredients = {
        ..._ingredients,
        flower.name: (_ingredients[flower.name] ?? 0) + 1,
      };
    });
    _persist();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🧪 ${flower.customName} hammadde olarak eklendi'),
      backgroundColor: const Color(0xFF7B5EA7),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _addToCauldron(String key) {
    if ((_ingredients[key] ?? 0) <= 0) return;
    HapticFeedback.lightImpact();
    setState(() {
      _ingredients = {..._ingredients, key: _ingredients[key]! - 1};
      _cauldronMix = {..._cauldronMix, key: (_cauldronMix[key] ?? 0) + 1};
    });
    _persist();
  }

  void _removeFromCauldron(String key) {
    if ((_cauldronMix[key] ?? 0) <= 0) return;
    HapticFeedback.lightImpact();
    setState(() {
      _cauldronMix = {..._cauldronMix, key: _cauldronMix[key]! - 1}
        ..removeWhere((_, v) => v == 0);
      _ingredients = {..._ingredients, key: (_ingredients[key] ?? 0) + 1};
    });
    _persist();
  }

  void _startBrew() {
    if (_cauldronMix.isEmpty) return;
    HapticFeedback.mediumImpact();
    final total = _cauldronMix.values.fold(0, (a, b) => a + b);
    setState(() {
      _brewStartMs = DateTime.now().millisecondsSinceEpoch;
      _brewDurationMs = total * 5 * 60 * 1000; // 5 dk per ingredient
    });
    _persist();
  }

  bool _mapsEqual(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) { if (b[e.key] != e.value) return false; }
    return true;
  }

  void _collectPotion() {
    CraftingPotion? matched;
    for (final recipe in potionRecipes) {
      final mixNoZero = Map.fromEntries(_cauldronMix.entries.where((e) => e.value > 0));
      if (_mapsEqual(recipe.recipe, mixNoZero)) { matched = recipe; break; }
    }
    setState(() {
      if (matched != null) {
        _craftedPotions = {..._craftedPotions, matched!.id: (_craftedPotions[matched.id] ?? 0) + 1};
        _discoveredPotions = {..._discoveredPotions, matched.id};
      }
      _cauldronMix = {};
      _brewStartMs = 0;
      _brewDurationMs = 0;
    });
    _persist();
    HapticFeedback.mediumImpact();
    final msg = matched != null
        ? '${matched.emoji} ${matched.name} ortaya çıktı!'
        : '💨 Gizemli bir karışım... hiçbir şey olmadı.';
    final color = matched != null ? const Color(0xFF7B5EA7) : const Color(0xFF9E9E9E);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  void _usePotion(CraftingPotion potion) {
    if ((_craftedPotions[potion.id] ?? 0) <= 0) return;
    HapticFeedback.mediumImpact();
    final today = _todayStr();
    setState(() {
      _craftedPotions = {
        ..._craftedPotions,
        potion.id: _craftedPotions[potion.id]! - 1,
      };
      switch (potion.effectType) {
        case 'weather_sunny':
          _todayWeather = 'sunny';
        case 'weather_rainy':
          _todayWeather = 'rainy';
          _isWilted = false;
          _lastWateredDate = today;
          _totalWaterCount++;
          _watersTodayCount++;
        case 'bug_shield':
          _hasBugs = false;
          _bugShieldUntil = DateTime.now()
              .add(Duration(days: potion.effectValue)).toIso8601String();
        case 'speed_boost':
          _speedBoostEnd = DateTime.now()
              .add(Duration(minutes: potion.effectValue));
        case 'sun_bonus':
          _balance += potion.effectValue;
          _totalSun += potion.effectValue;
        case 'full_restore':
          _isWilted = false;
          _lastWateredDate = today;
          _hasBugs = false;
          _balance += potion.effectValue;
          _totalSun += potion.effectValue;
        case 'water_and_sunny':
          _isWilted = false;
          _lastWateredDate = today;
          _totalWaterCount++;
          _watersTodayCount++;
          _todayWeather = 'sunny';
      }
    });
    if (potion.effectType == 'weather_sunny' || potion.effectType == 'weather_rainy'
        || potion.effectType == 'water_and_sunny') {
      SharedPreferences.getInstance().then(
          (p) => p.setString('weather_$today', _todayWeather));
    }
    _checkAchievements();
    _persist();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${potion.emoji} ${potion.name} kullanıldı!'),
      backgroundColor: const Color(0xFF5AAE61),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _checkAchievements() {
    final prev = Set<String>.from(_earnedAchievements);
    final level = sunToLevel(_totalSun);
    final collectionCount = _collection.length;

    // Çiçek büyümesi
    if (level >= 1) _earnedAchievements.add('first_sprout');
    if (level >= 3) _earnedAchievements.add('full_bloom');

    // Koleksiyon
    if (collectionCount >= 1)  _earnedAchievements.add('full_bloom');
    if (collectionCount >= 5)  _earnedAchievements.add('gardener');
    if (collectionCount >= 20) _earnedAchievements.add('master_gardener');

    // Odaklanma
    if (_totalMinutesGlobal >= 60)   _earnedAchievements.add('focused_1');
    if (_totalMinutesGlobal >= 600)  _earnedAchievements.add('focused_2');
    if (_totalMinutesGlobal >= 6000) _earnedAchievements.add('focused_3');

    // Sulama
    if (_totalWaterCount >= 1)   _earnedAchievements.add('water_1');
    if (_totalWaterCount >= 10)  _earnedAchievements.add('water_2');
    if (_totalWaterCount >= 100) _earnedAchievements.add('water_3');

    // Seri
    if (_streak >= 3)  _earnedAchievements.add('streak_3');
    if (_streak >= 7)  _earnedAchievements.add('streak_7');
    if (_streak >= 30) _earnedAchievements.add('streak_30');

    final newOnes = _earnedAchievements.difference(prev);
    for (final id in newOnes) {
      final a = achievements.firstWhere((a) => a.id == id, orElse: () => achievements[0]);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${a.emoji} Başarım kazandın: ${a.title}!'),
        backgroundColor: const Color(0xFFFF8F00),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF4FBF4),
          body: IndexedStack(
            index: _tab,
            children: [
              FocusTab(
                flower: widget.flower,
                flowerName: _flowerName,
                balance: _balance,
                totalSun: _totalSun,
                isWilted: _isWilted,
                needsWater: _needsWater,
                resolvedMystery: _resolvedMystery,
                purchased: _purchased,
                watersTodayCount: _watersTodayCount,
                onTick: _onTimerTick,
                onCheat: () => _earnSun(100),
                onSessionComplete: _onSessionComplete,
                onWater: _onWater,
                onPurchase: _purchase,
                onHarvest: _harvest,
                todayWeather: _todayWeather,
                hasBugs: _hasBugs,
                hasStreakFreeze: _hasStreakFreeze,
                sprinklerDaysLeft: _sprinklerDaysLeft,
                speedBoostActive: _speedBoostEnd != null &&
                    DateTime.now().isBefore(_speedBoostEnd!),
                onOpenSettings: () => _openSettings(context),
                onOpenMarket: _openMarket,
                dailyTask: taskPool.firstWhere((t) => t.id == _dailyTaskId, orElse: () => taskPool[0]),
                dailyTaskDone: _dailyTaskDone,
                dailyTaskProgress: () {
                  final task = taskPool.firstWhere((t) => t.id == _dailyTaskId, orElse: () => taskPool[0]);
                  final today = _todayStr();
                  return switch (task.type) {
                    'sessions' => _sessionsToday,
                    'minutes'  => _weeklyMinutes[today] ?? 0,
                    'water'    => _watersTodayCount,
                    _          => 0,
                  };
                }(),
              ),
              GardenTab(
                collection: _collection,
                pendingBeeSignal: _pendingBeeSignal,
                calendarMinutes: _weeklyMinutes,
                onMakeIngredient: _makeIngredient,
                onOpenMarket: _openMarket,
                onCollectBee: () {
                  _earnSun(20);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('🐝 Arı ziyareti! +20 ☀️ çiçeğine aktarıldı'),
                    backgroundColor: const Color(0xFFFFB300),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 2),
                  ));
                },
                onRename: (i, name) {
                  setState(() {
                    _collection = [
                      for (int j = 0; j < _collection.length; j++)
                        j == i ? _collection[j].withName(name) : _collection[j],
                    ];
                  });
                  _persist();
                },
              ),
              SimyaTab(
                ingredients: _ingredients,
                craftedPotions: _craftedPotions,
                discoveredPotions: _discoveredPotions,
                cauldronMix: _cauldronMix,
                brewStartMs: _brewStartMs,
                brewDurationMs: _brewDurationMs,
                onAddToCauldron: _addToCauldron,
                onRemoveFromCauldron: _removeFromCauldron,
                onStartBrew: _startBrew,
                onCollectPotion: _collectPotion,
                onUsePotion: _usePotion,
                onGoToFocus: () => setState(() => _tab = 0),
              ),
            ],
          ),
          bottomNavigationBar: _BottomNav(
            current: _tab,
            onTap: (i) => setState(() => _tab = i),
          ),
        ),
        if (_todayWeather == 'rainy')
          const Positioned.fill(child: IgnorePointer(child: _RainOverlay())),
        if (_showCelebration)
          Positioned.fill(child: _CelebrationOverlay(flower: widget.flower)),
      ],
    );
  }
}

// ── Bottom Nav ─────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              _NavItem(icon: Icons.timer_rounded,         label: 'Odaklanma', selected: current == 0, onTap: () => onTap(0)),
              _NavItem(icon: Icons.local_florist_rounded, label: 'Bahçem',    selected: current == 1, onTap: () => onTap(1)),
              _NavItem(icon: Icons.science_rounded,       label: 'Simya',     selected: current == 2, onTap: () => onTap(2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF5AAE61) : const Color(0xFFBBBBBB);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF5AAE61).withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(fontSize: 10, color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Focus Tab ─────────────────────────────────────────────────────────────────

class FocusTab extends StatefulWidget {
  final Flower flower;
  final String flowerName;
  final int balance;
  final int totalSun;
  final bool isWilted;
  final bool needsWater;
  final String? resolvedMystery;
  final Set<String> purchased;
  final int watersTodayCount;
  final VoidCallback onTick;
  final VoidCallback onCheat;
  final void Function(int minutes)? onSessionComplete;
  final VoidCallback onWater;
  final void Function(MarketItem) onPurchase;
  final VoidCallback onHarvest;
  final String todayWeather;
  final bool hasBugs;
  final DailyTask dailyTask;
  final bool dailyTaskDone;
  final int dailyTaskProgress;
  final bool hasStreakFreeze;
  final int sprinklerDaysLeft;
  final bool speedBoostActive;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenMarket;
  const FocusTab({super.key, required this.flower, required this.flowerName,
      required this.balance, required this.totalSun, required this.isWilted,
      required this.needsWater, this.resolvedMystery, required this.purchased,
      required this.watersTodayCount, required this.onTick, required this.onCheat,
      this.onSessionComplete, required this.onWater,
      required this.onPurchase, required this.onHarvest,
      required this.todayWeather, required this.hasBugs,
      required this.dailyTask, required this.dailyTaskDone,
      required this.dailyTaskProgress, required this.hasStreakFreeze,
      required this.sprinklerDaysLeft,
      required this.speedBoostActive, required this.onOpenSettings,
      required this.onOpenMarket});

  @override
  State<FocusTab> createState() => _FocusTabState();
}

class _FocusTabState extends State<FocusTab> with SingleTickerProviderStateMixin {
  int _durationMinutes = 25;
  late int _secondsLeft;
  bool _running = false;
  bool _completed = false;
  bool _isBreak = false;
  bool _showDrops = false;
  int _pomodoroCount = 0;
  Timer? _timer;
  late AnimationController _breathCtrl;
  late Animation<double> _breath;

  @override
  void initState() {
    super.initState();
    _secondsLeft = _durationMinutes * 60;
    _breathCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _breath = Tween<double>(begin: 0, end: -7).animate(
        CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut));
    _breathCtrl.repeat(reverse: true);
  }

  @override
  void dispose() { _timer?.cancel(); _breathCtrl.dispose(); super.dispose(); }

  int get _totalSeconds => _durationMinutes * 60;
  double get _progress => 1 - (_secondsLeft / _totalSeconds);

  void _startBreathing({bool slow = false}) {
    _breathCtrl.duration = Duration(milliseconds: slow ? 3800 : 2200);
    _breathCtrl.repeat(reverse: true);
  }

  void _changeDuration(int delta) {
    if (_running || _completed) return;
    final next = (_durationMinutes + delta).clamp(5, 90);
    setState(() { _durationMinutes = next; _secondsLeft = next * 60; });
  }

  bool get _suggestLongBreak => _pomodoroCount > 0 && _pomodoroCount % 4 == 0;

  void _start() {
    setState(() { _running = true; _completed = false; });
    _startBreathing(slow: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        setState(() {
          _running = false;
          _completed = true;
          if (!_isBreak) _pomodoroCount++;
        });
        _startBreathing();
        if (!_isBreak) widget.onSessionComplete?.call(_durationMinutes);
        return;
      }
      if (!_isBreak) widget.onTick();
      setState(() => _secondsLeft--);
    });
  }

  void _startBreak(int minutes) {
    setState(() {
      _isBreak = true;
      _durationMinutes = minutes;
      _secondsLeft = minutes * 60;
      _completed = false;
    });
    _start();
  }

  void _pause() { _timer?.cancel(); setState(() => _running = false); _startBreathing(); }

  void _waterAndStart() {
    HapticFeedback.lightImpact();
    widget.onWater();
    setState(() => _showDrops = true);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showDrops = false);
    });
    _start();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _completed = false;
      _isBreak = false;
      _durationMinutes = 25;
      _secondsLeft = _totalSeconds;
    });
    _startBreathing();
  }

  String get _timeLabel {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final level = sunToLevel(widget.totalSun);
    final isMystery = widget.flower.name == 'mystery';
    final flowerEmoji = widget.isWilted ? '🥀'
        : (isMystery && level >= 3) ? resolvedMysteryEmoji(widget.resolvedMystery)
        : widget.flower.stage(level);
    final flowerSize = widget.isWilted ? 80.0 : 80.0 + level * 18.0;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const FlowerSelectScreen())),
                  child: const Icon(Icons.local_florist_rounded,
                      color: Color(0xFFAACAA9), size: 22),
                ),
                Expanded(child: Column(
                  children: [
                    const Text('flororo',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                            color: Color(0xFF5AAE61), letterSpacing: 1.5)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(seasonEmoji(currentSeason()),
                            style: const TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                        Text(
                          widget.todayWeather == 'rainy' ? '🌧️ yağmurlu'
                              : widget.todayWeather == 'cloudy' ? '⛅ bulutlu'
                              : '☀️ güneşli',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF8CAF8E)),
                        ),
                      ],
                    ),
                    if (widget.speedBoostActive)
                      const Text('⚡ 3× hız aktif',
                          style: TextStyle(fontSize: 10, color: Color(0xFFAB47BC),
                              fontWeight: FontWeight.w700)),
                  ],
                )),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SunBadge(balance: widget.balance, onLongPress: widget.onCheat),
                    const SizedBox(width: 8),
                    _ScaleTap(
                      onTap: widget.onOpenMarket,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF5AAE61),
                            borderRadius: BorderRadius.circular(20)),
                        child: const Text('🛍️', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ScaleTap(
                      onTap: widget.onOpenSettings,
                      child: const Icon(Icons.settings_rounded,
                          color: Color(0xFFAACAA9), size: 22),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  SizedBox(
                    width: 134, height: 134,
                    child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedBuilder(
                        animation: _breath,
                        builder: (_, __) {
                          final asset = widget.isWilted ? null : widget.flower.assetForLevel(level);
                          return Transform.translate(
                            offset: Offset(0, _breath.value),
                            child: asset != null
                                ? Image.asset(asset,
                                    width: flowerSize, height: flowerSize, fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 600),
                                      style: TextStyle(fontSize: flowerSize),
                                      child: Text(flowerEmoji),
                                    ))
                                : AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 600),
                                    style: TextStyle(fontSize: flowerSize),
                                    child: Text(flowerEmoji),
                                  ),
                          );
                        },
                      ),
                      if (widget.hasBugs)
                        const Positioned(top: -4, left: -12,
                            child: Text('🐛', style: TextStyle(fontSize: 22))),
                      if (_showDrops)
                        const Positioned.fill(child: _WaterBurst()),
                    ],
                  ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    widget.flowerName.isNotEmpty ? widget.flowerName : widget.flower.label,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: Color(0xFF7AAF7C)),
                  ),

                  if (level >= 3 && !widget.isWilted) ...[
                    const SizedBox(height: 10),
                    _ScaleTap(
                      onTap: widget.onHarvest,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFCC80)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🌺', style: TextStyle(fontSize: 16)),
                            SizedBox(width: 6),
                            Text('bahçeye ekle',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                    color: Color(0xFFE65100))),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (widget.flower.name == 'cactus') ...[
                    const SizedBox(height: 6),
                    Text('🌵 +2 ☀️/dk  •  5 günde bir su yeter',
                        style: TextStyle(fontSize: 10, color: Colors.green.shade400)),
                  ],
                  if (widget.hasBugs) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFCC80)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🐛', style: TextStyle(fontSize: 13)),
                          SizedBox(width: 6),
                          Text('böcek var! büyüme yavaşladı — marketten ilaç al',
                              style: TextStyle(fontSize: 11,
                                  color: Color(0xFFE65100), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _GrowthBar(totalSun: widget.totalSun, level: level),
                  const SizedBox(height: 12),
                  _DailyTaskCard(
                    task: widget.dailyTask,
                    done: widget.dailyTaskDone,
                    progress: widget.dailyTaskProgress,
                  ),
                  const SizedBox(height: 12),

                  if (!_running && !_completed)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _DurationBtn(icon: Icons.remove, onTap: () => _changeDuration(-5)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('$_durationMinutes dk',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                  color: Color(0xFF3A5A3C))),
                        ),
                        _DurationBtn(icon: Icons.add, onTap: () => _changeDuration(5)),
                      ],
                    ),
                  if (!_running && !_completed) const SizedBox(height: 12),

                  Text(_timeLabel,
                      style: TextStyle(
                        fontSize: 76, fontWeight: FontWeight.w300, letterSpacing: 4,
                        color: _isBreak
                            ? const Color(0xFF42A5F5)
                            : _completed ? const Color(0xFF5AAE61) : const Color(0xFF3A5A3C),
                      )),
                  const SizedBox(height: 6),
                  Text(
                    _isBreak && _completed ? 'mola bitti! hazır mısın? 💪'
                        : _isBreak && _running ? 'mola zamanı ☕ • dinlen biraz'
                        : _completed ? 'harika! çiçeğin büyüdü 🌸'
                        : _running ? '1 dk = 1 ☀️  •  30 dk = +5 ☀️ bonus'
                        : widget.needsWater ? 'çiçeğine can suyu ver 💧'
                        : 'süreyi ayarla ve başlat',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8CAF8E)),
                  ),

                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: _progress, minHeight: 4,
                      backgroundColor: const Color(0xFFD4EDDA),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          _isBreak ? const Color(0xFF42A5F5) : const Color(0xFF5AAE61)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Mola devam ederken → erken bitir
                  if (_isBreak && _running) ...[
                    _ScaleTap(
                      onTap: () { _timer?.cancel(); setState(() { _running = false; _completed = true; }); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF42A5F5)),
                        ),
                        child: const Text('molayı erken bitir ⏭',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                color: Color(0xFF42A5F5))),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Çalışma tamamlandı → mola seçenekleri
                  if (_completed && !_isBreak) ...[
                    if (_suggestLongBreak)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text('4. pomodoro! uzun mola hak ettin 🎉',
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade400,
                                fontWeight: FontWeight.w600)),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ScaleTap(
                          onTap: () => _startBreak(_suggestLongBreak ? 15 : 5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF42A5F5),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(_suggestLongBreak ? 'uzun mola 15 dk 🌿' : 'kısa mola 5 dk ☕',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ScaleTap(
                          onTap: _reset,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(24)),
                            child: const Text('atla →',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                    color: Color(0xFF5AAE61))),
                          ),
                        ),
                      ],
                    ),
                  ]

                  // Mola tamamlandı → çalışmaya dön
                  else if (_completed && _isBreak)
                    _ScaleTap(
                      onTap: _reset,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(color: const Color(0xFF5AAE61),
                            borderRadius: BorderRadius.circular(24)),
                        child: const Text('çalışmaya başla 🌱',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    )

                  // Can suyu ver butonu
                  else if (widget.needsWater && !_running)
                    _ScaleTap(
                      onTap: _waterAndStart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF42A5F5),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [BoxShadow(color: const Color(0xFF42A5F5).withValues(alpha: 0.35),
                              blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('💧', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 8),
                            Text('can suyu ver',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    )

                  // Normal çalışma butonları
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ScaleTap(
                          onTap: _running ? _pause : _start,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 120, height: 48,
                            decoration: BoxDecoration(
                              color: _running ? const Color(0xFFD4EDDA) : const Color(0xFF5AAE61),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            alignment: Alignment.center,
                            child: Text(_running ? 'duraklat' : 'başlat',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                                    color: _running ? const Color(0xFF5AAE61) : Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _ScaleTap(
                          onTap: _reset,
                          child: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(24)),
                            alignment: Alignment.center,
                            child: const Icon(Icons.refresh_rounded,
                                color: Color(0xFFAACAA9), size: 22),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Growth Bar ────────────────────────────────────────────────────────────────

class _GrowthBar extends StatelessWidget {
  final int totalSun;
  final int level;
  const _GrowthBar({required this.totalSun, required this.level});

  @override
  Widget build(BuildContext context) {
    if (level >= 3) {
      return const Text('🌟 Tam çiçek! 🌟',
          style: TextStyle(fontSize: 12, color: Color(0xFF5AAE61), fontWeight: FontWeight.w700));
    }
    final threshold = nextLevelThreshold(totalSun);
    final prevThreshold = [0, 50, 150, 300][level.clamp(0, 3)];
    final linearProgress = ((totalSun - prevThreshold) / (threshold - prevThreshold)).clamp(0.0, 1.0);
    final progress = sigmoidProgress(linearProgress);
    const labels = ['Filiz', 'Tomurcuk', 'Tam Çiçek'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('büyüme', style: TextStyle(fontSize: 10, color: Colors.green.shade400)),
            Text('${labels[level.clamp(0,2)]} için $totalSun/$threshold ☀️',
                style: TextStyle(fontSize: 10, color: Colors.green.shade400)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: progress, minHeight: 6,
            backgroundColor: const Color(0xFFD4EDDA),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF81C784)),
          ),
        ),
      ],
    );
  }
}

// ── Simya Tab ─────────────────────────────────────────────────────────────────

class SimyaTab extends StatefulWidget {
  final Map<String, int> ingredients;
  final Map<String, int> craftedPotions;
  final Set<String> discoveredPotions;
  final Map<String, int> cauldronMix;
  final int brewStartMs;
  final int brewDurationMs;
  final void Function(String) onAddToCauldron;
  final void Function(String) onRemoveFromCauldron;
  final VoidCallback onStartBrew;
  final VoidCallback onCollectPotion;
  final void Function(CraftingPotion) onUsePotion;
  final VoidCallback onGoToFocus;
  const SimyaTab({super.key, required this.ingredients,
      required this.craftedPotions, required this.discoveredPotions,
      required this.cauldronMix,
      required this.brewStartMs, required this.brewDurationMs,
      required this.onAddToCauldron, required this.onRemoveFromCauldron,
      required this.onStartBrew, required this.onCollectPotion,
      required this.onUsePotion, required this.onGoToFocus});

  @override
  State<SimyaTab> createState() => _SimyaTabState();
}

class _SimyaTabState extends State<SimyaTab> with SingleTickerProviderStateMixin {
  Timer? _brewTimer;
  int _secondsLeft = 0;
  late AnimationController _bubbleCtrl;

  @override
  void initState() {
    super.initState();
    _bubbleCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(SimyaTab old) {
    super.didUpdateWidget(old);
    if (old.brewStartMs != widget.brewStartMs) {
      _brewTimer?.cancel();
      _startTimerIfNeeded();
    }
  }

  void _startTimerIfNeeded() {
    if (widget.brewStartMs > 0) {
      final endMs = widget.brewStartMs + widget.brewDurationMs;
      _tick(endMs);
      if (_secondsLeft > 0) {
        _brewTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          _tick(endMs);
          if (_secondsLeft <= 0) _brewTimer?.cancel();
        });
      }
    }
  }

  void _tick(int endMs) {
    final left = max(0, ((endMs - DateTime.now().millisecondsSinceEpoch) / 1000).ceil());
    if (mounted) setState(() => _secondsLeft = left);
  }

  @override
  void dispose() {
    _brewTimer?.cancel();
    _bubbleCtrl.dispose();
    super.dispose();
  }

  String _fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  String _emoji(String key) => key == 'butterfly' ? '🦋'
      : flowers.firstWhere((f) => f.name == key, orElse: () => flowers.first).emoji;
  String _label(String key) => key == 'butterfly' ? 'Kelebek'
      : flowers.firstWhere((f) => f.name == key, orElse: () => flowers.first).label;

  @override
  Widget build(BuildContext context) {
    final isBrewing = widget.brewStartMs > 0 && _secondsLeft > 0;
    final isReady   = widget.brewStartMs > 0 && _secondsLeft <= 0;
    final mixTotal  = widget.cauldronMix.values.fold(0, (a, b) => a + b);
    final isLoaded  = mixTotal > 0 && !isBrewing && !isReady;
    final hasIngredients = widget.ingredients.values.any((v) => v > 0);
    final hasPotions = widget.craftedPotions.values.any((v) => v > 0);
    final hasDiscovered = widget.discoveredPotions.isNotEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('simya atölyesi',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: Color(0xFF7B5EA7), letterSpacing: 2)),
            const SizedBox(height: 4),
            const Text('kazana malzeme at, ne çıkacağını bekle',
                style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
            const SizedBox(height: 28),

            // ── Kazan ──────────────────────────────────────────────────────
            Center(
              child: AnimatedBuilder(
                animation: _bubbleCtrl,
                builder: (_, __) {
                  final v = _bubbleCtrl.value;
                  final glow = isBrewing || isReady;
                  final glowColor = isReady ? const Color(0xFFAB47BC) : const Color(0xFF5C6BC0);
                  return Container(
                    width: 220,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isReady
                            ? [const Color(0xFF4A148C), const Color(0xFF7B1FA2)]
                            : isBrewing
                                ? [const Color(0xFF1A237E), const Color(0xFF283593)]
                                : [const Color(0xFF37474F), const Color(0xFF546E7A)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(110), bottom: Radius.circular(30)),
                      boxShadow: glow ? [BoxShadow(
                        color: glowColor.withValues(alpha: 0.3 + v * 0.3),
                        blurRadius: 24 + v * 12,
                        spreadRadius: 2,
                      )] : [],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Kaynayan kabarcıklar
                        if (isBrewing) ...[
                          for (int bi = 0; bi < 4; bi++)
                            Positioned(
                              left: 20.0 + bi * 38,
                              bottom: 8 + sin(v * 2 * pi + bi * 1.5) * 10 + bi * 4.0,
                              child: Opacity(
                                opacity: (0.15 + sin(v * pi + bi) * 0.15).clamp(0.0, 0.4),
                                child: Container(
                                  width: 8.0 + bi * 3,
                                  height: 8.0 + bi * 3,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                        ],
                        // İçerik
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isBrewing) const SizedBox(height: 18),
                            Text(
                              isReady ? '✨' : isBrewing ? '🔮' : '🫕',
                              style: TextStyle(
                                  fontSize: 52 + (isBrewing ? v * 6 : 0)),
                            ),
                            const SizedBox(height: 8),
                            if (isBrewing) ...[
                              Text(_fmt(_secondsLeft),
                                  style: const TextStyle(color: Colors.white,
                                      fontSize: 24, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text('kaynıyor${'.' * (1 + (v * 3).floor())}',
                                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
                            ] else if (isReady) ...[
                              const Text('hazır!',
                                  style: TextStyle(color: Colors.white,
                                      fontSize: 18, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              const Text('iksiri almayı unutma',
                                  style: TextStyle(color: Colors.white60, fontSize: 11)),
                            ] else if (mixTotal > 0) ...[
                              Text('$mixTotal malzeme içinde',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              Text('~${(mixTotal * 5)} dk pişecek',
                                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            ] else ...[
                              const Text('boş',
                                  style: TextStyle(color: Colors.white38, fontSize: 13)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Progress bar (sadece pişerken) ─────────────────────────────
            if (isBrewing) ...[
              Builder(builder: (_) {
                final total = widget.brewDurationMs / 1000;
                final progress = total > 0 ? (1 - _secondsLeft / total).clamp(0.0, 1.0) : 0.0;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(children: [
                    Container(height: 10, color: const Color(0xFFE8EAF6)),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 10,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF7986CB), Color(0xFF8E24AA)],
                          ),
                        ),
                      ),
                    ),
                  ]),
                );
              }),
              const SizedBox(height: 12),
              // Hızlandır butonu
              _ScaleTap(
                onTap: widget.onGoToFocus,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7F6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCE93D8)),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('⚡', style: TextStyle(fontSize: 15)),
                    SizedBox(width: 6),
                    Text('Çalışarak hızlandır',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: Color(0xFF7B5EA7))),
                    SizedBox(width: 6),
                    Text('· her 3 dk odaklanma = −1 dk',
                        style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ── Kazandaki malzemeler (tıklayınca geri al) ──────────────────
            if (widget.cauldronMix.isNotEmpty && !isBrewing) ...[
              Row(children: [
                const Text('kazanda', style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700, color: Color(0xFF7B5EA7))),
                if (!isReady) ...[
                  const Spacer(),
                  const Text('dokun → geri al', style: TextStyle(
                      fontSize: 10, color: Color(0xFF9E9E9E))),
                ],
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8,
                children: widget.cauldronMix.entries.where((e) => e.value > 0).map((e) =>
                  _ScaleTap(
                    onTap: isReady ? null : () => widget.onRemoveFromCauldron(e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE7F6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCE93D8)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(_emoji(e.key), style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 4),
                        Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_label(e.key), style: const TextStyle(
                              fontSize: 9, color: Color(0xFF7B5EA7))),
                          Text('×${e.value}', style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800,
                              color: Color(0xFF4A148C))),
                        ]),
                      ]),
                    ),
                  ),
                ).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // ── Aksiyon butonu ─────────────────────────────────────────────
            if (isReady)
              _ScaleTap(
                onTap: widget.onCollectPotion,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF8E24AA), Color(0xFF5E35B1)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFF7B1FA2).withValues(alpha: 0.4),
                        blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('✨', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 10),
                    Text('İksiri Al', style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w800, color: Colors.white)),
                  ]),
                ),
              )
            else if (isBrewing)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(child: Text('⏳ Pişiyor, bekle...',
                    style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w600))),
              )
            else
              _ScaleTap(
                onTap: isLoaded ? widget.onStartBrew : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isLoaded ? const Color(0xFF7B5EA7) : const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(child: Text(
                    isLoaded ? '🔥 Kaynat!' : 'Kazana malzeme ekle...',
                    style: TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isLoaded ? Colors.white : const Color(0xFFBDBDBD)),
                  )),
                ),
              ),
            const SizedBox(height: 28),

            // ── Malzeme envanteri (eklemek için tıkla) ────────────────────
            if (!isBrewing && !isReady) ...[
              const Text('malzemeler',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: Color(0xFF4A148C))),
              const SizedBox(height: 4),
              const Text('dokun → kazana ekle',
                  style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
              const SizedBox(height: 10),
              if (!hasIngredients)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(children: [
                    const Text('🌸', style: TextStyle(fontSize: 28)),
                    const SizedBox(height: 8),
                    const Text('Henüz malzemen yok',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: Color(0xFF7B5EA7))),
                    const SizedBox(height: 4),
                    const Text(
                      'Bahçedeki çiçeklere tıklayıp "Hasat Et" ile malzeme ekle',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                    ),
                  ]),
                )
              else
                Wrap(spacing: 8, runSpacing: 8,
                  children: widget.ingredients.entries.where((e) => e.value > 0).map((e) =>
                    _ScaleTap(
                      onTap: () => widget.onAddToCauldron(e.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFCE93D8)),
                        ),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_emoji(e.key), style: const TextStyle(fontSize: 20)),
                          Text(_label(e.key), style: const TextStyle(
                              fontSize: 9, color: Color(0xFF7B5EA7))),
                          Text('×${e.value}', style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800,
                              color: Color(0xFF4A148C))),
                        ]),
                      ),
                    ),
                  ).toList(),
                ),
              const SizedBox(height: 28),
            ],

            // ── Hazır iksirler ─────────────────────────────────────────────
            if (hasPotions) ...[
              const Text('hazır iksirler',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: Color(0xFF4A148C))),
              const SizedBox(height: 8),
              ...potionRecipes.where((p) => (widget.craftedPotions[p.id] ?? 0) > 0).map((p) =>
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7F6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCE93D8)),
                  ),
                  child: Row(children: [
                    Text(p.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${p.name}  ×${widget.craftedPotions[p.id]}',
                            style: const TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w700, color: Color(0xFF4A148C))),
                        Text(p.description,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                      ],
                    )),
                    _ScaleTap(
                      onTap: () => widget.onUsePotion(p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF7B5EA7),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Text('kullan', style: TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Keşifler defteri ───────────────────────────────────────────
            if (hasDiscovered) ...[
              Row(children: [
                const Text('keşifler defteri',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: Color(0xFF4A148C))),
                const SizedBox(width: 6),
                Text('${widget.discoveredPotions.length}/${potionRecipes.length}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
              ]),
              const SizedBox(height: 8),
              ...potionRecipes.where((p) => widget.discoveredPotions.contains(p.id)).map((p) {
                final inStock = (widget.craftedPotions[p.id] ?? 0) > 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: inStock ? const Color(0xFFF3E5F5) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: inStock ? const Color(0xFFCE93D8) : const Color(0xFFE0E0E0)),
                  ),
                  child: Row(children: [
                    Text(p.emoji,
                        style: TextStyle(fontSize: 24,
                            color: inStock ? null : Colors.black26)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                color: inStock
                                    ? const Color(0xFF4A148C)
                                    : const Color(0xFFBDBDBD))),
                        Text(p.description,
                            style: TextStyle(fontSize: 11,
                                color: inStock
                                    ? const Color(0xFF9E9E9E)
                                    : const Color(0xFFBDBDBD))),
                      ],
                    )),
                    if (inStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE7F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('×${widget.craftedPotions[p.id]}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                                color: Color(0xFF7B5EA7))),
                      )
                    else
                      const Text('kullanıldı',
                          style: TextStyle(fontSize: 11, color: Color(0xFFBDBDBD))),
                  ]),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Garden Tab ────────────────────────────────────────────────────────────────

class GardenTab extends StatefulWidget {
  final List<CollectedFlower> collection;
  final int pendingBeeSignal;
  final void Function(int index, String name) onRename;
  final void Function(int index) onMakeIngredient;
  final VoidCallback onCollectBee;
  final VoidCallback onOpenMarket;
  final Map<String, int> calendarMinutes;
  const GardenTab({super.key, required this.collection,
      required this.pendingBeeSignal,
      required this.onRename, required this.onMakeIngredient,
      required this.onCollectBee, required this.onOpenMarket,
      required this.calendarMinutes});

  @override
  State<GardenTab> createState() => _GardenTabState();
}

class _BeeData {
  final String id;
  final Offset position;
  final DateTime expiresAt;
  _BeeData({required this.id, required this.position, required this.expiresAt});
}

class _GardenTabState extends State<GardenTab> with SingleTickerProviderStateMixin {
  List<Offset> _positions = [];
  Size _gardenSize = Size.zero;
  final List<_BeeData> _bees = [];
  late AnimationController _butterflyCtrl;
  Timer? _expireTimer;
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _loadPositions();
    _butterflyCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 3))..repeat();
    // Süresi dolmuş arıları temizle
    _expireTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final now = DateTime.now();
      if (_bees.any((b) => now.isAfter(b.expiresAt))) {
        setState(() => _bees.removeWhere((b) => now.isAfter(b.expiresAt)));
      }
    });
  }



  void _spawnBee() {
    setState(() {
      _bees.add(_BeeData(
        id: 'bee_${DateTime.now().millisecondsSinceEpoch}',
        position: Offset(0.1 + _rnd.nextDouble() * 0.8, 0.1 + _rnd.nextDouble() * 0.6),
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      ));
    });
  }

  void _collectBee(String id) {
    HapticFeedback.lightImpact();
    setState(() => _bees.removeWhere((b) => b.id == id));
    widget.onCollectBee();
  }

  @override
  void didUpdateWidget(GardenTab old) {
    super.didUpdateWidget(old);
    if (old.collection.length != widget.collection.length) _loadPositions();
    if (widget.pendingBeeSignal > old.pendingBeeSignal) {
      final count = widget.pendingBeeSignal - old.pendingBeeSignal;
      for (int i = 0; i < count; i++) _spawnBee();
    }
  }

  @override
  void dispose() {
    _butterflyCtrl.dispose();
    _expireTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPositions() async {
    final prefs = await SharedPreferences.getInstance();
    final n = widget.collection.length;
    setState(() {
      _positions = List.generate(n, (i) {
        final uid = widget.collection[i].uid;
        return Offset(
          prefs.getDouble('gpos_${uid}_x') ?? _defaultX(i, n),
          prefs.getDouble('gpos_${uid}_y') ?? 0.75,
        );
      });
    });
  }

  double _defaultX(int i, int n) {
    if (n == 1) return 0.5;
    return 0.15 + (i / (n - 1).clamp(1, 99)) * 0.7;
  }

  Future<void> _savePosition(int i) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = widget.collection[i].uid;
    await prefs.setDouble('gpos_${uid}_x', _positions[i].dx);
    await prefs.setDouble('gpos_${uid}_y', _positions[i].dy);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                const Text('bahçem',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                        color: Color(0xFF5AAE61), letterSpacing: 3)),
                const SizedBox(width: 10),
                if (widget.collection.isNotEmpty)
                  Text('${widget.collection.length} çiçek 🌸',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF8CAF8E))),
                const Spacer(),
                _ScaleTap(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => DraggableScrollableSheet(
                      initialChildSize: 0.6, minChildSize: 0.5, maxChildSize: 0.9,
                      expand: false,
                      builder: (_, sc) => Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF4FBF4),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                        ),
                        child: ListView(
                          controller: sc,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                          children: [
                            Center(child: Container(width: 40, height: 4,
                                decoration: BoxDecoration(color: const Color(0xFFC8E6C9),
                                    borderRadius: BorderRadius.circular(2)))),
                            const SizedBox(height: 16),
                            _GardenCalendar(calendarMinutes: widget.calendarMinutes),
                          ],
                        ),
                      ),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text('📅', style: TextStyle(fontSize: 22)),
                  ),
                ),
                _ScaleTap(
                  onTap: widget.onOpenMarket,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5AAE61),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('🛍️ market',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    _gardenSize = constraints.biggest;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Gökyüzü + zemin gradyanı
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFD6EEFF),
                                Color(0xFFB3D9F5),
                                Color(0xFFC8E6C9),
                                Color(0xFF81C784),
                              ],
                              stops: [0.0, 0.45, 0.65, 1.0],
                            ),
                          ),
                        ),
                        Positioned.fill(child: _GardenWallpaper(hasFertilizer: false)),
                        // Zemin şeridi
                        Positioned(
                          bottom: 0, left: 0, right: 0, height: 72,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 70, left: 0, right: 0,
                          child: Container(height: 2,
                              color: Colors.brown.withValues(alpha: 0.2)),
                        ),

                        if (widget.collection.isEmpty)
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🌱', style: TextStyle(fontSize: 56)),
                                const SizedBox(height: 12),
                                const Text('Bahçen henüz boş',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                                        color: Color(0xFF3A5A3C))),
                                const SizedBox(height: 4),
                                Text('Çiçeği büyüt ve buraya ekle 🌺',
                                    style: TextStyle(fontSize: 12, color: Colors.green.shade400)),
                              ],
                            ),
                          ),

                        // Sürüklenebilir çiçekler
                        if (_gardenSize != Size.zero)
                          for (int i = 0; i < widget.collection.length && i < _positions.length; i++)
                            _buildDraggableFlower(i),

                        // Arılar
                        if (_gardenSize != Size.zero)
                          AnimatedBuilder(
                            animation: _butterflyCtrl,
                            builder: (_, __) => Stack(
                              children: [
                                ..._bees.map((b) {
                                  final dx = b.position.dx * _gardenSize.width +
                                      sin(_butterflyCtrl.value * 4 * pi + b.position.dx * 3) * 10;
                                  final dy = b.position.dy * _gardenSize.height +
                                      sin(_butterflyCtrl.value * 3 * pi + b.position.dy * 2) * 7;
                                  final timeLeft = b.expiresAt.difference(DateTime.now()).inSeconds;
                                  final opacity = (timeLeft / 3.0).clamp(0.0, 1.0);
                                  return Positioned(
                                    left: dx - 14, top: dy - 14,
                                    child: GestureDetector(
                                      onTap: () => _collectBee(b.id),
                                      child: Opacity(
                                        opacity: opacity,
                                        child: Container(
                                          width: 28, height: 28,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Text('🐝',
                                              style: TextStyle(fontSize: 18)),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFlowerInfo(int i) {
    final c = widget.collection[i];
    final flowerData = flowers.firstWhere((f) => f.name == c.name,
        orElse: () => flowers.first);
    final nameCtrl = TextEditingController(text: c.customName);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4FBF4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFC8E6C9),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              flowerData.fullAsset != null
                  ? Image.asset(flowerData.fullAsset!, width: 100, height: 100,
                      fit: BoxFit.contain, filterQuality: FilterQuality.none,
                      errorBuilder: (_, __, ___) => Text(c.emoji, style: const TextStyle(fontSize: 72)))
                  : Text(c.emoji, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              // İsim alanı — düzenlenebilir
              TextField(
                controller: nameCtrl,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                    color: Color(0xFF3A5A3C)),
                decoration: InputDecoration(
                  hintText: flowerData.label,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  suffixIcon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFFAACAA9)),
                ),
                maxLength: 20,
                onSubmitted: (v) {
                  final name = v.trim().isNotEmpty ? v.trim() : flowerData.label;
                  widget.onRename(i, name);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 4),
              Text(flowerData.label,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF8CAF8E))),
              const SizedBox(height: 4),
              Text('🌱 ${c.date} tarihinde bahçene katıldı',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFAACAA9))),
              if (c.minutesWorked > 0)
                Text('⏱️ ${c.minutesWorked} dakika çalışarak yetiştirildi',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFAACAA9))),
              if (flowerData.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(flowerData.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF3A5A3C),
                          height: 1.6)),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim().isNotEmpty
                          ? nameCtrl.text.trim() : flowerData.label;
                      widget.onRename(i, name);
                      Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF5AAE61)),
                    child: const Text('kaydet'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      showDialog(
                        context: context,
                        builder: (dctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          title: const Text('Hasat Et?',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          content: Text(
                            '"${c.customName}" bahçenden kaldırılıp iksir malzemesi olacak.',
                            style: const TextStyle(fontSize: 14),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dctx),
                              child: const Text('vazgeç'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(dctx);
                                widget.onMakeIngredient(i);
                              },
                              style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF7B5EA7)),
                              child: const Text('hasat et'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Text('🧪', style: TextStyle(fontSize: 14)),
                    label: const Text('hasat et',
                        style: TextStyle(color: Color(0xFF7B5EA7))),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF7B5EA7))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => nameCtrl.dispose());
  }

  Widget _buildDraggableFlower(int i) {
    final c = widget.collection[i];
    final pos = _positions[i];
    const totalW = 72.0;
    const totalH = 112.0;

    final left = (pos.dx * _gardenSize.width - totalW / 2).clamp(0.0, _gardenSize.width - totalW);
    final top  = (pos.dy * _gardenSize.height - totalH / 2).clamp(0.0, _gardenSize.height - totalH);

    return Positioned(
      left: left, top: top, width: totalW, height: totalH,
      child: GestureDetector(
        onTap: () => _showFlowerInfo(i),
        onPanUpdate: (d) {
          setState(() {
            final cur = _positions[i];
            _positions[i] = Offset(
              (cur.dx + d.delta.dx / _gardenSize.width).clamp(0.05, 0.95),
              (cur.dy + d.delta.dy / _gardenSize.height).clamp(0.05, 0.95),
            );
          });
        },
        onPanEnd: (_) => _savePosition(i),
        child: SizedBox(
          width: totalW,
          height: totalH,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              () {
                final fd = flowers.firstWhere((f) => f.name == c.name, orElse: () => flowers.first);
                return fd.fullAsset != null
                    ? Image.asset(fd.fullAsset!, width: 40, height: 40, fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        errorBuilder: (_, __, ___) => Text(c.emoji, style: const TextStyle(fontSize: 32)))
                    : Text(c.emoji, style: const TextStyle(fontSize: 32));
              }(),
              Text('🪴', style: const TextStyle(fontSize: 34)),
              Text(c.customName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                      color: Color(0xFF3A5A3C))),
            ],
          ),
        ),
      ),
    );
  }
}


// ── Garden Calendar ───────────────────────────────────────────────────────────

class _GardenCalendar extends StatefulWidget {
  final Map<String, int> calendarMinutes;
  const _GardenCalendar({required this.calendarMinutes});

  @override
  State<_GardenCalendar> createState() => _GardenCalendarState();
}

class _GardenCalendarState extends State<_GardenCalendar> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
  }

  String _ds(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  void _prev() => setState(() => _month = DateTime(_month.year, _month.month - 1));
  void _next() {
    final next = DateTime(_month.year, _month.month + 1);
    if (!next.isAfter(DateTime(DateTime.now().year, DateTime.now().month))) {
      setState(() => _month = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = _month.year == now.year && _month.month == now.month;
    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // Pazartesi = 1, Pazar = 7; başlamadan önce kaç boş hücre
    final startOffset = (firstDay.weekday - 1) % 7;

    final monthNames = ['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran',
        'Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];
    final dayLabels = ['Pzt','Sal','Çar','Per','Cum','Cmt','Paz'];

    // Bu ay max dakika (renk skalası için)
    int maxMin = 1;
    for (int d = 1; d <= daysInMonth; d++) {
      final m = widget.calendarMinutes[_ds(DateTime(_month.year, _month.month, d))] ?? 0;
      if (m > maxMin) maxMin = m;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('📅', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            const Text('çalışma takvimi',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: Color(0xFF5AAE61))),
            const Spacer(),
            _ScaleTap(
              onTap: _prev,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF8CAF8E)),
              ),
            ),
            Text('${monthNames[_month.month - 1]} ${_month.year}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: Color(0xFF5AAE61))),
            _ScaleTap(
              onTap: isCurrentMonth ? null : _next,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.chevron_right_rounded, size: 20,
                    color: isCurrentMonth ? const Color(0xFFD4EDDA) : const Color(0xFF8CAF8E)),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          // Gün başlıkları
          Row(children: dayLabels.map((l) => Expanded(
            child: Center(child: Text(l,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: Color(0xFF8CAF8E)))),
          )).toList()),
          const SizedBox(height: 4),
          // Takvim hücreleri
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, mainAxisSpacing: 3, crossAxisSpacing: 3),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (_, idx) {
              if (idx < startOffset) return const SizedBox.shrink();
              final day = idx - startOffset + 1;
              final date = DateTime(_month.year, _month.month, day);
              final mins = widget.calendarMinutes[_ds(date)] ?? 0;
              final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
              final isFuture = date.isAfter(now);
              final intensity = isFuture || mins == 0 ? 0.0 : (mins / maxMin).clamp(0.1, 1.0);
              final bg = isFuture
                  ? const Color(0xFFF5F5F5)
                  : mins == 0
                      ? const Color(0xFFF1F8F1)
                      : Color.lerp(const Color(0xFFC8E6C9), const Color(0xFF2E7D32), intensity)!;
              return Tooltip(
                message: mins > 0 ? '$mins dk' : '',
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(5),
                    border: isToday ? Border.all(color: const Color(0xFF5AAE61), width: 1.5) : null,
                  ),
                  child: Center(
                    child: Text('$day',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w400,
                          color: mins > 0 && intensity > 0.5
                              ? Colors.white
                              : const Color(0xFF5AAE61),
                        )),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Stats Tab ─────────────────────────────────────────────────────────────────

class StatsTab extends StatelessWidget {
  final int totalMinutes;
  final int totalSunEver;
  final int streak;
  final Set<String> earnedAchievements;
  final int totalWaterCount;
  final int dailyGoalSessions;
  final int sessionsToday;
  final Map<String, int> weeklyMinutes;
  final void Function(int delta) onGoalChange;
  final ScrollController? scrollController;
  const StatsTab({super.key, required this.totalMinutes, required this.totalSunEver,
      required this.streak, required this.earnedAchievements, required this.totalWaterCount,
      required this.dailyGoalSessions,
      required this.sessionsToday, required this.weeklyMinutes, required this.onGoalChange,
      this.scrollController});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('istatistik',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: Color(0xFF5AAE61), letterSpacing: 2)),
            const SizedBox(height: 20),

            // Günlük Hedef Kartı
            _DailyGoalCard(
              goal: dailyGoalSessions,
              done: sessionsToday,
              onGoalChange: onGoalChange,
            ),
            const SizedBox(height: 20),

            // Haftalık Özet
            _WeeklyChart(weeklyMinutes: weeklyMinutes),
            const SizedBox(height: 16),

            // Streak görsel
            _StreakCard(streak: streak, weeklyMinutes: weeklyMinutes),
            const SizedBox(height: 16),

            // Stat kartları
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _StatCard(
                  icon: Icons.timer_rounded, iconColor: const Color(0xFF5C6BC0),
                  gradient: const [Color(0xFF7986CB), Color(0xFF5C6BC0)],
                  label: 'Odaklanma', value: '$totalMinutes dk'),
                _StatCard(
                  icon: Icons.wb_sunny_rounded, iconColor: const Color(0xFFFFB300),
                  gradient: const [Color(0xFFFFCA28), Color(0xFFFFB300)],
                  label: 'Toplam Güneş', value: '$totalSunEver'),
                _StatCard(
                  icon: Icons.local_fire_department_rounded, iconColor: const Color(0xFFFF5722),
                  gradient: const [Color(0xFFFF7043), Color(0xFFFF5722)],
                  label: 'Seri', value: '$streak gün'),
                _StatCard(
                  icon: Icons.water_drop_rounded, iconColor: const Color(0xFF2196F3),
                  gradient: const [Color(0xFF42A5F5), Color(0xFF2196F3)],
                  label: 'Sulama', value: '$totalWaterCount kez'),
              ],
            ),

            const SizedBox(height: 32),
            const Text('başarımlar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                    color: Color(0xFF3A5A3C))),
            const SizedBox(height: 16),

            const SizedBox(height: 32),
            ...achievements.map((a) {
              final earned = earnedAchievements.contains(a.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: earned ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: earned ? const Color(0xFFC8E6C9) : const Color(0xFFE0E0E0),
                  ),
                ),
                child: Row(
                  children: [
                    Text(a.emoji,
                        style: TextStyle(fontSize: 28,
                            color: earned ? null : Colors.grey.withValues(alpha: 0.4))),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                  color: earned ? const Color(0xFF3A5A3C) : Colors.grey)),
                          Text(a.description,
                              style: TextStyle(fontSize: 12,
                                  color: earned ? const Color(0xFF8CAF8E) : Colors.grey.shade400)),
                        ],
                      ),
                    ),
                    if (earned)
                      const Text('✓', style: TextStyle(fontSize: 20,
                          color: Color(0xFF5AAE61), fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final List<Color> gradient;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.iconColor,
      required this.gradient, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: gradient.last.withValues(alpha: 0.25),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  color: Colors.white)),
              Text(label, style: TextStyle(fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.8))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Daily Goal Card ───────────────────────────────────────────────────────────

class _DailyGoalCard extends StatelessWidget {
  final int goal;
  final int done;
  final void Function(int delta) onGoalChange;
  const _DailyGoalCard({required this.goal, required this.done, required this.onGoalChange});

  @override
  Widget build(BuildContext context) {
    final progress = (done / goal).clamp(0.0, 1.0);
    final reached = done >= goal;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Günlük Hedef',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: Color(0xFF3A5A3C))),
              ),
              GestureDetector(
                onTap: () => onGoalChange(-1),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.remove, size: 16, color: Color(0xFF5AAE61)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('$goal seans',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                        color: Color(0xFF3A5A3C))),
              ),
              GestureDetector(
                onTap: () => onGoalChange(1),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.add, size: 16, color: Color(0xFF5AAE61)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress, minHeight: 8,
              backgroundColor: const Color(0xFFD4EDDA),
              valueColor: AlwaysStoppedAnimation<Color>(
                  reached ? const Color(0xFFFF8F00) : const Color(0xFF5AAE61)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reached ? '🌟 Tebrikler! Günlük hedefe ulaştın!' : '$done/$goal seans tamamlandı',
            style: TextStyle(
              fontSize: 12,
              color: reached ? const Color(0xFFE65100) : const Color(0xFF8CAF8E),
              fontWeight: reached ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Weekly Chart ──────────────────────────────────────────────────────────────

class _WeeklyChart extends StatelessWidget {
  final Map<String, int> weeklyMinutes;
  const _WeeklyChart({required this.weeklyMinutes});

  static const _dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  Widget build(BuildContext context) {
    // Bu haftanın Pazartesi'sinden bugüne
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final days = List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      final ds = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      return (date: ds, minutes: weeklyMinutes[ds] ?? 0, weekday: d.weekday);
    });

    final maxMin = days.map((d) => d.minutes).fold(0, (a, b) => a > b ? a : b);
    final bestIdx = maxMin > 0 ? days.indexWhere((d) => d.minutes == maxMin) : -1;
    final totalWeek = days.fold(0, (s, d) => s + d.minutes);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Bu Hafta',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: Color(0xFF3A5A3C))),
              ),
              Text('$totalWeek dk toplam',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8CAF8E))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final d = days[i];
              final isBest = i == bestIdx;
              final isToday = i == 6;
              final barH = maxMin > 0 ? (d.minutes / maxMin * 80).clamp(4.0, 80.0) : 4.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (d.minutes > 0)
                        Text('${d.minutes}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isBest ? const Color(0xFFE65100) : const Color(0xFF8CAF8E),
                            )),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: barH,
                        decoration: BoxDecoration(
                          color: isBest
                              ? const Color(0xFFFFB300)
                              : isToday
                                  ? const Color(0xFF5AAE61)
                                  : const Color(0xFFD4EDDA),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(_dayLabels[d.weekday - 1],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isToday ? FontWeight.w800 : FontWeight.normal,
                            color: isToday ? const Color(0xFF5AAE61) : const Color(0xFF8CAF8E),
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Celebration Overlay ───────────────────────────────────────────────────────

class _CelebrationOverlay extends StatefulWidget {
  final Flower flower;
  const _CelebrationOverlay({required this.flower});

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _cardScale;
  final List<_Particle> _particles = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
      ..forward();
    _cardScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)),
        weight: 28,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 14,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 58),
    ]).animate(_ctrl);

    final colors = [
      const Color(0xFFFFB7C5), const Color(0xFFFFD580),
      const Color(0xFFA8E6C1), const Color(0xFFDDB8E8),
      const Color(0xFFFFAB76), const Color(0xFF9BD4F5),
    ];
    for (int i = 0; i < 38; i++) {
      _particles.add(_Particle(
        x: _rnd.nextDouble(),
        y: -0.08 - _rnd.nextDouble() * 0.4,
        speed: 0.32 + _rnd.nextDouble() * 0.48,
        size: 7 + _rnd.nextDouble() * 9,
        color: colors[_rnd.nextInt(colors.length)],
        wobble: _rnd.nextDouble() * 2 - 1,
        isOval: _rnd.nextBool(),
      ));
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Widget _buildFlowerImage() {
    final asset = widget.flower.fullAsset;
    if (asset != null) {
      return Image.asset(
        asset,
        width: 96, height: 96,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => Text(
          widget.flower.stages.last,
          style: const TextStyle(fontSize: 72),
        ),
      );
    }
    return Text(widget.flower.stages.last, style: const TextStyle(fontSize: 72));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = _ctrl.value;
          final fadeOut = (1 - ((t - 0.62) / 0.38).clamp(0.0, 1.0));
          return Stack(
            children: [
              // Soft background
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.22 * fadeOut),
                ),
              ),
              // Petal confetti
              ..._particles.map((p) {
                final py = p.y + t * p.speed;
                final px = p.x + sin(t * 5 * pi * p.wobble) * 0.04;
                final opacity = (1 - t * 1.25).clamp(0.0, 1.0);
                return Positioned(
                  left: size.width * px,
                  top: size.height * py,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.rotate(
                      angle: t * 4 * p.wobble,
                      child: Container(
                        width: p.isOval ? p.size * 0.55 : p.size,
                        height: p.size,
                        decoration: BoxDecoration(
                          color: p.color,
                          borderRadius: BorderRadius.circular(
                            p.isOval ? p.size : p.size / 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              // Center card
              Center(
                child: Opacity(
                  opacity: fadeOut,
                  child: Transform.scale(
                    scale: _cardScale.value,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.fromLTRB(32, 36, 32, 28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFB7C5).withValues(alpha: 0.45),
                            blurRadius: 56,
                            spreadRadius: 10,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFlowerImage(),
                          const SizedBox(height: 18),
                          const Text(
                            'Çiçeğin Açtı!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2E6B45),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.flower.label,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF999999),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}

class _Particle {
  final double x, y, speed, size, wobble;
  final Color color;
  final bool isOval;
  _Particle({required this.x, required this.y, required this.speed,
      required this.size, required this.color, required this.wobble,
      required this.isOval});
}

// ── Garden Wallpaper ───────────────────────────────────────────────────────────

class _GardenWallpaper extends StatelessWidget {
  final bool hasFertilizer;
  const _GardenWallpaper({required this.hasFertilizer});

  @override
  Widget build(BuildContext context) {
    final color = hasFertilizer
        ? Colors.green.withValues(alpha: 0.07)
        : Colors.green.withValues(alpha: 0.04);
    return IgnorePointer(
        child: CustomPaint(painter: _WallpaperPainter(color: color)));
  }
}

class _WallpaperPainter extends CustomPainter {
  final Color color;
  const _WallpaperPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    const spacing = 38.0;
    for (double y = 0; y < size.height * 0.7; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        final offset = (y ~/ spacing).isOdd ? spacing / 2 : 0.0;
        tp.text = TextSpan(text: '✿', style: TextStyle(fontSize: 15, color: color));
        tp.layout();
        tp.paint(canvas, Offset(x + offset, y));
      }
    }
  }

  @override
  bool shouldRepaint(_WallpaperPainter old) => old.color != color;
}

// ── Daily Task Card ────────────────────────────────────────────────────────────

class _DailyTaskCard extends StatelessWidget {
  final DailyTask task;
  final bool done;
  final int progress;
  const _DailyTaskCard({required this.task, required this.done, required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress / task.target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFE8F5E9) : const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done ? const Color(0xFFA5D6A7) : const Color(0xFFFFE082),
        ),
      ),
      child: Row(
        children: [
          Text(done ? '✅' : '🎯', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.text,
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: done ? const Color(0xFF388E3C) : const Color(0xFF5D4037),
                    )),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: done ? 1.0 : sigmoidProgress(pct),
                    minHeight: 4,
                    backgroundColor: Colors.black12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      done ? const Color(0xFF66BB6A) : const Color(0xFFFFCA28),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(done ? 'tamamlandı!' : '$progress / ${task.target}',
                    style: TextStyle(
                      fontSize: 10,
                      color: done ? const Color(0xFF66BB6A) : const Color(0xFF8D6E63),
                    )),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: done ? const Color(0xFF66BB6A) : const Color(0xFFFFCA28),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('+${task.reward} ☀️',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: done ? Colors.white : const Color(0xFF5D4037),
                )),
          ),
        ],
      ),
    );
  }
}

// ── Market Card ────────────────────────────────────────────────────────────────

class _MarketCard extends StatelessWidget {
  final MarketItem item;
  final bool owned;
  final String? ownedLabel;
  final bool canAfford;
  final VoidCallback onBuy;
  const _MarketCard({required this.item, required this.owned,
      this.ownedLabel, required this.canAfford, required this.onBuy});

  static (IconData, Color) _iconFor(String id) => switch (id) {
    'water'         => (Icons.water_drop_rounded,          Color(0xFF2196F3)),
    'pesticide'     => (Icons.bug_report_rounded,          Color(0xFFFF6D00)),
    'revival'       => (Icons.auto_fix_high_rounded,       Color(0xFF7B5EA7)),
    'streak_freeze' => (Icons.ac_unit_rounded,             Color(0xFF00BCD4)),
    'sprinkler'     => (Icons.shower_rounded,              Color(0xFF29B6F6)),
    'stone'         => (Icons.circle,                      Color(0xFF9E9E9E)),
    'fertilizer'    => (Icons.spa_rounded,                 Color(0xFF4CAF50)),
    'fancy_pot'     => (Icons.local_florist_rounded,       Color(0xFF795548)),
    _               => (Icons.star_rounded,                Color(0xFF5AAE61)),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor) = _iconFor(item.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w700, color: Color(0xFF2D2D2D))),
                Text(item.description, style: const TextStyle(fontSize: 11,
                    color: Color(0xFF9E9E9E))),
              ],
            ),
          ),
          if (owned && !item.isTreat)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(ownedLabel ?? 'sahip', style: const TextStyle(fontSize: 11,
                  color: Color(0xFF5AAE61), fontWeight: FontWeight.w700)),
            )
          else if (owned && item.isTreat)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(ownedLabel ?? 'aktif', style: const TextStyle(fontSize: 11,
                  color: Color(0xFF5AAE61), fontWeight: FontWeight.w700)),
            )
          else
            _ScaleTap(
              onTap: onBuy,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: canAfford ? const Color(0xFF5AAE61) : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.wb_sunny_rounded, size: 13,
                      color: canAfford ? Colors.white : const Color(0xFFBDBDBD)),
                  const SizedBox(width: 4),
                  Text('${item.price}', style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: canAfford ? Colors.white : const Color(0xFFBDBDBD))),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Sun Badge ─────────────────────────────────────────────────────────────────

class _SunBadge extends StatelessWidget {
  final int balance;
  final VoidCallback? onLongPress;
  const _SunBadge({required this.balance, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFD4EDDA),
            borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('☀️', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text('$balance', style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700, color: Color(0xFF5AAE61))),
          ],
        ),
      ),
    );
  }
}

// ── Duration Btn ──────────────────────────────────────────────────────────────

class _DurationBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _DurationBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 18, color: const Color(0xFF5AAE61)),
      ),
    );
  }
}


// ── Scale Tap ─────────────────────────────────────────────────────────────────

class _ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _ScaleTap({required this.child, this.onTap});

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _onTap() async {
    await _ctrl.forward();
    await _ctrl.reverse();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ── Encyclopedia Entry ────────────────────────────────────────────────────────

class _EncyclopediaEntry extends StatefulWidget {
  final Flower flower;
  final bool locked;
  const _EncyclopediaEntry({required this.flower, this.locked = false});

  @override
  State<_EncyclopediaEntry> createState() => _EncyclopediaEntryState();
}

class _EncyclopediaEntryState extends State<_EncyclopediaEntry> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.flower;
    final locked = widget.locked;
    final isMystery = f.name == 'mystery';
    final isCactus = f.name == 'cactus';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: locked ? const Color(0xFFF5F5F5) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          // ── Header row ─────────────────────────────────────────────────────
          _ScaleTap(
            onTap: locked ? null : () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Flower image / locked
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: locked ? const Color(0xFFEEEEEE) : const Color(0xFFF0FAF0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: locked
                        ? const Center(child: Icon(Icons.lock_rounded, color: Color(0xFFBDBDBD), size: 26))
                        : isMystery
                            ? const Center(child: Text('❓', style: TextStyle(fontSize: 28)))
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.asset(
                                  f.fullAsset!,
                                  width: 56, height: 56,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.none,
                                  errorBuilder: (_, __, ___) =>
                                      Center(child: Text(f.emoji, style: const TextStyle(fontSize: 28))),
                                ),
                              ),
                  ),
                  const SizedBox(width: 14),
                  // Name + latin + stages
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(locked ? '???' : f.label,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                                color: locked ? const Color(0xFFBDBDBD) : const Color(0xFF2E6B45))),
                        if (!locked && f.latinName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(f.latinName,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF8CAF8E),
                                  fontStyle: FontStyle.italic)),
                        ],
                        const SizedBox(height: 4),
                        locked
                            ? const Text('henüz yetiştirilmedi',
                                style: TextStyle(fontSize: 11, color: Color(0xFFBDBDBD)))
                            : Text(f.stages.join('  '), style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  if (!locked)
                    Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF8CAF8E), size: 22),
                ],
              ),
            ),
          ),
          // ── Expanded details ───────────────────────────────────────────────
          if (_expanded && !locked) ...[
            const Divider(height: 1, color: Color(0xFFE8F5E9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(f.description,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF4A7A5C), height: 1.5)),
                  const SizedBox(height: 12),
                  // Traits
                  if (f.traits.isNotEmpty) ...[
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: f.traits.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(t, style: const TextStyle(fontSize: 11, color: Color(0xFF4A7C59))),
                      )).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Special rules
                  if (isCactus) ...[
                    _EncyclopediaBadge(
                      icon: '☀️',
                      text: 'Güneşli havada dakikada +2 ☀️ kazanır (diğer çiçekler: +1)',
                      color: const Color(0xFFFFF8E1),
                      textColor: const Color(0xFF7A6000),
                    ),
                    const SizedBox(height: 6),
                    _EncyclopediaBadge(
                      icon: '🏜️',
                      text: 'Solmadan önce 5 gün bekler — diğer çiçekler 2 gün',
                      color: const Color(0xFFFCEBE0),
                      textColor: const Color(0xFF7A3B1E),
                    ),
                  ],
                  if (isMystery) ...[
                    _EncyclopediaBadge(
                      icon: '🎲',
                      text: 'Her büyümede rastgele bir çiçek ortaya çıkar — ne yetişeceği belli olmaz!',
                      color: const Color(0xFFF3E5F5),
                      textColor: const Color(0xFF6A1B9A),
                    ),
                  ],
                  if (!isCactus && !isMystery) ...[
                    _EncyclopediaBadge(
                      icon: '💧',
                      text: '2 gün sulanmazsa solar',
                      color: const Color(0xFFE3F2FD),
                      textColor: const Color(0xFF1565C0),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Growth stages
                  const Text('Büyüme aşamaları',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: Color(0xFF8CAF8E), letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (int i = 0; i < f.stages.length; i++) ...[
                        Column(
                          children: [
                            Text(f.stages[i], style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 2),
                            Text(['Tohum', 'Filiz', 'Tomurcuk', 'Tam'][i],
                                style: const TextStyle(fontSize: 9, color: Color(0xFF8CAF8E))),
                          ],
                        ),
                        if (i < f.stages.length - 1)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFC8E6C9)),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EncyclopediaBadge extends StatelessWidget {
  final String icon;
  final String text;
  final Color color;
  final Color textColor;
  const _EncyclopediaBadge({required this.icon, required this.text,
      required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12, color: textColor, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ── Album Flower Card ─────────────────────────────────────────────────────────


// ── Streak Card ───────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final int streak;
  final Map<String, int> weeklyMinutes;
  const _StreakCard({required this.streak, required this.weeklyMinutes});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final days = List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      final ds = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      return (weeklyMinutes[ds] ?? 0) > 0;
    });
    final dayLabels = ['Pzt','Sal','Çar','Per','Cum','Cmt','Paz'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('🔥', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 6),
                Text('$streak gün',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                        color: Color(0xFFE65100))),
              ]),
              const SizedBox(height: 2),
              const Text('günlük seri',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8CAF8E))),
            ],
          ),
          const Spacer(),
          Row(
            children: List.generate(7, (i) {
              final active = days[i];
              final isToday = i == 6;
              final d = DateTime.now().subtract(Duration(days: 6 - i));
              final label = dayLabels[d.weekday - 1];
              return Padding(
                padding: EdgeInsets.only(left: i > 0 ? 5 : 0),
                child: Column(
                  children: [
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: active
                            ? (isToday ? const Color(0xFFFF8F00) : const Color(0xFFFFB300))
                            : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: active
                              ? (isToday ? const Color(0xFFE65100) : const Color(0xFFFFCA28))
                              : const Color(0xFFE0E0E0),
                          width: isToday ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          active ? '🔥' : '·',
                          style: TextStyle(fontSize: active ? 12 : 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(label,
                        style: TextStyle(
                          fontSize: 8,
                          color: isToday ? const Color(0xFFE65100) : const Color(0xFF8CAF8E),
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.normal,
                        )),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Rain Overlay ──────────────────────────────────────────────────────────────

class _RainOverlay extends StatefulWidget {
  const _RainOverlay();
  @override
  State<_RainOverlay> createState() => _RainOverlayState();
}

class _RainOverlayState extends State<_RainOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_RainDrop> _drops;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _drops = List.generate(22, (_) => _RainDrop(_rng));
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..addListener(() { if (mounted) setState(() {}); })
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RainPainter(_drops, _ctrl.value),
      child: const SizedBox.expand(),
    );
  }
}

class _RainDrop {
  final double x;
  final double phase;
  final double speed;
  final double length;
  _RainDrop(Random rng)
      : x = rng.nextDouble(),
        phase = rng.nextDouble(),
        speed = 0.6 + rng.nextDouble() * 0.8,
        length = 10 + rng.nextDouble() * 14;
}

class _RainPainter extends CustomPainter {
  final List<_RainDrop> drops;
  final double t;
  _RainPainter(this.drops, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF90CAF9).withValues(alpha: 0.4)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (final d in drops) {
      final progress = (t * d.speed + d.phase) % 1.0;
      final y = progress * (size.height + d.length) - d.length;
      final x = d.x * size.width;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 1.5, y + d.length),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RainPainter old) => true;
}

// ── Water Burst ───────────────────────────────────────────────────────────────

class _WaterBurst extends StatefulWidget {
  const _WaterBurst();

  @override
  State<_WaterBurst> createState() => _WaterBurstState();
}

class _WaterBurstState extends State<_WaterBurst> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..forward();
    _opacity = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 1.0)));
    _offset = Tween<double>(begin: 0, end: -70).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, _offset.value),
          child: const Text('💧 💧 💧', style: TextStyle(fontSize: 28)),
        ),
      ),
    );
  }
}
