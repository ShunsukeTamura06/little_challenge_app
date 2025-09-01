import 'package:add_2_calendar/add_2_calendar.dart';
import '../models/task.dart';

class CalendarService {
  /// Adds the given [task] as an all-day event for today.
  /// Returns true if the event was added (or calendar UI was opened successfully), false otherwise.
  static Future<bool> addTaskToCalendar(Task task) async {
    final now = DateTime.now();
    // All-day event for today
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final description = _buildDescription(task);

    final event = Event(
      title: task.title,
      description: description,
      startDate: start,
      endDate: end,
      allDay: true,
    );

    try {
      final result = await Add2Calendar.addEvent2Cal(event);
      return result;
    } catch (_) {
      return false;
    }
  }

  static String? _buildDescription(Task task) {
    final buffer = StringBuffer();
    if (task.description != null && task.description!.trim().isNotEmpty) {
      buffer.writeln(task.description!.trim());
      buffer.writeln();
    }
    if (task.tags.isNotEmpty) {
      buffer.writeln('タグ: ${task.tags.join(', ')}');
    }
    return buffer.isEmpty ? null : buffer.toString();
  }
}

