import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'challenge_detail_screen.dart'; // We'll create this next

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> challenges = [];

  @override
  void initState() {
    super.initState();
    fetchChallenges();
  }

  Future<void> fetchChallenges() async {
    const url = 'http://localhost:8000/challenges';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          challenges = json.decode(utf8.decode(response.bodyBytes));
        });
      }
    } catch (e) {
      print('An error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今日の小さな挑戦'),
      ),
      body: challenges.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: challenges.length,
              itemBuilder: (context, index) {
                final challenge = challenges[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(challenge['difficulty'].toString()),
                  ),
                  title: Text(challenge['title'] ?? 'タイトルなし'),
                  subtitle: Text(challenge['category']['name'] ?? 'カテゴリなし'),
                  onTap: () async {
                    // 詳細画面に移動し、結果（trueが返ってきたか）を待つ
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChallengeDetailScreen(challenge: challenge),
                      ),
                    );
                    // もし result が true なら（達成報告されたなら）、リストを再読み込み
                    if (result == true) {
                      fetchChallenges();
                    }
                  },
                );
              },
            ),
    );
  }
}