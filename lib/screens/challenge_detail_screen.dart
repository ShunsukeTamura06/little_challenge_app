// lib/screens/challenge_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChallengeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> challenge;
  const ChallengeDetailScreen({super.key, required this.challenge});

  Future<void> _reportAchievement(BuildContext context) async {
    const url = 'http://localhost:8000/achievements';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'challenge_id': challenge['id']}),
      );

      if (response.statusCode == 201) {
        // 成功メッセージを表示して前の画面に戻る
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('達成おめでとうございます！')),
        );
        Navigator.pop(context, true); // trueを渡して、更新が必要なことを伝える
      } else {
        // エラー処理
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('エラー：報告に失敗しました。')),
        );
      }
    } catch (e) {
      print('エラーが発生しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(challenge['title'] ?? '詳細')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(challenge['title'] ?? 'タイトルなし', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('カテゴリ: ${challenge['category']['name'] ?? 'なし'}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('難易度: ${challenge['difficulty']}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            Text(challenge['description'] ?? '説明なし', style: Theme.of(context).textTheme.bodyLarge),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _reportAchievement(context),
              child: const Text('達成！'),
            ),
          ],
        ),
      ),
    );
  }
}