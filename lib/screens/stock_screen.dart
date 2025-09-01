
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/app_state_manager.dart';
import 'challenge_detail_screen.dart';
import 'package:little_challenge_app/config/environment.dart';
import 'package:little_challenge_app/services/api_headers.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Task> _stockedTasks = [];
  int _lastSeenRefreshCounter = 0;

  @override
  void initState() {
    super.initState();
    _fetchStockedTasks();
    // Listen to app state changes to refresh when requested
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppStateManager>(context, listen: false);
      _lastSeenRefreshCounter = appState.stockRefreshCounter;
      appState.addListener(_onAppStateChanged);
    });
  }

  void _onAppStateChanged() {
    final appState = Provider.of<AppStateManager>(context, listen: false);
    if (appState.selectedIndex == 2 && appState.stockRefreshCounter != _lastSeenRefreshCounter) {
      _lastSeenRefreshCounter = appState.stockRefreshCounter;
      _fetchStockedTasks();
    }
  }

  @override
  void dispose() {
    try {
      Provider.of<AppStateManager>(context, listen: false).removeListener(_onAppStateChanged);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _fetchStockedTasks() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse('${Environment.apiBaseUrl}/stock');

    try {
      final response = await http
          .get(url, headers: await ApiHeaders.baseHeaders())
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _stockedTasks = data.map((json) => Task.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "ストックの取得に失敗しました (Code: ${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "エラーが発生しました: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _setAsDailyTask(String taskId, String taskTitle) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('タスクの変更'),
          content: Text('「$taskTitle」を今日のタスクに設定しますか？'),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('はい'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final url = Uri.parse('${Environment.apiBaseUrl}/tasks/daily/replace');
    final headers = await ApiHeaders.jsonHeaders();
    final Task t = _stockedTasks.firstWhere((e) => e.id == taskId, orElse: () => Task(id: taskId, title: taskTitle, tags: []));
    final bool isMy = (t.source == 'my');
    // Prefer my_task_id for newer backend; will fallback to new_task_id if needed
    final bodyMy = isMy
        ? json.encode({
            'my_task_id': int.tryParse(t.id),
            'source': 'stock_my',
          })
        : null;
    final bodyNew = json.encode({
      'new_task_id': taskId,
      'source': isMy ? 'stock_my' : 'stock',
    });

    try {
      http.Response response;
      if (isMy && bodyMy != null) {
        response = await http.post(url, headers: headers, body: bodyMy);
        if (response.statusCode == 422 || response.statusCode == 400) {
          // Fallback for Render backend that expects new_task_id as string
          response = await http.post(url, headers: headers, body: bodyNew);
        }
      } else {
        response = await http.post(url, headers: headers, body: bodyNew);
      }

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Update the daily task in the app state
        final data = json.decode(utf8.decode(response.bodyBytes));
        final newTask = Task.fromJson(data);
        Provider.of<AppStateManager>(context, listen: false).setDailyTask(newTask);
        
        // Remove the task from local stock list
        setState(() {
          _stockedTasks.removeWhere((task) => task.id == taskId);
        });
        
        // Delete the task from stock in the backend (silently)
        try {
          final deleteUrl = Uri.parse('${Environment.apiBaseUrl}/stock/by-task/${t.id}');
          await http.delete(deleteUrl, headers: await ApiHeaders.baseHeaders());
        } catch (e) {
          // Ignore deletion errors since the main action (setting daily task) succeeded
          // In production, use a proper logging framework instead of print
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('今日のタスクを変更しました！'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Switch to the home tab
          Provider.of<AppStateManager>(context, listen: false).goToTab(0);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('タスクの変更に失敗しました (Code: ${response.statusCode})'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteStockedTask(String taskId) async {
    final int taskIndex = _stockedTasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;

    final Task taskToDelete = _stockedTasks[taskIndex];

    // Optimistically remove from UI
    setState(() {
      _stockedTasks.removeAt(taskIndex);
    });

    final Task t = taskToDelete;
    final url = Uri.parse('${Environment.apiBaseUrl}/stock/by-task/${t.id}');

    try {
      final response = await http.delete(url, headers: await ApiHeaders.baseHeaders());

      if (!mounted) return;

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('タスクを削除しました'),
            action: SnackBarAction(
              label: '元に戻す',
              onPressed: () {
                _undoDelete(taskToDelete, taskIndex);
              },
            ),
          ),
        );
      } else {
        // If deletion fails, add the task back to the list and show error
        setState(() {
          _stockedTasks.insert(taskIndex, taskToDelete);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('削除に失敗しました (Code: ${response.statusCode})'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      // If an error occurs, add the task back and show error
      setState(() {
        _stockedTasks.insert(taskIndex, taskToDelete);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _undoDelete(Task task, int index) async {
    // Re-add to the backend
    final url = Uri.parse('${Environment.apiBaseUrl}/stock');
    final headers = await ApiHeaders.jsonHeaders();
    final int? taskId = int.tryParse(task.id);
    final bodyInt = json.encode({'task_id': taskId});
    final bodyStr = json.encode({'task_id': task.id});

    try {
      http.Response response = await http.post(url, headers: headers, body: bodyInt);
      if (response.statusCode == 422 || response.statusCode == 400) {
        response = await http.post(url, headers: headers, body: bodyStr);
      }

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Add back to the local list at the original position
        setState(() {
          _stockedTasks.insert(index, task);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('タスクを元に戻しました'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // If re-adding fails, show an error. The user might need to refresh.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('元に戻せませんでした (Code: ${response.statusCode})'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('ストック'),
      ),
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
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
              onPressed: _fetchStockedTasks,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (_stockedTasks.isEmpty) {
      return const Center(
        child: Text(
          'ストックされているタスクはありません。',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchStockedTasks,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton(
              onPressed: _proposeRandomTask,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48), // make button wider
              ),
              child: const Text('ストックからランダムに提案'),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _stockedTasks.length,
              itemBuilder: (context, index) {
                final task = _stockedTasks[index];
                return Dismissible(
                  key: ValueKey(task.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _deleteStockedTask(task.id);
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    title: Text(task.title),
                    subtitle: Wrap(
                      spacing: 6.0,
                      children: task.tags.map((tag) => Chip(label: Text(tag))).toList(),
                    ),
                    trailing: TextButton(
                      child: const Text('今日やる'),
                      onPressed: () => _setAsDailyTask(task.id, task.title),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChallengeDetailScreen(task: task, isFromStock: true),
                        ),
                      ).then((_) {
                        // Refresh stock list when returning from detail screen
                        _fetchStockedTasks();
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _proposeRandomTask() {
    if (_stockedTasks.isEmpty) return;
    final randomTask = _stockedTasks[Random().nextInt(_stockedTasks.length)];
    _setAsDailyTask(randomTask.id, randomTask.title);
  }
}
