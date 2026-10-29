import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/juz_ayah.dart';
import '../services/quran_api_service.dart';
import '../services/theme_service.dart';
import '../theme/app_colors.dart';

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
    final isDark = context.watch<ThemeService>().isDarkMode;
    final colors = AppColors(isDark);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textSecondary),
        title: Text('Juz ${widget.juzNumber}',
            style: TextStyle(color: colors.textSecondary, fontSize: 18)),
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
                    style: TextStyle(color: colors.textSecondary)),
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
                        style: TextStyle(
                            color: colors.accent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  Text(
                    '${ayah.arabicText} (${ayah.numberInSurah})',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                        color: colors.textPrimary, fontSize: 20, height: 1.8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ayah.translation,
                    style: TextStyle(
                        color: colors.textMuted, fontSize: 13, height: 1.4),
                  ),
                  Divider(color: colors.divider, height: 32),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
