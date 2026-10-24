import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';

class Reciter {
  final String id;
  final String name;
  const Reciter(this.id, this.name);
}

const List<Reciter> reciters = [
  Reciter('ar.alafasy', 'Mishary Rashid Alafasy'),
  Reciter('ar.abdulbasitmurattal', 'Abdul Basit (Murattal)'),
  Reciter('ar.husary', 'Mahmoud Khalil Al-Husary'),
  Reciter('ar.minshawi', 'Mohamed Siddiq El-Minshawi'),
  Reciter('ar.abdurrahmaansudais', 'Abdur-Rahman As-Sudais'),
  Reciter('ar.shaatree', 'Abu Bakr Ash-Shaatree'),
];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text('Reciter',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
          ...reciters.map((r) => RadioListTile<String>(
                value: r.id,
                groupValue: player.reciter,
                activeColor: Colors.amber,
                title: Text(r.name,
                    style: const TextStyle(color: Colors.white)),
                onChanged: (value) {
                  if (value != null) player.setReciter(value);
                },
              )),
          const Divider(color: Colors.white12, height: 32),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('About the Developer',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
          const _InfoTile(label: 'Name', value: 'Ibrahim Muhammad Ikara'),
          const _InfoTile(
              label: 'Email', value: 'muhammadibrahimikara@gmail.com'),
          const _InfoTile(label: 'Country', value: 'Nigeria'),
          const _InfoTile(label: 'Phone', value: '09033874402'),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label,
          style: const TextStyle(color: Colors.white38, fontSize: 13)),
      subtitle: Text(value,
          style: const TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}
