import 'package:flutter/material.dart';

class AchievementReportScreen extends StatelessWidget {
  const AchievementReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("達成の記録"),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "お疲れ様でした！",
              style: textTheme.headlineLarge?.copyWith(fontSize: 28),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
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
              onPressed: () {
                // TODO: Implement photo adding functionality
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.textTheme.bodyMedium?.color,
                side: BorderSide(color: theme.dividerColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement Step 2 (Feel Log)
                Navigator.of(context).pop(); // Close screen for now
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text("気持ちを記録する", style: textTheme.labelLarge),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // TODO: Implement API call for skipping
                Navigator.of(context).pop(); // Close screen
              },
              child: Text(
                "スキップして完了",
                style: TextStyle(color: textTheme.bodyMedium?.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
