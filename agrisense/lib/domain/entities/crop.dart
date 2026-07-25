/// Pure domain entity — no Flutter or Firebase dependencies.
class Crop {
  final String id;
  final String name;
  final String kinyarwanda;
  final String emoji;

  const Crop({
    required this.id,
    required this.name,
    required this.kinyarwanda,
    required this.emoji,
  });
}
