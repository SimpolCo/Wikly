import 'package:hive/hive.dart';

part 'event.g.dart'; // generated adapter will live here

@HiveType(typeId: 0) // unique typeId per model
class Event extends HiveObject {
  @HiveField(0)
  int? id; // optional, Hive already assigns a key

  @HiveField(1)
  String title;

  @HiveField(2)
  int day;

  @HiveField(3)
  int startMinutes;

  @HiveField(4)
  int endMinutes;

  @HiveField(5)
  int colorValue;

  Event({
    this.id,
    required this.title,
    required this.day,
    required this.startMinutes,
    required this.endMinutes,
    required this.colorValue,
  });

  String timeRangeString() {
    String two(int n) => n.toString().padLeft(2, '0');
    final sh = startMinutes ~/ 60;
    final sm = startMinutes % 60;
    final eh = endMinutes ~/ 60;
    final em = endMinutes % 60;
    return "${two(sh)}:${two(sm)} - ${two(eh)}:${two(em)}";
  }
}
