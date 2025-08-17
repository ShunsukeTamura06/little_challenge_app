// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> achievements = [];

  @override
  void initState() {
    super.initState();
    fetchAchievements();
  }

  Future<void> fetchAchievements() async {
    const url = 'http://localhost:8000/achievements';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          achievements = json.decode(utf8.decode(response.bodyBytes));
        });
      }
    } catch (e) {
      print('エラーが発生しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('振り返り'),
      ),
      body: achievements.isEmpty
          ? const Center(child: Text('まだ達成した挑戦はありません。'))
          : RefreshIndicator(
              onRefresh: fetchAchievements,
              child: ListView.builder(
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  final challenge = achievement['challenge'];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(challenge['difficulty'].toString()),
                    ),
                    title: Text(challenge['title'] ?? 'タイトルなし'),
                    subtitle: Text(challenge['category']['name'] ?? 'カテゴリなし'),
                  );
                },
              ),
            ),
    );
  }
}