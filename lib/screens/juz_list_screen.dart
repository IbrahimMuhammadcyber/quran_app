import 'package:flutter/material.dart';
import 'juz_detail_screen.dart';

class JuzListScreen extends StatelessWidget {
  const JuzListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Browse by Juz',
            style: TextStyle(color: Colors.white70, fontSize: 18)),
      ),
      body: ListView.separated(
        itemCount: 30,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Colors.white12),
        itemBuilder: (context, index) {
          final juzNumber = index + 1;
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text('$juzNumber',
                  style: const TextStyle(
                      color: Color(0xFFD4AF37), fontSize: 14)),
            ),
            title: Text('Juz $juzNumber',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JuzDetailScreen(juzNumber: juzNumber),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
