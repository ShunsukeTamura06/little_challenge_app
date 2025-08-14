import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // APIから取得したデータを保持するためのリスト
  List<dynamic> challenges = [];

  // アプリ起動時に一度だけAPIを呼び出す
  @override
  void initState() {
    super.initState();
    fetchChallenges();
  }

  // APIを叩いて挑戦リストを取得する関数
  Future<void> fetchChallenges() async {
    // 【重要】Androidエミュレータから見たホストPCのlocalhostにアクセスするための特別なIPアドレス
    const url = 'http://10.0.2.2:8000/challenges';
    try {
      final response = await http.get(Uri.parse(url));
      // 日本語が文字化けしないようにutf8でデコードする
      if (response.statusCode == 200) {
        setState(() {
          challenges = json.decode(utf8.decode(response.bodyBytes));
        });
      }
    } catch (e) {
      // エラー処理
      print('エラーが発生しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 右上のデバッグバナーを非表示にする
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('今日の小さな挑戦'),
          backgroundColor: Colors.lightBlue,
        ),
        // データ取得中ならローディング表示、完了したらリスト表示
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
                  );
                },
              ),
      ),
    );
  }
}