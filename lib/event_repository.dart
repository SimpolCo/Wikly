import 'dart:convert';
import 'package:hive/hive.dart';
import 'models/event.dart';

class EventRepository {
  static final Box<Event> _box = Hive.box<Event>('events');

  static Future<Event> createEvent(Event e) async {
    final id = await _box.add(e);
    e.id = id; // store Hive key as id
    await e.save();
    return e;
  }

  static List<Event> readAllEvents() {
    final events = _box.values.toList();
    events.sort((a, b) {
      final cmp = a.day.compareTo(b.day);
      return cmp != 0 ? cmp : a.startMinutes.compareTo(b.startMinutes);
    });
    return events;
  }

  static Future<void> deleteEvent(int key) async {
    await _box.delete(key);
  }

  /// Backup
  static Future<String> exportToJson() async {
    final maps = _box.values.map((e) => {
      'id': e.key, // Hive auto key
      'title': e.title,
      'day': e.day,
      'startMinutes': e.startMinutes,
      'endMinutes': e.endMinutes,
      'colorValue': e.colorValue,
    }).toList();
    return jsonEncode(maps);
  }

  /// Restore
  static Future<void> importFromJson(String jsonString) async {
    final decoded = jsonDecode(jsonString) as List;
    await _box.clear();
    for (final m in decoded) {
      await _box.add(Event(
        title: m['title'],
        day: m['day'],
        startMinutes: m['startMinutes'],
        endMinutes: m['endMinutes'],
        colorValue: m['colorValue'],
      ));
    }
  }
}
