import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/prayer_service.dart';
import '../services/theme_service.dart';
import '../theme/app_colors.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  final PrayerService _prayerService = PrayerService();
  Map<String, DateTime>? _times;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final loc = await _prayerService.getLocation();
    if (loc == null) {
      setState(() {
        _error =
            'No location saved yet. Go to Settings and tap "Use my current location" first.';
        _loading = false;
      });
      return;
    }
    final times = _prayerService.todayTimes(loc['lat']!, loc['lng']!);
    if (times == null) {
      setState(() {
        _error = 'Could not calculate prayer times.';
        _loading = false;
      });
      return;
    }
    setState(() {
      _times = {
        'Fajr': times.fajr,
        'Dhuhr': times.dhuhr,
        'Asr': times.asr,
        'Maghrib': times.maghrib,
        'Isha': times.isha,
      };
      _loading = false;
    });
  }

  String _formatTime(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
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
        title: Text('Prayer Times',
            style: TextStyle(color: colors.textSecondary, fontSize: 18)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.textSecondary)),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _times!.entries
                      .map((e) => Card(
                            color: colors.surface,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading:
                                  Icon(Icons.access_time, color: colors.accent),
                              title: Text(e.key,
                                  style: TextStyle(
                                      color: colors.textPrimary, fontSize: 16)),
                              trailing: Text(_formatTime(e.value),
                                  style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 15)),
                            ),
                          ))
                      .toList(),
                ),
    );
  }
}
