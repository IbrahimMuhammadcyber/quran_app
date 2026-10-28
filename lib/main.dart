import 'screens/home_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/surah_list_screen.dart';
import 'services/audio_player_service.dart';
import 'services/prayer_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    String? startupError;
    try {
      await PrayerService().init();
    } catch (e, st) {
      startupError = 'PrayerService.init() failed:\n$e\n\n$st';
    }

    runApp(QuranApp(startupError: startupError));
  }, (error, stack) {
    runApp(ErrorApp(error: 'Uncaught error:\n$error\n\n$stack'));
  });
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: const Text('Startup Error')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            error,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class QuranApp extends StatelessWidget {
  final String? startupError;
  const QuranApp({super.key, this.startupError});

  @override
  Widget build(BuildContext context) {
    if (startupError != null) {
      return ErrorApp(error: startupError!);
    }
    return ChangeNotifierProvider(
      create: (_) => AudioPlayerService(),
      child: MaterialApp(
        title: 'Tilawah',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF121212),
          primaryColor: Colors.amber,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
