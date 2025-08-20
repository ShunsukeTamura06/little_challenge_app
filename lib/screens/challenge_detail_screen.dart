import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/app_state_manager.dart';

class ChallengeDetailScreen extends StatelessWidget {
  final Task task;

  const ChallengeDetailScreen({super.key, required this.task});

  Future<void> _setAsDailyTask(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('タスクの変更'),
          content: Text('「${task.title}」を今日のタスクに設定しますか？'),
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
      'new_task_id': int.parse(task.id),
      'source': 'detail', // or another identifier
    });

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);

      if (!context.mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('今日のタスクを変更しました！'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Switch to the home tab and pop the detail screen
        Provider.of<AppStateManager>(context, listen: false).goToTab(0);
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('タスクの変更に失敗しました (Code: ${response.statusCode})'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
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
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('タスクの詳細'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    if (task.tags.isNotEmpty)
                      Wrap(
                        spacing: 8.0,
                        children: task.tags.map((tag) => Chip(label: Text(tag))).toList(),
                      ),
                    const SizedBox(height: 16),
                    if (task.difficulty != null)
                      Row(
                        children: [
                          const Icon(Icons.thermostat, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text('難易度: ${task.difficulty}', style: textTheme.bodyLarge),
                        ],
                      ),
                    const SizedBox(height: 24),
                    Text(task.description ?? '説明はありません。', style: textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _setAsDailyTask(context),
              child: const Text('今日やる'),
            ),
          ],
        ),
      ),
    );
  }
}
