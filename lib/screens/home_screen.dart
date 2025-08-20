import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_manager.dart';
import 'achievement_report_screen.dart';
import '../models/task.dart';

import 'package:little_challenge_app/providers/app_state_manager.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  bool _showUndoPanel = false;
  Timer? _undoTimer;

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
    _undoTimer?.cancel();
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

    final url = Uri.parse('http://localhost:8000/tasks/daily?force_refresh=$forceRefresh');

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

    setState(() {
      _showUndoPanel = true;
    });

    _undoTimer?.cancel();
    _undoTimer = Timer(const Duration(seconds: 5), () {
      _triggerAchievementFlow();
    });
  }

  void _triggerAchievementFlow() {
    if (!_showUndoPanel || !mounted) return;
    final task = Provider.of<AppStateManager>(context, listen: false).dailyTask;

    setState(() {
      _showUndoPanel = false;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AchievementReportScreen(taskId: task!.id),
        fullscreenDialog: true,
      ),
    ).then((_) {
      _fetchDailyTask(forceRefresh: true);
    });
  }

  void _cancelAchievement() {
    _undoTimer?.cancel();
    setState(() {
      _showUndoPanel = false;
    });
  }

  Future<void> _onStockItTapped() async {
    final task = Provider.of<AppStateManager>(context, listen: false).dailyTask;
    if (task == null) return;

    final url = Uri.parse('http://localhost:8000/stock');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({'task_id': int.parse(task.id)});

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ストックに追加しました'),
            backgroundColor: Colors.teal,
          ),
        );
        await _fetchDailyTask(forceRefresh: true);
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

    return Stack(
      children: [
        if (_isLoading && task == null)
          const Center(child: CircularProgressIndicator())
        else if (_errorMessage != null)
          Center(
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
          )
        else if (task == null)
          Center(
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
          )
        else
          _buildTaskView(context, task),
        
        // Undo Panel
        if (_showUndoPanel)
          _buildUndoPanel(context),
      ],
    );
  }

  Widget _buildTaskView(BuildContext context, Task task) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Hide the main task view when the undo panel is shown
    return AnimatedOpacity(
      opacity: _showUndoPanel ? 0.0 : 1.0,
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
                            "全ユーザーの${(task.completionRate! * 100).toStringAsFixed(0)}%が達成",
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      )
                    ],
                  ),
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

  Widget _buildUndoPanel(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50), // System Success Green
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Text('🎉達成しました！', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: _cancelAchievement,
                child: const Text('取り消す', style: TextStyle(color: Colors.white, decoration: TextDecoration.underline)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}