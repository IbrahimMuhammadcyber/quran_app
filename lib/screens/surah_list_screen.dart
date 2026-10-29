import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/surah.dart';
import '../services/quran_api_service.dart';
import '../services/audio_player_service.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import '../theme/app_colors.dart';
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

  void _showSleepTimerSheet(BuildContext context, AppColors colors) {
    final player = context.read<AudioPlayerService>();
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      builder: (context) {
        final options = [5, 10, 15, 30, 45, 60];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Sleep Timer',
                    style: TextStyle(color: colors.textPrimary, fontSize: 18)),
              ),
              ...options.map((minutes) => ListTile(
                    title: Text('$minutes minutes',
                        style: TextStyle(color: colors.textPrimary)),
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
    final isDark = context.watch<ThemeService>().isDarkMode;
    final colors = AppColors(isDark);
    final reciterName = reciters
        .firstWhere((r) => r.id == player.reciter,
            orElse: () => reciters.first)
        .name;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textSecondary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tilawah',
                style: TextStyle(color: colors.textSecondary, fontSize: 18)),
            if (player.currentSurah != null)
              Text(reciterName,
                  style: TextStyle(color: colors.textFaint, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: colors.textSecondary),
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
            icon: Icon(Icons.timer_outlined, color: colors.textSecondary),
            onPressed: () => _showSleepTimerSheet(context, colors),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: colors.textSecondary),
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
                  style: TextStyle(color: colors.textSecondary)),
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
                  color: colors.surfaceAlt,
                  child: ListTile(
                    leading: Icon(Icons.history, color: colors.accent),
                    title: Text(
                      'Continue: ${lastSurah.nameTransliteration}',
                      style: TextStyle(color: colors.textPrimary),
                    ),
                    subtitle: Text('Tap to resume',
                        style: TextStyle(color: colors.textMuted)),
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
                      Divider(height: 1, color: colors.divider),
                  itemBuilder: (context, index) {
                    final surah = surahs[index];
                    return _SurahTile(
                      surah: surah,
                      colors: colors,
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
  final AppColors colors;
  final VoidCallback onTap;

  const _SurahTile(
      {required this.surah, required this.colors, required this.onTap});

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
    final colors = widget.colors;
    return ListTile(
      onTap: widget.onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: const Text('🕋', style: TextStyle(fontSize: 20)),
      ),
      title: Text(
        '${widget.surah.number} - ${widget.surah.nameArabic}',
        textAlign: TextAlign.right,
        style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w500),
      ),
      subtitle: Text(widget.surah.nameTransliteration,
          style: TextStyle(color: colors.textMuted, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.surah.formattedDuration,
                  style: TextStyle(color: colors.textSecondary)),
              const SizedBox(height: 4),
              Text('Total verses (${widget.surah.totalVerses})',
                  style: TextStyle(color: colors.textFaint, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 4),
          if (_progress != null)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  value: _progress, strokeWidth: 2, color: colors.accent),
            )
          else
            IconButton(
              icon: Icon(
                _downloaded ? Icons.download_done : Icons.download_outlined,
                color: _downloaded ? colors.accent : colors.textFaint,
                size: 20,
              ),
              onPressed: _downloaded ? null : _download,
            ),
        ],
      ),
    );
  }
}
