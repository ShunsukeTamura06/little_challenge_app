import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/app_state_manager.dart';
import 'package:little_challenge_app/config/environment.dart';

class ChallengeDetailScreen extends StatelessWidget {
  final Task task;
  final bool isFromStock;
  final bool isFromHome;

  const ChallengeDetailScreen({
    super.key, 
    required this.task, 
    this.isFromStock = false,
    this.isFromHome = false,
  });

  Future<void> _addToStock(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ストックに追加'),
          content: Text('「${task.title}」をストックに追加しますか？'),
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

    final url = Uri.parse('${Environment.apiBaseUrl}/stock');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({
      'task_id': task.id,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (!context.mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ストックに追加しました！'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ストックへの追加に失敗しました (Code: ${response.statusCode})'),
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

    final url = Uri.parse('${Environment.apiBaseUrl}/tasks/daily/replace');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({
      'new_task_id': task.id,
      'source': 'detail', // or another identifier
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (!context.mounted) return;

      if (response.statusCode == 200) {
        // Update the daily task in the app state
        final data = json.decode(utf8.decode(response.bodyBytes));
        final newTask = Task.fromJson(data);
        Provider.of<AppStateManager>(context, listen: false).setDailyTask(newTask);
        
        // If this task was from stock, remove it from stock
        if (isFromStock) {
          try {
            final deleteUrl = Uri.parse('${Environment.apiBaseUrl}/stock/by-challenge/${task.id}');
            await http.delete(deleteUrl);
          } catch (e) {
            // Ignore deletion errors since the main action (setting daily task) succeeded
          }
        }
        
        if (!context.mounted) return;
        
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
            if (!isFromStock && !isFromHome)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ElevatedButton(
                  onPressed: () => _addToStock(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('あとでやる'),
                ),
              ),
            if (!isFromHome)
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
