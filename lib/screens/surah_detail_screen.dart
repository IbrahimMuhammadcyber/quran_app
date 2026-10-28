import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../services/quran_api_service.dart';
import '../services/audio_player_service.dart';

class SurahDetailScreen extends StatefulWidget {
  final Surah surah;
  const SurahDetailScreen({super.key, required this.surah});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final QuranApiService _api = QuranApiService();
  late Future<List<Ayah>> _versesFuture;

  @override
  void initState() {
    super.initState();
    _versesFuture = _api.fetchVerses(widget.surah.number);
  }

  @override
  Widget build(BuildContext context) {
    final player = context.read<AudioPlayerService>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${widget.surah.number} - ${widget.surah.nameTransliteration}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline, color: Colors.amber),
            onPressed: () {
              player.playSurah(widget.surah);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Ayah>>(
        future: _versesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load verses: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            );
          }
          final verses = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: verses.length,
            separatorBuilder: (_, __) =>
                const Divider(color: Colors.white12, height: 32),
            itemBuilder: (context, index) {
              final ayah = verses[index];
              return _VerseTile(ayah: ayah);
            },
          );
        },
      ),
    );
  }
}

class _VerseTile extends StatelessWidget {
  final Ayah ayah;
  const _VerseTile({required this.ayah});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                '${ayah.numberInSurah}',
                style: const TextStyle(color: Colors.amber, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          ayah.arabicText,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            height: 1.8,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          ayah.translation,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
