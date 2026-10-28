import 'prayer_times_screen.dart';
import 'package:flutter/material.dart';
import 'surah_list_screen.dart';
import 'read_surah_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.4,
            colors: [
              Color(0xFF1C1810),
              Color(0xFF0D0D0D),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFD4AF37), Color(0xFF8A6D1F)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🕋', style: TextStyle(fontSize: 48)),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Tilawah',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'القرآن الكريم',
                  style: TextStyle(
                    color: const Color(0xFFD4AF37).withOpacity(0.85),
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Listen and reflect',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(flex: 4),
                _HomeActionButton(
                  icon: Icons.headphones_rounded,
                  label: 'Listen',
                  subtitle: 'Recitation by your favorite reciters',
                  isPrimary: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SurahListScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _HomeActionButton(
                  icon: Icons.menu_book_rounded,
                  label: 'Read Quran',
                  subtitle: 'Arabic text with translation',
                  isPrimary: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ReadSurahListScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PrayerTimesScreen()),
                    );
                  },
                  icon: const Icon(Icons.access_time,
                      color: Colors.white38, size: 18),
                  label: const Text('Prayer Times',
                      style: TextStyle(color: Colors.white38)),
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isPrimary;
  final VoidCallback onTap;

  const _HomeActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: isPrimary
                ? const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFB8933A)],
                  )
                : null,
            color: isPrimary ? null : const Color(0xFF1A1A1A),
            border: isPrimary
                ? null
                : Border.all(color: Colors.white24, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: isPrimary ? Colors.black87 : const Color(0xFFD4AF37),
                  size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isPrimary ? Colors.black87 : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isPrimary
                            ? Colors.black54
                            : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isPrimary ? Colors.black54 : Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}
