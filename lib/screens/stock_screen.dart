
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// TODO: This class is duplicated from home_screen.dart. Move to a shared models file.
class StockedTask {
  final String id;
  final String title;
  final List<String> tags;

  StockedTask({
    required this.id,
    required this.title,
    required this.tags,
  });

  factory StockedTask.fromJson(Map<String, dynamic> json) {
    // The category is nested in the response for dummy data
    final categoryName = json['category'] != null ? json['category']['name'] as String : '未分類';
    return StockedTask(
      id: json['id'].toString(),
      title: json['title'] as String,
      tags: [categoryName], // Assuming tags come from the category name for now
    );
  }
}

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<StockedTask> _stockedTasks = [];

  @override
  void initState() {
    super.initState();
    _fetchStockedTasks();
  }

  Future<void> _fetchStockedTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse('http://localhost:8000/stock');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _stockedTasks = data.map((json) => StockedTask.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "ストックの取得に失敗しました (Code: ${response.statusCode})";
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

    final url = Uri.parse('http://localhost:8000/tasks/daily/replace');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({
      'new_task_id': int.parse(taskId),
      'source': 'stock',
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('今日のタスクを変更しました！ホーム画面で確認してください。'),
            backgroundColor: Colors.green,
          ),
        );
        // TODO: Switch to the home tab and trigger a refresh.
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('タスクの変更に失敗しました (Code: ${response.statusCode})'),
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
      child: ListView.builder(
        itemCount: _stockedTasks.length,
        itemBuilder: (context, index) {
          final task = _stockedTasks[index];
          return ListTile(
            title: Text(task.title),
            subtitle: Wrap(
              spacing: 6.0,
              children: task.tags.map((tag) => Chip(label: Text(tag))).toList(),
            ),
            trailing: TextButton(
              child: const Text('今日やる'),
              onPressed: () => _setAsDailyTask(task.id, task.title),
            ),
          );
        },
      ),
    );
  }
}
