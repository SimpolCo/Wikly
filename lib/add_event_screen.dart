import 'package:flutter/material.dart';

import 'event_repository.dart';
import 'models/event.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtl = TextEditingController();

  int _day = 0;
  TimeOfDay _from = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _to = TimeOfDay(hour: 10, minute: 0);

  final List<Color> _colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.brown,
  ];
  int _colorIndex = 0;

  Future<void> _pickFrom() async {
    final t = await showTimePicker(context: context, initialTime: _from);
    if (t != null) setState(() => _from = t);
  }

  Future<void> _pickTo() async {
    final t = await showTimePicker(context: context, initialTime: _to);
    if (t != null) setState(() => _to = t);
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final fromMin = _toMinutes(_from);
    final toMin = _toMinutes(_to);
    if (toMin <= fromMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final event = Event(
      title: _titleCtl.text.trim(),
      day: _day,
      startMinutes: fromMin,
      endMinutes: toMin,
      colorValue: _colors[_colorIndex].value,
    );

    await EventRepository.createEvent(event);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Scaffold(
      appBar: AppBar(title: const Text('Add Event')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            // <-- add this
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleCtl,
                  decoration: const InputDecoration(labelText: 'Event name'),
                  validator: (s) =>
                      (s == null || s.trim().isEmpty) ? 'Enter a title' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Day:'),
                    const SizedBox(width: 12),
                    DropdownButton<int>(
                      value: _day,
                      items: List.generate(
                        7,
                        (i) => DropdownMenuItem(value: i, child: Text(days[i])),
                      ),
                      onChanged: (v) => setState(() => _day = v ?? 0),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('From'),
                        subtitle: Text(_from.format(context)),
                        onTap: _pickFrom,
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('To'),
                        subtitle: Text(_to.format(context)),
                        onTap: _pickTo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Color:'),
                    const SizedBox(width: 12),
                    Wrap(
                      spacing: 8,
                      children: List.generate(_colors.length, (i) {
                        return GestureDetector(
                          onTap: () => setState(() => _colorIndex = i),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _colors[i],
                              border: _colorIndex == i
                                  ? Border.all(
                                      width: 3,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    )
                                  : null,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
