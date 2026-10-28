import 'package:flutter/material.dart';
import '../services/prayer_service.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Prayer Times',
            style: TextStyle(color: Colors.white70, fontSize: 18)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70)),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _times!.entries
                      .map((e) => Card(
                            color: const Color(0xFF1A1A1A),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(Icons.access_time,
                                  color: Color(0xFFD4AF37)),
                              title: Text(e.key,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16)),
                              trailing: Text(_formatTime(e.value),
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 15)),
                            ),
                          ))
                      .toList(),
                ),
    );
  }
}
