import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/surah.dart';
import '../services/quran_api_service.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import '../theme/app_colors.dart';
import 'surah_detail_screen.dart';
import 'juz_list_screen.dart';

class ReadSurahListScreen extends StatefulWidget {
  const ReadSurahListScreen({super.key});

  @override
  State<ReadSurahListScreen> createState() => _ReadSurahListScreenState();
}

class _ReadSurahListScreenState extends State<ReadSurahListScreen> {
  final QuranApiService _api = QuranApiService();
  final StorageService _storage = StorageService();
  late Future<List<Surah>> _surahsFuture;
  Set<int> _favorites = {};
  Map<String, int>? _lastRead;
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _surahsFuture = _api.fetchSurahList();
    _loadFavorites();
    _loadLastRead();
  }

  Future<void> _loadFavorites() async {
    final favs = await _storage.getFavorites();
    if (mounted) setState(() => _favorites = favs);
  }

  Future<void> _loadLastRead() async {
    final last = await _storage.getLastRead();
    if (mounted) setState(() => _lastRead = last);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeService>().isDarkMode;
    final colors = AppColors(isDark);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textSecondary),
        title: Text('Read Quran',
            style: TextStyle(color: colors.textSecondary, fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(Icons.view_list_outlined, color: colors.textSecondary),
            tooltip: 'Browse by Juz',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JuzListScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.star : Icons.star_border,
              color: _showFavoritesOnly ? colors.accent : colors.textSecondary,
            ),
            tooltip: 'Favorites',
            onPressed: () {
              setState(() => _showFavoritesOnly = !_showFavoritesOnly);
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
          var surahs = snapshot.data!;
          if (_showFavoritesOnly) {
            surahs =
                surahs.where((s) => _favorites.contains(s.number)).toList();
          }

          Surah? lastReadSurah;
          if (_lastRead != null && !_showFavoritesOnly) {
            try {
              lastReadSurah = snapshot.data!
                  .firstWhere((s) => s.number == _lastRead!['surahNumber']);
            } catch (_) {}
          }

          return Column(
            children: [
              if (lastReadSurah != null)
                Material(
                  color: colors.surfaceAlt,
                  child: ListTile(
                    leading: Icon(Icons.menu_book, color: colors.accent),
                    title: Text(
                      'Continue reading: ${lastReadSurah.nameTransliteration}',
                      style: TextStyle(color: colors.textPrimary),
                    ),
                    subtitle: Text('Ayah ${_lastRead!['ayahNumber']}',
                        style: TextStyle(color: colors.textMuted)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SurahDetailScreen(surah: lastReadSurah!),
                        ),
                      );
                    },
                  ),
                ),
              Expanded(
                child: surahs.isEmpty
                    ? Center(
                        child: Text(
                          _showFavoritesOnly
                              ? 'No favorites yet — tap the star on a surah to add one.'
                              : 'No surahs found.',
                          style: TextStyle(color: colors.textFaint),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        itemCount: surahs.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: colors.divider),
                        itemBuilder: (context, index) {
                          final surah = surahs[index];
                          final isFav = _favorites.contains(surah.number);
                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colors.card,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text('${surah.number}',
                                  style: TextStyle(
                                      color: colors.accent, fontSize: 14)),
                            ),
                            title: Text(
                              surah.nameArabic,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              '${surah.nameTransliteration} • ${surah.totalVerses} verses',
                              style: TextStyle(
                                  color: colors.textMuted, fontSize: 13),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                isFav ? Icons.star : Icons.star_border,
                                color:
                                    isFav ? colors.accent : colors.textFaint,
                              ),
                              onPressed: () async {
                                await _storage.toggleFavorite(surah.number);
                                _loadFavorites();
                              },
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SurahDetailScreen(surah: surah),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
