import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'screens/surah_list_screen.dart';
import 'services/audio_player_service.dart';
import 'services/audio_handler.dart';
import 'services/prayer_service.dart';

late TilawahAudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrayerService().init();
  audioHandler = await AudioService.init(
    builder: () => TilawahAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.tilawah.audio',
      androidNotificationChannelName: 'Tilawah Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
  runApp(const QuranApp());
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AudioPlayerService(audioHandler),
      child: MaterialApp(
        title: 'Tilawah',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF121212),
          primaryColor: Colors.amber,
        ),
        home: const SurahListScreen(),
      ),
    );
  }
}
