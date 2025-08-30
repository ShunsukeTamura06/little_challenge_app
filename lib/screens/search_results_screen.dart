import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import 'challenge_detail_screen.dart';
import 'package:little_challenge_app/config/environment.dart';
import 'package:little_challenge_app/services/api_headers.dart';

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

    String url = '${Environment.apiBaseUrl}/challenges/search';
    final Map<String, String> queryParams = {};

    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      queryParams['q'] = widget.searchQuery!;
    }
    if (widget.categoryId != null) {
      queryParams['category_id'] = widget.categoryId.toString();
    }

    if (queryParams.isNotEmpty) {
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      url = uri.toString();
    }

    try {
      final response = await http
          .get(Uri.parse(url), headers: await ApiHeaders.baseHeaders())
          .timeout(const Duration(seconds: 10));
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

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final task = _searchResults[index];
        return ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (task.isCompleted == true)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.check_circle, color: Colors.green, size: 16),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description != null && task.description!.isNotEmpty)
                Text(
                  task.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.label_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.tags.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
                    ),
                  ),
                  if (task.difficulty != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.thermostat, color: Colors.orange, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      'Lv ${task.difficulty}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChallengeDetailScreen(task: task),
              ),
            );
          },
        );
      },
    );
  }
}
