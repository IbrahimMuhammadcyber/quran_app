import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/surah.dart';
import '../services/quran_api_service.dart';
import '../services/audio_player_service.dart';
import '../services/storage_service.dart';
import '../widgets/mini_player.dart';
import 'settings_screen.dart';
import 'search_screen.dart';
import 'surah_detail_screen.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  final QuranApiService _api = QuranApiService();
  late Future<List<Surah>> _surahsFuture;
  List<Surah> _loadedSurahs = [];
  Map<String, dynamic>? _lastPlayed;

  @override
  void initState() {
    super.initState();
    _surahsFuture = _api.fetchSurahList();
    _loadLastPlayed();
  }

  Future<void> _loadLastPlayed() async {
    final storage = StorageService();
    final last = await storage.getLastPlayed();
    if (mounted) setState(() => _lastPlayed = last);
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

          Surah? lastSurah;
          if (_lastPlayed != null) {
            try {
              lastSurah = surahs.firstWhere(
                  (s) => s.number == _lastPlayed!['surahNumber']);
            } catch (_) {}
          }

          return Column(
            children: [
              if (lastSurah != null && player.currentSurah == null)
                Material(
                  color: const Color(0xFF1E1E1E),
                  child: ListTile(
                    leading: const Icon(Icons.history, color: Colors.amber),
                    title: Text(
                      'Continue: ${lastSurah.nameTransliteration}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text('Tap to resume',
                        style: TextStyle(color: Colors.white54)),
                    onTap: () {
                      player.setReciter(_lastPlayed!['reciter']);
                      player.playSurah(
                        lastSurah!,
                        queue: surahs,
                        startAt: Duration(
                            milliseconds: _lastPlayed!['positionMs']),
                      );
                    },
                  ),
                ),
              Expanded(
                child: ListView.separated(
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
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: player.currentSurah == null
          ? null
          : const MiniPlayer(),
    );
  }
}

class _SurahTile extends StatefulWidget {
  final Surah surah;
  final VoidCallback onTap;

  const _SurahTile({required this.surah, required this.onTap});

  @override
  State<_SurahTile> createState() => _SurahTileState();
}

class _SurahTileState extends State<_SurahTile> {
  final StorageService _storage = StorageService();
  bool _downloaded = false;
  double? _progress;

  @override
  void initState() {
    super.initState();
    _checkDownloaded();
  }

  Future<void> _checkDownloaded() async {
    final player = context.read<AudioPlayerService>();
    final downloaded =
        await _storage.isDownloaded(player.reciter, widget.surah.number);
    if (mounted) setState(() => _downloaded = downloaded);
  }

  Future<void> _download() async {
    final player = context.read<AudioPlayerService>();
    setState(() => _progress = 0);
    try {
      await _storage.downloadSurah(
        reciter: player.reciter,
        surahNumber: widget.surah.number,
        remoteUrl: player.audioUrlForDownload(widget.surah.number),
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (mounted) setState(() {
        _downloaded = true;
        _progress = null;
      });
    } catch (_) {
      if (mounted) setState(() => _progress = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: widget.onTap,
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
        '${widget.surah.number} - ${widget.surah.nameArabic}',
        textAlign: TextAlign.right,
        style: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(widget.surah.nameTransliteration,
          style: const TextStyle(color: Colors.white54, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.surah.formattedDuration,
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Text('Total verses (${widget.surah.totalVerses})',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.menu_book_outlined,
                color: Colors.white38, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SurahDetailScreen(surah: widget.surah),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          if (_progress != null)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  value: _progress, strokeWidth: 2, color: Colors.amber),
            )
          else
            IconButton(
              icon: Icon(
                _downloaded
                    ? Icons.download_done
                    : Icons.download_outlined,
                color: _downloaded ? Colors.amber : Colors.white38,
                size: 20,
              ),
              onPressed: _downloaded ? null : _download,
            ),
        ],
      ),
    );
  }
}),
              onPressed: _downloaded ? null : _download,
            ),
        ],
      ),
    );
  }
}
