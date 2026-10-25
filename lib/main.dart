import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/surah_list_screen.dart';
import 'services/audio_player_service.dart';

void main() {
  runApp(const QuranApp());
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AudioPlayerService(),
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
