import 'dart:async';
import 'dart:convert';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:little_challenge_app/config/environment.dart';
import 'package:little_challenge_app/services/api_headers.dart';

class AchievementReportScreen extends StatefulWidget {
  final String taskId;
  final bool showUndoOption;

  const AchievementReportScreen({
    super.key, 
    required this.taskId,
    this.showUndoOption = false,
  });

  @override
  State<AchievementReportScreen> createState() => _AchievementReportScreenState();
}

class _AchievementReportScreenState extends State<AchievementReportScreen> {
  late ConfettiController _confettiController;
  int _currentStep = 0;
  String? _selectedFeeling;
  final _memoController = TextEditingController();
  bool _isSubmitting = false;
  bool _showUndoPanel = false;
  Timer? _undoTimer;

  final Map<String, String> _feelings = {
    '😄': '嬉しい',
    '😊': '楽しい',
    '🎉': '最高！',
    '🤔': 'なるほど',
    '✨': 'ひらめき',
  };

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    
    // Show undo panel for 5 seconds if showUndoOption is true
    if (widget.showUndoOption) {
      _showUndoPanel = true;
      _undoTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showUndoPanel = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _memoController.dispose();
    _undoTimer?.cancel();
    super.dispose();
  }

  void _cancelAchievement() {
    _undoTimer?.cancel();
    Navigator.of(context).pop('cancelled');
  }

  Future<void> _submitReport({String? feeling}) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final url = Uri.parse('${Environment.apiBaseUrl}/logs');
    final headers = await ApiHeaders.jsonHeaders();
    final nowLocal = DateTime.now();
    final body = json.encode({
      'task_id': int.parse(widget.taskId),
      'memo': _memoController.text,
      'feeling': feeling,
      // Save using client-local timestamp
      'achieved_at': nowLocal.toIso8601String(),
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (!mounted) return;

      if (response.statusCode == 201) {
        _confettiController.play();
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('レポートの送信に失敗しました (Code: ${response.statusCode})'),
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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("達成の記録"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 20,
              gravity: 0.3,
              emissionFrequency: 0.05,
            ),
          ),
          // Undo Panel
          if (_showUndoPanel)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50), // System Success Green
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      const Text('🎉達成しました！', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton(
                        onPressed: _cancelAchievement,
                        child: const Text('取り消す', style: TextStyle(color: Colors.white, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      key: const ValueKey<int>(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "お疲れ様でした！",
          style: textTheme.headlineLarge?.copyWith(fontSize: 28),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _memoController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "感想や気づきをメモしよう（任意）",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: theme.colorScheme.surface),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.add_a_photo),
          label: const Text("写真を追加（任意）"),
          onPressed: () { /* TODO: Implement photo adding */ },
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.textTheme.bodyMedium?.color,
            side: BorderSide(color: theme.dividerColor),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isSubmitting ? null : () => setState(() => _currentStep = 1),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text("気持ちを記録する", style: textTheme.labelLarge),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _isSubmitting ? null : () => _submitReport(),
          child: _isSubmitting && _selectedFeeling == null
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator())
              : Text(
                  "スキップして完了",
                  style: TextStyle(color: textTheme.bodyMedium?.color),
                ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      key: const ValueKey<int>(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "どんな気持ちでしたか？",
          style: textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12.0,
          runSpacing: 12.0,
          children: _feelings.entries.map((entry) {
            final isSelected = _selectedFeeling == entry.key;
            return ChoiceChip(
              label: Text('${entry.key} ${entry.value}'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFeeling = selected ? entry.key : null;
                });
              },
              selectedColor: theme.primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? theme.primaryColor : textTheme.bodyMedium?.color,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isSubmitting || _selectedFeeling == null
              ? null
              : () => _submitReport(feeling: _selectedFeeling),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isSubmitting
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
              : Text("記録して完了", style: textTheme.labelLarge),
        ),
      ],
    );
  }
}
