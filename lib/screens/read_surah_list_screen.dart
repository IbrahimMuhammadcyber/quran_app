import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../services/quran_api_service.dart';
import 'surah_detail_screen.dart';

class ReadSurahListScreen extends StatefulWidget {
  const ReadSurahListScreen({super.key});

  @override
  State<ReadSurahListScreen> createState() => _ReadSurahListScreenState();
}

class _ReadSurahListScreenState extends State<ReadSurahListScreen> {
  final QuranApiService _api = QuranApiService();
  late Future<List<Surah>> _surahsFuture;

  @override
  void initState() {
    super.initState();
    _surahsFuture = _api.fetchSurahList();
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
                          color: Color(0xFFD4AF37), fontSize: 14)),
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SurahDetailScreen(surah: surah),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
