import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/surah.dart';
import '../services/quran_api_service.dart';
import '../services/audio_player_service.dart';
import '../widgets/mini_player.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  final QuranApiService _api = QuranApiService();
  late Future<List<Surah>> _surahsFuture;

  @override
  void initState() {
    super.initState();
    _surahsFuture = _api.fetchSurahList();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text('Salah Buddy',
            style: TextStyle(color: Colors.white70, fontSize: 18)),
        actions: [
          IconButton(
              icon: const Icon(Icons.search, color: Colors.white70),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.timer_outlined, color: Colors.white70),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white70),
              onPressed: () {}),
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
          return ListView.separated(
            itemCount: surahs.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Colors.white12),
            itemBuilder: (context, index) {
              final surah = surahs[index];
              return _SurahTile(
                surah: surah,
                onTap: () {
                  final url = _api.audioUrlFor(surah.number);
                  player.playSurah(surah, url, queue: surahs);
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
