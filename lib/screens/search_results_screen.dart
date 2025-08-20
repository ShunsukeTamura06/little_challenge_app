import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/task.dart'; // Assuming Task model is used for search results

class SearchResultsScreen extends StatefulWidget {
  final String? searchQuery;
  final int? categoryId;

  const SearchResultsScreen({super.key, this.searchQuery, this.categoryId});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Task> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String url = 'http://localhost:8000/challenges/search';
    final Map<String, String> queryParams = {};

    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      queryParams['q'] = widget.searchQuery!;
    }
    if (widget.categoryId != null) {
      queryParams['category_id'] = widget.categoryId.toString();
    }

    if (queryParams.isNotEmpty) {
      url += '?' + Uri.encodeQueryComponent(queryParams.entries.map((e) => '${e.key}=${e.value}').join('&'));
    }

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _searchResults = data.map((json) => Task.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "検索結果の取得に失敗しました (Code: ${response.statusCode})";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('検索結果'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _performSearch, child: const Text('再試行')),
                  ],
                ))
              : _buildSearchResults(),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text('該当するタスクは見つかりませんでした。'));
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final task = _searchResults[index];
        return ListTile(
          title: Text(task.title),
          subtitle: Text(task.tags.join(', ')),
          // TODO: Navigate to TaskDetailScreen [SCR-007]
        );
      },
    );
  }
}
