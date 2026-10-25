import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/surah.dart';
import '../services/quran_api_service.dart';
import '../services/audio_player_service.dart';
import '../widgets/mini_player.dart';
import 'settings_screen.dart';
import 'search_screen.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  final QuranApiService _api = QuranApiService();
  late Future<List<Surah>> _surahsFuture;
  List<Surah> _loadedSurahs = [];

  @override
  void initState() {
    super.initState();
    _surahsFuture = _api.fetchSurahList();
  }

  void _showSleepTimerSheet(BuildContext context) {
    final player = context.read<AudioPlayerService>();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) {
        final options = [5, 10, 15, 30, 45, 60];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Sleep Timer',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              ...options.map((minutes) => ListTile(
                    title: Text('$minutes minutes',
                        style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      player.startSleepTimer(Duration(minutes: minutes));
                      Navigator.pop(context);
                    },
                  )),
              if (player.sleepTimerDuration != null)
                ListTile(
                  title: const Text('Cancel timer',
                      style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    player.cancelSleepTimer();
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final reciterName = reciters
        .firstWhere((r) => r.id == player.reciter,
            orElse: () => reciters.first)
        .name;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tilawah',
                style: TextStyle(color: Colors.white70, fontSize: 18)),
            if (player.currentSurah != null)
              Text(reciterName,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchScreen(allSurahs: _loadedSurahs),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.timer_outlined, color: Colors.white70),
            onPressed: () => _showSleepTimerSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Surah>>(
        future: _surahsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load surahs: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white70)),
            );
          }
          final surahs = snapshot.data!;
          _loadedSurahs = surahs;
          return ListView.separated(
            itemCount: surahs.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Colors.white12),
            itemBuilder: (context, index) {
              final surah = surahs[index];
              return _SurahTile(
                surah: surah,
                onTap: () {
                  player.playSurah(surah, queue: surahs);
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: player.currentSurah == null
          ? null
          : const MiniPlayer(),
    );
  }
}

class _SurahTile extends StatelessWidget {
  final Surah surah;
  final VoidCallback onTap;

  const _SurahTile({required this.surah, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: const Text('🕋', style: TextStyle(fontSize: 20)),
      ),
      title: Text(
        '${surah.number} - ${surah.nameArabic}',
        textAlign: TextAlign.right,
        style: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(surah.nameTransliteration,
          style: const TextStyle(color: Colors.white54, fontSize: 15)),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(surah.formattedDuration,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text('Total verses (${surah.totalVerses})',
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}
