import 'dart:io';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/task.dart';

class CalendarService {
  /// Adds the given [task] as an all-day event for today.
  /// Returns true if the event was added (or calendar UI was opened successfully), false otherwise.
  static Future<bool> addTaskToCalendar(Task task) async {
    // No runtime permission is required when launching the Calendar insert UI
    // (we're not directly writing to the calendar provider).
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
      if (result) return true;
      // If result is false on Android, try Google Calendar fallback.
      if (Platform.isAndroid) {
        final fallbackOk = await _openGoogleCalendarFallback(task, start, end, description);
        return fallbackOk;
      }
      return false;
    } catch (e) {
      // Print error for diagnostics (e.g., ActivityNotFoundException or permission issues)
      // ignore: avoid_print
      print('Add2Calendar error: $e');
      // Try fallback on Android even if exception occurs
      if (Platform.isAndroid) {
        final fallbackOk = await _openGoogleCalendarFallback(task, start, end, description);
        return fallbackOk;
      }
      return false;
    }
  }

  static Future<bool> _openGoogleCalendarFallback(
    Task task,
    DateTime start,
    DateTime end,
    String? description,
  ) async {
    try {
      // All-day "dates" format: YYYYMMDD/YYYYMMDD
      String fmt(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}'
              .trim();
      final dates = '${fmt(start)}/${fmt(end)}';
      final uri = Uri.parse(
          'https://calendar.google.com/calendar/render?action=TEMPLATE&text='
          '${Uri.encodeComponent(task.title)}'
          '&dates=${Uri.encodeComponent(dates)}'
          '${description != null ? '&details=${Uri.encodeComponent(description)}' : ''}');
      if (await canLaunchUrl(uri)) {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        return ok;
      }
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Google Calendar fallback error: $e');
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
