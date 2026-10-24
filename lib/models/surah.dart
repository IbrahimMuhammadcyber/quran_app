class Surah {
  final int number;
  final String nameArabic;
  final String nameTransliteration;
  final String nameTranslation;
  final int totalVerses;
  final String revelationType; // "Meccan" or "Medinan"
  final String? audioUrl; // full surah audio, per reciter
  final Duration? duration;

  Surah({
    required this.number,
    required this.nameArabic,
    required this.nameTransliteration,
    required this.nameTranslation,
    required this.totalVerses,
    required this.revelationType,
    this.audioUrl,
    this.duration,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'],
      nameArabic: json['name'],
      nameTransliteration: json['englishName'],
      nameTranslation: json['englishNameTranslation'],
      totalVerses: json['numberOfAyahs'],
      revelationType: json['revelationType'],
    );
  }

  String get formattedDuration {
    if (duration == null) return '--:--';
    final m = duration!.inMinutes.toString().padLeft(2, '0');
    final s = (duration!.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
