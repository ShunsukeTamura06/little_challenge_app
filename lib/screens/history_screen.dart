import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';
import 'package:little_challenge_app/config/environment.dart';
import 'package:little_challenge_app/services/api_headers.dart';

// A model for the log entry, adapted from the backend response
import 'package:little_challenge_app/screens/challenge_detail_screen.dart';

class LogEntry {
  final String id;
  final Task challenge;
  final String? memo;
  final String? feeling;
  final DateTime createdAt; // We need a date for the calendar

  LogEntry({
    required this.id,
    required this.challenge,
    this.memo,
    this.feeling,
    required this.createdAt,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'],
      challenge: Task.fromJson(json['challenge']),
      memo: json['memo'],
      feeling: json['feeling'],
      createdAt: DateTime.parse(json['achieved_at'] as String),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final ValueNotifier<List<LogEntry>> _selectedEvents;
  Map<DateTime, List<LogEntry>> _logsByDate = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]);
    _fetchLogsForMonth(_focusedDay);
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<LogEntry> _getEventsForDay(DateTime day) {
    // Normalize to UTC date to match the map keys
    final dayUtc = DateTime.utc(day.year, day.month, day.day);
    return _logsByDate[dayUtc] ?? [];
  }

  Future<void> _fetchLogsForMonth(DateTime month) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final monthFormat = DateFormat('yyyy-MM');
    final formattedMonth = monthFormat.format(month);
    final url = Uri.parse('${Environment.apiBaseUrl}/logs?month=$formattedMonth');

    try {
      final response = await http.get(Uri.parse(url.toString()), headers: await ApiHeaders.baseHeaders());
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        
        final Map<DateTime, List<LogEntry>> groupedLogs = {};
        data.forEach((dateString, logsJson) {
          final date = DateTime.parse(dateString);
          final dayUtc = DateTime.utc(date.year, date.month, date.day);
          final entries = (logsJson as List).map((item) => LogEntry.fromJson(item)).toList();
          groupedLogs[dayUtc] = entries;
        });

        setState(() {
          _logsByDate.addAll(groupedLogs); // Merge with existing data
          _isLoading = false;
          _selectedEvents.value = _getEventsForDay(_selectedDay!);
        });
      } else {
        setState(() {
          _errorMessage = "ログの取得に失敗しました";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "エラーが発生しました: $e";
        _isLoading = false;
      });
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents.value = _getEventsForDay(selectedDay);
      });
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    // Check if we already have data for the new month to avoid redundant API calls
    final firstDayOfMonth = DateTime.utc(focusedDay.year, focusedDay.month, 1);
    if (!_logsByDate.keys.any((d) => d.year == firstDayOfMonth.year && d.month == firstDayOfMonth.month)) {
       _fetchLogsForMonth(focusedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ログ'),
      ),
      body: _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _fetchLogsForMonth(_focusedDay),
                    child: const Text('再試行'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _fetchLogsForMonth(_focusedDay),
              child: Column(
                children: [
                  _buildSummaryPanel(),
                  if (_isLoading && _logsByDate.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  TableCalendar<LogEntry>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: _onDaySelected,
                    onPageChanged: _onPageChanged,
                    eventLoader: _getEventsForDay,
                    calendarStyle: const CalendarStyle(
                      markerDecoration: BoxDecoration(
                        color: Colors.teal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Expanded(
                    child: ValueListenableBuilder<List<LogEntry>>(
                      valueListenable: _selectedEvents,
                      builder: (context, value, _) {
                        if (value.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_note, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'この日の記録はありません',
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: value.length,
                          itemBuilder: (context, index) {
                            final log = value[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      log.feeling ?? '📝',
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                                title: Text(log.challenge.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (log.memo != null && log.memo!.isNotEmpty)
                                      Text(log.memo!, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('HH:mm').format(log.createdAt.toLocal()),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ChallengeDetailScreen(task: log.challenge),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  int _calculateStreak() {
    if (_logsByDate.isEmpty) return 0;

    final today = DateTime.now();
    final todayUtc = DateTime.utc(today.year, today.month, today.day);
    
    int streak = 0;
    DateTime checkDate = todayUtc;

    // Count backwards from today until we find a day without achievements
    while (true) {
      if (_logsByDate.containsKey(checkDate) && _logsByDate[checkDate]!.isNotEmpty) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  Widget _buildSummaryPanel() {
    final totalAchievements = _logsByDate.values.expand((i) => i).length;
    final streak = _calculateStreak(); 

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text('合計達成数', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text('$totalAchievements', style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
          Column(
            children: [
              Text('連続記録', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text('$streak日', style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ],
      ),
    );
  }
}
