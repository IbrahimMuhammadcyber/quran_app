import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../services/audio_handler.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  IconData _repeatIcon(TilawahRepeatMode mode) {
    switch (mode) {
      case TilawahRepeatMode.off:
        return Icons.repeat;
      case TilawahRepeatMode.all:
        return Icons.repeat_on;
      case TilawahRepeatMode.one:
        return Icons.repeat_one_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final surah = player.currentSurah;
    if (surah == null) return const SizedBox.shrink();

    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final total = player.totalDuration ?? Duration.zero;
              final maxMs =
                  total.inMilliseconds > 0 ? total.inMilliseconds : 1;
              final value =
                  position.inMilliseconds.clamp(0, maxMs).toDouble();
              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 10),
                      activeTrackColor: Colors.amber,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.amber,
                    ),
                    child: Slider(
                      min: 0,
                      max: maxMs.toDouble(),
                      value: value,
                      onChanged: (v) {
                        player.seek(Duration(milliseconds: v.round()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_format(position),
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11)),
                        Text(_format(total),
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${surah.nameTransliteration} • ${surah.nameArabic}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(_repeatIcon(player.repeatMode),
                    color: player.repeatMode == TilawahRepeatMode.off
                        ? Colors.white38
                        : Colors.amber,
                    size: 20),
                onPressed: player.cycleRepeatMode,
              ),
              IconButton(
                icon: const Icon(Icons.replay_10,
                    color: Colors.white70, size: 22),
                onPressed: () =>
                    player.seekRelative(const Duration(seconds: -10)),
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.white70),
                onPressed: player.playPrevious,
              ),
              IconButton(
                icon: Icon(
                  player.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 36,
                ),
                onPressed: player.togglePlayPause,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white70),
                onPressed: player.playNext,
              ),
              IconButton(
                icon: const Icon(Icons.forward_10,
                    color: Colors.white70, size: 22),
                onPressed: () =>
                    player.seekRelative(const Duration(seconds: 10)),
              ),
              IconButton(
                icon: Icon(Icons.shuffle,
                    color:
                        player.shuffleEnabled ? Colors.amber : Colors.white38,
                    size: 20),
                onPressed: player.toggleShuffle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
