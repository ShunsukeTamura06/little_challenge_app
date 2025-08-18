import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'achievement_report_screen.dart';

// A simple data class for the daily task
class DailyTask {
  final String id;
  final String title;
  final List<String> tags;
  final double completionRate;

  DailyTask({
    required this.id,
    required this.title,
    required this.tags,
    required this.completionRate,
  });

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      id: json['id'] as String,
      title: json['title'] as String,
      tags: List<String>.from(json['tags'] as List),
      completionRate: (json['stats']['completion_rate'] as num).toDouble(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State for API data
  bool _isLoading = true;
  String? _errorMessage;
  DailyTask? _task;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ja_JP', null);
    _fetchDailyTask();
  }

  Future<void> _fetchDailyTask({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse('http://localhost:8000/tasks/daily?force_refresh=$forceRefresh');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _task = DailyTask.fromJson(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "タスクの取得に失敗しました (Code: ${response.statusCode})";
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

  void _onAchieveTapped() {
    // TODO: Here you would typically update the state on the server first.

    // Navigate to the report screen immediately
    final navigator = Navigator.of(context);
    navigator.push(
      MaterialPageRoute(
        builder: (context) => const AchievementReportScreen(),
      ),
    );

    // Show a SnackBar with an Undo action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🎉達成しました！'),
        action: SnackBarAction(
          label: '元に戻す',
          onPressed: () {
            // This will pop the AchievementReportScreen
            if (navigator.canPop()) {
              navigator.pop();
            }
            // TODO: Here you would send a request to the server to undo the achievement.
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String formattedDate = DateFormat('M月d日', 'ja_JP').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(formattedDate),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () { /* TODO: Navigate to Settings Screen */ },
          ),
        ],
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _buildMainContent(context),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchDailyTask(),
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (_task == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("今日のタスクはありませんでした。", textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchDailyTask(),
              child: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }

    return _buildTaskView(context, _task!); // Task view is built here
  }

  Widget _buildTaskView(BuildContext context, DailyTask task) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: theme.colorScheme.surface,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    task.title,
                    style: textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    alignment: WrapAlignment.center,
                    children: task.tags
                        .map((tag) => Chip(label: Text(tag, style: textTheme.bodyMedium))))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_alt_outlined, color: textTheme.bodyMedium?.color),
                      const SizedBox(width: 8),
                      Text(
                        "全ユーザーの${(task.completionRate * 100).toStringAsFixed(0)}%が達成",
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _onAchieveTapped,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('達成！', style: textTheme.labelLarge),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () { /* TODO: Handle 'あとでやる' */ },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('あとでやる', style: TextStyle(color: theme.primaryColor)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _fetchDailyTask(forceRefresh: true),
            child: Text(
              '他の提案を見る',
              style: TextStyle(color: textTheme.bodyMedium?.color, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}
