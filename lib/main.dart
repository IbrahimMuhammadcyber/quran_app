import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/audio_player_service.dart';
import 'services/prayer_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrayerService().init();
  final themeService = ThemeService();
  await themeService.load();
  runApp(QuranApp(themeService: themeService));
}

class QuranApp extends StatelessWidget {
  final ThemeService themeService;
  const QuranApp({super.key, required this.themeService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioPlayerService()),
        ChangeNotifierProvider.value(value: themeService),
      ],
      child: Consumer<ThemeService>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'Tilawah',
            debugShowCheckedModeBanner: false,
            themeMode: theme.themeMode,
            theme: ThemeData.light().copyWith(
              scaffoldBackgroundColor: const Color(0xFFFAF7F0),
              primaryColor: const Color(0xFFD4AF37),
            ),
            darkTheme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: const Color(0xFF121212),
              primaryColor: const Color(0xFFD4AF37),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
