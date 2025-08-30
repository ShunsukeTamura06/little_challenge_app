import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_manager.dart';
import 'package:little_challenge_app/config/environment.dart';
import 'package:little_challenge_app/services/api_headers.dart';
import 'achievement_report_screen.dart';
import 'challenge_detail_screen.dart';
import '../models/task.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isStocking = false; // Flag for stock animation

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ja_JP', null);
    // Post-frame callback to access provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppStateManager>(context, listen: false);
      if (appState.dailyTask == null) {
        _fetchDailyTask();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchDailyTask({bool forceRefresh = false}) async {
    final appState = Provider.of<AppStateManager>(context, listen: false);
    if (forceRefresh) {
      appState.clearDailyTask();
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse('${Environment.apiBaseUrl}/tasks/daily?force_refresh=$forceRefresh');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        appState.setDailyTask(Task.fromJson(data));
      } else {
        setState(() {
          _errorMessage = "タスクの取得に失敗しました (Code: ${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "エラーが発生しました: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onAchieveTapped() {
    final task = Provider.of<AppStateManager>(context, listen: false).dailyTask;
    if (task == null) return;

    // Navigate immediately to achievement report screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AchievementReportScreen(
          taskId: task.id,
          showUndoOption: true,
        ),
        fullscreenDialog: true,
      ),
    ).then((result) {
      if (result != 'cancelled') {
        _fetchDailyTask(forceRefresh: true);
      }
    });
  }


  Future<void> _onStockItTapped() async {
    final appState = Provider.of<AppStateManager>(context, listen: false);
    final task = appState.dailyTask;
    if (task == null || _isStocking) return;

    final url = Uri.parse('${Environment.apiBaseUrl}/stock');
    final headers = await ApiHeaders.jsonHeaders();
    final body = json.encode({'task_id': task.id});

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ストックに追加しました'),
            backgroundColor: Colors.teal,
            duration: Duration(seconds: 2),
          ),
        );
        
        setState(() {
          _isStocking = true;
        });

        await Future.delayed(const Duration(milliseconds: 300));
        await _fetchDailyTask(forceRefresh: true);

        if (mounted) {
          setState(() {
            _isStocking = false;
          });
        }

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ストックの追加に失敗しました (Code: ${response.statusCode})'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
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
    final appState = Provider.of<AppStateManager>(context);
    final task = appState.dailyTask;

    if (_isLoading && task == null) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
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
    } else if (task == null) {
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
    } else {
      return _buildTaskView(context, task);
    }
  }

  Widget _buildTaskView(BuildContext context, Task task) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Hide the main task view when stocking
    return AnimatedOpacity(
      opacity: _isStocking ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Dismissible(
              key: ValueKey(task.id),
              onDismissed: (direction) {
                _fetchDailyTask(forceRefresh: true);
              },
              background: Container(
                color: Colors.transparent, // Make background transparent
              ),
              secondaryBackground: Container(
                color: Colors.transparent,
              ),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChallengeDetailScreen(
                        task: task, 
                        isFromHome: true,
                      ),
                    ),
                  );
                },
                child: Card(
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
                              .map((tag) => Chip(label: Text(tag, style: textTheme.bodyMedium)))
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_alt_outlined, color: textTheme.bodyMedium?.color),
                            const SizedBox(width: 8),
                            Text(
                              "全ユーザーの${((task.completionRate ?? 0.0) * 100).toStringAsFixed(0)}%が達成",
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: task.source == 'my' ? null : _onAchieveTapped,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('達成！', style: textTheme.labelLarge),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _onStockItTapped,
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
      ),
    );
  }

}
