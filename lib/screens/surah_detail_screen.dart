import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../services/quran_api_service.dart';
import '../services/audio_player_service.dart';
import '../services/storage_service.dart';

class SurahDetailScreen extends StatefulWidget {
  final Surah surah;
  const SurahDetailScreen({super.key, required this.surah});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final QuranApiService _api = QuranApiService();
  final StorageService _storage = StorageService();
  final ScrollController _scrollController = ScrollController();
  late Future<List<Ayah>> _versesFuture;
  double _fontSize = 22;
  Timer? _saveTimer;
  int _verseCount = 0;

  @override
  void initState() {
    super.initState();
    _versesFuture = _api.fetchVerses(widget.surah.number);
    _loadFontSize();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _fontSize = prefs.getDouble('verse_font_size') ?? 22);
    }
  }

  Future<void> _changeFontSize(double delta) async {
    final prefs = await SharedPreferences.getInstance();
    final newSize = (_fontSize + delta).clamp(14.0, 36.0);
    await prefs.setDouble('verse_font_size', newSize);
    setState(() => _fontSize = newSize);
  }

  void _onScroll() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), () {
      if (!_scrollController.hasClients || _verseCount == 0) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
      final fraction = maxScroll > 0 ? (current / maxScroll).clamp(0, 1) : 0;
      final approxAyah = (fraction * _verseCount).round().clamp(1, _verseCount);
      _storage.saveLastRead(widget.surah.number, approxAyah);
    });
  }

  Future<void> _showTafsir(int ayahNumber) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: FutureBuilder<String>(
              future: _api.fetchTafsir(widget.surah.number, ayahNumber),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    'Tafsir unavailable for this verse right now.',
                    style: const TextStyle(color: Colors.white54),
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tafsir Al-Muyassar (Arabic)',
                        style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.data ?? '',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, height: 1.7),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
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
            icon: const Icon(Icons.text_decrease, color: Colors.white70),
            onPressed: () => _changeFontSize(-2),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase, color: Colors.white70),
            onPressed: () => _changeFontSize(2),
          ),
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
          _verseCount = verses.length;
          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: verses.length,
            separatorBuilder: (_, __) =>
                const Divider(color: Colors.white12, height: 32),
            itemBuilder: (context, index) {
              final ayah = verses[index];
              return _VerseTile(
                ayah: ayah,
                fontSize: _fontSize,
                onTafsirTap: () => _showTafsir(ayah.numberInSurah),
              );
            },
          );
        },
      ),
    );
  }
}

class _VerseTile extends StatelessWidget {
  final Ayah ayah;
  final double fontSize;
  final VoidCallback onTafsirTap;

  const _VerseTile({
    required this.ayah,
    required this.fontSize,
    required this.onTafsirTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            IconButton(
              icon: const Icon(Icons.info_outline,
                  color: Colors.white38, size: 18),
              onPressed: onTafsirTap,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          ayah.arabicText,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
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
