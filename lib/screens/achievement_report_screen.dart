import 'package:flutter/material.dart';

class AchievementReportScreen extends StatefulWidget {
  const AchievementReportScreen({super.key});

  @override
  State<AchievementReportScreen> createState() => _AchievementReportScreenState();
}

class _AchievementReportScreenState extends State<AchievementReportScreen> {
  int _currentStep = 0;
  String? _selectedFeeling;
  final _memoController = TextEditingController();
  bool _isSubmitting = false;

  // Define feelings
  final Map<String, String> _feelings = {
    '😄': '嬉しい',
    '😊': '楽しい',
    '🎉': '最高！',
    '🤔': 'なるほど',
    '✨': 'ひらめき',
  };

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  void _submitReport({String? feeling}) {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // TODO: Implement API call to POST /logs
    print('Submitting report...');
    print('Memo: ${_memoController.text}');
    print('Feeling: $feeling');

    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isSubmitting = false);
        // TODO: Show confetti on success
        Navigator.of(context).pop(); // Close the modal
      }
    });
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
        ),
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
          onPressed: () => setState(() => _currentStep = 1),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text("気持ちを記録する", style: textTheme.labelLarge),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => _submitReport(),
          child: Text(
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
          onPressed: _selectedFeeling == null ? null : () => _submitReport(feeling: _selectedFeeling),
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
