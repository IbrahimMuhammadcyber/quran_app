import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../services/quran_api_service.dart';
import '../services/storage_service.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Read Quran',
            style: TextStyle(color: Colors.white70, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_list_outlined, color: Colors.white70),
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
              color: _showFavoritesOnly ? Colors.amber : Colors.white70,
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
                  style: const TextStyle(color: Colors.white70)),
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
                  color: const Color(0xFF1E1E1E),
                  child: ListTile(
                    leading:
                        const Icon(Icons.menu_book, color: Color(0xFFD4AF37)),
                    title: Text(
                      'Continue reading: ${lastReadSurah.nameTransliteration}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                        'Ayah ${_lastRead!['ayahNumber']}',
                        style: const TextStyle(color: Colors.white54)),
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
                          style: const TextStyle(color: Colors.white38),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        itemCount: surahs.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: Colors.white12),
                        itemBuilder: (context, index) {
                          final surah = surahs[index];
                          final isFav = _favorites.contains(surah.number);
                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text('${surah.number}',
                                  style: const TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontSize: 14)),
                            ),
                            title: Text(
                              surah.nameArabic,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              '${surah.nameTransliteration} • ${surah.totalVerses} verses',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 13),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                isFav ? Icons.star : Icons.star_border,
                                color: isFav
                                    ? Colors.amber
                                    : Colors.white38,
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
