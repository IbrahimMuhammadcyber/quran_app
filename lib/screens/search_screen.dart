import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/surah.dart';
import '../services/audio_player_service.dart';
import '../services/theme_service.dart';
import '../theme/app_colors.dart';

class SearchScreen extends StatefulWidget {
  final List<Surah> allSurahs;
  const SearchScreen({super.key, required this.allSurahs});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final player = context.read<AudioPlayerService>();
    final isDark = context.watch<ThemeService>().isDarkMode;
    final colors = AppColors(isDark);
    final filtered = widget.allSurahs.where((s) {
      final q = _query.toLowerCase();
      return s.nameTransliteration.toLowerCase().contains(q) ||
          s.nameArabic.contains(_query) ||
          s.number.toString() == _query;
    }).toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textSecondary),
        title: TextField(
          autofocus: true,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search surah by name or number',
            hintStyle: TextStyle(color: colors.textFaint),
            border: InputBorder.none,
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
      ),
      body: ListView.separated(
        itemCount: filtered.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: colors.divider),
        itemBuilder: (context, index) {
          final surah = filtered[index];
          return ListTile(
            title: Text('${surah.number} - ${surah.nameArabic}',
                style: TextStyle(color: colors.textPrimary)),
            subtitle: Text(surah.nameTransliteration,
                style: TextStyle(color: colors.textMuted)),
            onTap: () {
              player.playSurah(surah, queue: widget.allSurahs);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
