import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../services/prayer_service.dart';
import '../services/location_service.dart';
import '../services/theme_service.dart';
import '../theme/app_colors.dart';

class Reciter {
  final String id;
  final String name;
  final Color color;
  const Reciter(this.id, this.name, this.color);
}

const List<Reciter> reciters = [
  Reciter('ar.alafasy', 'Mishary Rashid Alafasy', Colors.teal),
  Reciter('ar.abdulbasitmurattal', 'Abdul Basit (Murattal)', Colors.indigo),
  Reciter('ar.minshawi', 'Mohamed Siddiq El-Minshawi', Colors.deepOrange),
  Reciter('ar.abdurrahmaansudais', 'Abdur-Rahman As-Sudais', Colors.green),
  Reciter('ar.shaatree', 'Abu Bakr Ash-Shaatree', Colors.purple),
  Reciter('ar.saoodshuraym', 'Saood Ash-Shuraym', Colors.brown),
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PrayerService _prayerService = PrayerService();
  final LocationService _locationService = LocationService();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  bool _prayerEnabled = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _loadPrayerSettings();
  }

  Future<void> _loadPrayerSettings() async {
    final loc = await _prayerService.getLocation();
    final enabled = await _prayerService.isEnabled();
    if (loc != null) {
      _latController.text = loc['lat'].toString();
      _lngController.text = loc['lng'].toString();
    }
    if (mounted) setState(() => _prayerEnabled = enabled);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final position = await _locationService.getCurrentLocation();
      setState(() {
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _savePrayerSettings(bool enabled) async {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid latitude and longitude')),
      );
      return;
    }
    try {
      await _prayerService.saveLocation(lat, lng);
      await _prayerService.setEnabled(enabled);
      setState(() => _prayerEnabled = enabled);

      if (enabled) {
        await _prayerService.requestPermission();
        await _prayerService.scheduleTodayNotifications(lat, lng);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prayer notification settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not schedule notifications: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final isDark = context.watch<ThemeService>().isDarkMode;
    final colors = AppColors(isDark);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text('Settings', style: TextStyle(color: colors.textPrimary)),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('Reciter',
                style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
          ...reciters.map((r) => RadioListTile<String>(
                value: r.id,
                groupValue: player.reciter,
                activeColor: colors.accent,
                secondary: CircleAvatar(
                  backgroundColor: r.color,
                  child: Text(r.name[0],
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                title: Text(r.name,
                    style: TextStyle(color: colors.textPrimary)),
                onChanged: (value) {
                  if (value != null) player.setReciter(value);
                },
              )),
          Divider(color: colors.divider, height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Prayer Notifications',
                style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _locating ? null : _useCurrentLocation,
                  icon: _locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                      _locating ? 'Locating...' : 'Use my current location'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: Colors.black),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _latController,
                  style: TextStyle(color: colors.textPrimary),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  decoration: InputDecoration(
                    labelText: 'Latitude',
                    labelStyle: TextStyle(color: colors.textMuted),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: colors.divider)),
                  ),
                ),
                TextField(
                  controller: _lngController,
                  style: TextStyle(color: colors.textPrimary),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  decoration: InputDecoration(
                    labelText: 'Longitude',
                    labelStyle: TextStyle(color: colors.textMuted),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: colors.divider)),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  activeColor: colors.accent,
                  title: Text('Enable prayer notifications',
                      style: TextStyle(color: colors.textPrimary)),
                  value: _prayerEnabled,
                  onChanged: _savePrayerSettings,
                ),
              ],
            ),
          ),
          Divider(color: colors.divider, height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Appearance',
                style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
          Consumer<ThemeService>(
            builder: (context, themeService, _) {
              return SwitchListTile(
                activeColor: colors.accent,
                title: Text('Dark mode',
                    style: TextStyle(color: colors.textPrimary)),
                value: themeService.isDarkMode,
                onChanged: (value) => themeService.toggle(value),
              );
            },
          ),
          Divider(color: colors.divider, height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('About the Developer',
                style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
          _InfoTile(
              label: 'Name', value: 'Ibrahim Muhammad Ikara', colors: colors),
          _InfoTile(
              label: 'Email',
              value: 'muhammadibrahimikara@gmail.com',
              colors: colors),
          _InfoTile(label: 'Country', value: 'Nigeria', colors: colors),
          _InfoTile(label: 'Phone', value: '09033874402', colors: colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final AppColors colors;
  const _InfoTile(
      {required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: TextStyle(color: colors.textFaint, fontSize: 13)),
      subtitle:
          Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16)),
    );
  }
}
