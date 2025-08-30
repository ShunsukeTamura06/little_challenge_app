import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:little_challenge_app/models/my_task.dart';
import 'package:little_challenge_app/screens/my_task_editor_screen.dart';
import 'package:little_challenge_app/config/environment.dart';
import 'package:little_challenge_app/services/api_headers.dart';
import 'package:provider/provider.dart';
import '../models/task.dart' as model;
import '../providers/app_state_manager.dart';
import 'package:little_challenge_app/services/api_headers.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<MyTask> _myTasks = [];

  @override
  void initState() {
    super.initState();
    _fetchMyTasks();
  }

  Future<void> _fetchMyTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = '${Environment.apiBaseUrl}/my_tasks';
    try {
      final response = await http.get(Uri.parse(url), headers: await ApiHeaders.baseHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _myTasks = data.map((json) => MyTask.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "マイタスクの取得に失敗しました";
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

  Future<void> _deleteMyTask(int taskId) async {
    final url = '${Environment.apiBaseUrl}/my_tasks/$taskId';
    try {
      final response = await http.delete(Uri.parse(url), headers: await ApiHeaders.baseHeaders());
      if (response.statusCode == 204) {
        setState(() {
          _myTasks.removeWhere((task) => task.id == taskId);
        });
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('タスクの削除に失敗しました (Code: ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }

  Future<void> _stockMyTask(int taskId, String title) async {
    final url = Uri.parse('${Environment.apiBaseUrl}/stock');
    final headers = await ApiHeaders.jsonHeaders();
    final body = json.encode({'task_id': taskId});
    try {
      final response = await http.post(url, headers: headers, body: body);
      if (!mounted) return;
      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「$title」をストックに追加しました')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ストックに失敗しました (Code: ${response.statusCode})')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }

  Future<void> _setMyTaskAsDaily(int taskId, String title) async {
    final url = Uri.parse('${Environment.apiBaseUrl}/tasks/daily/replace');
    final headers = await ApiHeaders.jsonHeaders();
    final body = json.encode({'my_task_id': taskId, 'source': 'my_task'});
    try {
      final response = await http.post(url, headers: headers, body: body);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final newTask = model.Task.fromJson(data);
        Provider.of<AppStateManager>(context, listen: false).setDailyTask(newTask);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「$title」を今日のタスクに設定しました')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('設定に失敗しました (Code: ${response.statusCode})')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }

  Future<void> _navigateToEditor({MyTask? task}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => MyTaskEditorScreen(task: task),
        fullscreenDialog: true,
      ),
    );

    if (result == true) {
      _fetchMyTasks(); // Refresh the list if a task was saved
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('マイタスク'),
      ),
      body: _buildMainContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditor(),
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
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
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchMyTasks, child: const Text('再試行')),
          ],
        ),
      );
    }

    if (_myTasks.isEmpty) {
      return const Center(
        child: Text(
          'マイタスクはありません。\n+ボタンから追加しましょう！',
          textAlign: TextAlign.center,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMyTasks,
      child: ListView.builder(
        itemCount: _myTasks.length,
        itemBuilder: (context, index) {
          final task = _myTasks[index];
          return Dismissible(
            key: Key(task.id.toString()),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              _deleteMyTask(task.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('「${task.title}」を削除しました')),
              );
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: ListTile(
              title: Text(task.title),
              subtitle: Text('作成日: ${DateFormat('yyyy/MM/dd').format(task.createdAt)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'ストックに追加',
                    icon: const Icon(Icons.bookmark_add_outlined),
                    onPressed: () => _stockMyTask(task.id, task.title),
                  ),
                  IconButton(
                    tooltip: '今日やる',
                    icon: const Icon(Icons.today_outlined),
                    onPressed: () => _setMyTaskAsDaily(task.id, task.title),
                  ),
                  IconButton(
                    tooltip: '編集',
                    icon: const Icon(Icons.edit),
                    onPressed: () => _navigateToEditor(task: task),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
