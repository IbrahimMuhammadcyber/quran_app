import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../theme/app_colors.dart';
import 'juz_detail_screen.dart';

class JuzListScreen extends StatelessWidget {
  const JuzListScreen({super.key});

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
        title: Text('Browse by Juz',
            style: TextStyle(color: colors.textSecondary, fontSize: 18)),
      ),
      body: ListView.separated(
        itemCount: 30,
        separatorBuilder: (_, __) => Divider(height: 1, color: colors.divider),
        itemBuilder: (context, index) {
          final juzNumber = index + 1;
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text('$juzNumber',
                  style: TextStyle(color: colors.accent, fontSize: 14)),
            ),
            title: Text('Juz $juzNumber',
                style: TextStyle(color: colors.textPrimary, fontSize: 16)),
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
