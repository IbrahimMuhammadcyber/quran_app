import 'package:flutter/material.dart';
import '../models/juz_ayah.dart';
import '../services/quran_api_service.dart';

class JuzDetailScreen extends StatefulWidget {
  final int juzNumber;
  const JuzDetailScreen({super.key, required this.juzNumber});

  @override
  State<JuzDetailScreen> createState() => _JuzDetailScreenState();
}

class _JuzDetailScreenState extends State<JuzDetailScreen> {
  final QuranApiService _api = QuranApiService();
  late Future<List<JuzAyah>> _ayahsFuture;

  @override
  void initState() {
    super.initState();
    _ayahsFuture = _api.fetchJuz(widget.juzNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Juz ${widget.juzNumber}',
            style: const TextStyle(color: Colors.white70, fontSize: 18)),
      ),
      body: FutureBuilder<List<JuzAyah>>(
        future: _ayahsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Failed to load: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70)),
              ),
            );
          }
          final ayahs = snapshot.data!;
          int? lastSurah;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ayahs.length,
            itemBuilder: (context, index) {
              final ayah = ayahs[index];
              final showHeader = ayah.surahNumber != lastSurah;
              lastSurah = ayah.surahNumber;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showHeader)
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 12),
                      child: Text(
                        '${ayah.surahNumber}. ${ayah.surahName}',
                        style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  Text(
                    '${ayah.arabicText} (${ayah.numberInSurah})',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, height: 1.8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ayah.translation,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13, height: 1.4),
                  ),
                  const Divider(color: Colors.white12, height: 32),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
