import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/surah.dart';
import '../services/audio_player_service.dart';

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
    final filtered = widget.allSurahs.where((s) {
      final q = _query.toLowerCase();
      return s.nameTransliteration.toLowerCase().contains(q) ||
          s.nameArabic.contains(_query) ||
          s.number.toString() == _query;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search surah by name or number',
            hintStyle: TextStyle(color: Colors.white38),
            border: InputBorder.none,
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
      ),
      body: ListView.separated(
        itemCount: filtered.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Colors.white12),
        itemBuilder: (context, index) {
          final surah = filtered[index];
          return ListTile(
            title: Text('${surah.number} - ${surah.nameArabic}',
                style: const TextStyle(color: Colors.white)),
            subtitle: Text(surah.nameTransliteration,
                style: const TextStyle(color: Colors.white54)),
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
