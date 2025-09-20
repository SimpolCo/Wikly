import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

import 'add_event_screen.dart';
import 'event_repository.dart';
import 'models/event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(EventAdapter());
  await Hive.openBox<Event>('events');

  runApp(const WiklyTimetableApp());
}

class WiklyTimetableApp extends StatelessWidget {
  const WiklyTimetableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wikly',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[50],
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          surface: Colors.black,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      home: const TimetableScreen(),
    );
  }
}

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  List<Event> _events = [];
  bool _loading = true;

  // Display range: 7:00 - 22:00
  final int displayStartHour = 7;
  final int displayEndHour = 22;

  // Grid sizing
  final double rowHeight = 80.0; // per hour
  final double dayColumnWidth = 120.0; // width per day column

  // Scroll controllers for synced scrolling
  final ScrollController _verticalController = ScrollController();
  final ScrollController _verticalController2 = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _horizontalController2 = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadEvents();

    // sync vertical scroll
    _verticalController.addListener(() {
      if (_verticalController2.offset != _verticalController.offset) {
        _verticalController2.jumpTo(_verticalController.offset);
      }
    });
    _verticalController2.addListener(() {
      if (_verticalController.offset != _verticalController2.offset) {
        _verticalController.jumpTo(_verticalController2.offset);
      }
    });

    // sync horizontal scroll
    _horizontalController.addListener(() {
      if (_horizontalController2.offset != _horizontalController.offset) {
        _horizontalController2.jumpTo(_horizontalController.offset);
      }
    });
    _horizontalController2.addListener(() {
      if (_horizontalController.offset != _horizontalController2.offset) {
        _horizontalController.jumpTo(_horizontalController2.offset);
      }
    });
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _verticalController2.dispose();
    _horizontalController.dispose();
    _horizontalController2.dispose();
    super.dispose();
  }

  Future<void> _backupData() async {
    final jsonString = await EventRepository.exportToJson();
    final directoryPath = await FilePicker.platform.getDirectoryPath();

    if (directoryPath != null) {
      final file = File('$directoryPath/timetable_backup.json');
      await file.writeAsString(jsonString);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Backup saved to ${file.path}')));
      }
    }
  }

  Future<void> _restoreData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      await EventRepository.importFromJson(jsonString);
      await _loadEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data restored successfully!')),
        );
      }
    }
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    final events = EventRepository.readAllEvents();
    setState(() {
      _events = events;
      _loading = false;
    });
  }

  Future<void> _openAddEvent() async {
    final created = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddEventScreen()));
    if (created == true) {
      await _loadEvents();
    }
  }

  // convert minutes since midnight to position
  double _topFor(int minutes) {
    final minutesFromStart = minutes - displayStartHour * 60;
    return minutesFromStart / 60.0 * rowHeight;
  }

  double _heightFor(int start, int end) {
    final durationMins = end - start;
    return durationMins / 60.0 * rowHeight;
  }

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hoursCount = displayEndHour - displayStartHour;
    final gridHeight = hoursCount * rowHeight;

    // group events by day
    final eventsByDay = List<List<Event>>.generate(7, (_) => []);
    for (final t in _events) {
      if (t.day >= 0 && t.day < 7) eventsByDay[t.day].add(t);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wikly'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'backup') {
                _backupData();
              } else if (value == 'restore') {
                _restoreData();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'backup', child: Text('Backup')),
              const PopupMenuItem(value: 'restore', child: Text('Restore')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔹 Top row: corner + day headers
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 40,
                      color: Theme.of(context).canvasColor,
                    ), // top-left corner
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(7, (d) {
                            return Container(
                              width: dayColumnWidth,
                              height: 40,
                              alignment: Alignment.center,
                              child: Text(
                                days[d],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Row(
                    children: [
                      // 🔹 Fixed left time labels
                      SingleChildScrollView(
                        controller: _verticalController,
                        scrollDirection: Axis.vertical,
                        child: Column(
                          children: List.generate(hoursCount, (i) {
                            final hour = displayStartHour + i;
                            return SizedBox(
                              width: 50,
                              height: rowHeight,
                              child: Center(
                                child: Text(
                                  '${hour.toString().padLeft(2, '0')}:00',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      // 🔹 Scrollable grid (events)
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _horizontalController2,
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            controller: _verticalController2,
                            scrollDirection: Axis.vertical,
                            child: SizedBox(
                              width: dayColumnWidth * 7,
                              height: gridHeight,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(7, (d) {
                                  return Container(
                                    width: dayColumnWidth,
                                    height: gridHeight,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          color: Theme.of(context).dividerColor,
                                        ),
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        // hour separators
                                        Column(
                                          children: List.generate(
                                            hoursCount,
                                            (i) => Container(
                                              width: double.infinity,
                                              height: rowHeight,
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  top: BorderSide(
                                                    color: Theme.of(context)
                                                        .dividerColor
                                                        .withOpacity(0.4),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // events
                                        ...eventsByDay[d].map((event) {
                                          final top = _topFor(
                                            event.startMinutes,
                                          ).clamp(0.0, gridHeight);
                                          final height = _heightFor(
                                            event.startMinutes,
                                            event.endMinutes,
                                          ).clamp(45.0, gridHeight - top);

                                          return Positioned(
                                            top: top,
                                            left: 4,
                                            right: 4,
                                            height: height,
                                            child: GestureDetector(
                                              onLongPress: () async {
                                                final ok = await showDialog<bool>(
                                                  context: context,
                                                  builder: (c) => AlertDialog(
                                                    title: Text(
                                                      'Delete "${event.title}"?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              c,
                                                              false,
                                                            ),
                                                        child: const Text(
                                                          'Cancel',
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              c,
                                                              true,
                                                            ),
                                                        child: const Text(
                                                          'Delete',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (ok == true &&
                                                    event.id != null) {
                                                  await EventRepository.deleteEvent(
                                                    event.id!,
                                                  );
                                                  await _loadEvents();
                                                }
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Color(
                                                    event.colorValue,
                                                  ).withOpacity(0.9),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      event.title,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      event.timeRangeString(),
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddEvent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
