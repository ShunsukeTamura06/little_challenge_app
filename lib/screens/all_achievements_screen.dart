import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:little_challenge_app/config/environment.dart';
import 'package:little_challenge_app/models/task.dart';
import 'package:little_challenge_app/screens/challenge_detail_screen.dart';
import 'package:little_challenge_app/services/api_headers.dart';

class AllAchievementsScreen extends StatefulWidget {
  const AllAchievementsScreen({super.key});

  @override
  State<AllAchievementsScreen> createState() => _AllAchievementsScreenState();
}

class _AllAchievementsScreenState extends State<AllAchievementsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  final List<_AchievementItem> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchAllLogs();
  }

  Future<void> _fetchAllLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse('${Environment.apiBaseUrl}/logs'); // no month => all
    try {
      final response = await http.get(url, headers: await ApiHeaders.baseHeaders());
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final List<_AchievementItem> all = [];
        data.forEach((date, list) {
          for (final item in (list as List)) {
            final taskJson = item['challenge'] as Map<String, dynamic>;
            final achievedAt = DateTime.parse(item['achieved_at'] as String);
            final memo = item['memo'] as String?;
            final feeling = item['feeling'] as String?;
            all.add(
              _AchievementItem(
                task: Task.fromJson(taskJson),
                achievedAt: achievedAt,
                memo: memo,
                feeling: feeling,
              ),
            );
          }
        });

        all.sort((a, b) => b.achievedAt.compareTo(a.achievedAt));

        setState(() {
          _items
            ..clear()
            ..addAll(all);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '取得に失敗しました (Code: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'エラーが発生しました: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('これまでの達成一覧')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _fetchAllLogs, child: const Text('再試行')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: Text('まだ達成した記録がありません'));
    }

    return RefreshIndicator(
      onRefresh: _fetchAllLogs,
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(item.feeling ?? '✅', style: const TextStyle(fontSize: 18)),
                ),
              ),
              title: Text(item.task.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.memo != null && item.memo!.isNotEmpty)
                    Text(item.memo!, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('yyyy/MM/dd HH:mm').format(item.achievedAt.toLocal()),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChallengeDetailScreen(task: item.task),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AchievementItem {
  final Task task;
  final DateTime achievedAt;
  final String? memo;
  final String? feeling;

  _AchievementItem({
    required this.task,
    required this.achievedAt,
    this.memo,
    this.feeling,
  });
}

