import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class MyTask {
  final int id;
  final String title;
  final DateTime createdAt;

  MyTask({required this.id, required this.title, required this.createdAt});

  factory MyTask.fromJson(Map<String, dynamic> json) {
    return MyTask(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

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

    const url = 'http://localhost:8000/my_tasks';
    try {
      final response = await http.get(Uri.parse(url));
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
    final url = 'http://localhost:8000/my_tasks/$taskId';
    try {
      final response = await http.delete(Uri.parse(url));
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

  void _showAddTaskDialog() {
    // TODO: Implement a proper editor screen [SCR-009]
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新しいマイタスク'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'タスク名'),
          ),
          actions: [
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('追加'),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  _addMyTask(controller.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addMyTask(String title) async {
    const url = 'http://localhost:8000/my_tasks';
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({'title': title});

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 201) {
        // Refresh the list to show the new task
        _fetchMyTasks();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('タスクの追加に失敗しました (Code: ${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
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
        onPressed: _showAddTaskDialog,
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
              // TODO: Add an edit button
            ),
          );
        },
      ),
    );
  }
}