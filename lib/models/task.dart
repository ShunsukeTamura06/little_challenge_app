class Task {
  final String id;
  final String title;
  final String? description;
  final List<String> tags;
  final int? difficulty;
  final double? completionRate; // Nullable for tasks from stock etc.

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.tags,
    this.difficulty,
    this.completionRate,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    List<String> tags = [];
    if (json['tags'] != null) {
      tags = List<String>.from(json['tags']);
    } else if (json['category'] != null && json['category']['name'] != null) {
      tags = [json['category']['name'] as String];
    }

    double? completionRate;
    if (json['stats'] != null && json['stats']['completion_rate'] != null) {
      completionRate = (json['stats']['completion_rate'] as num).toDouble();
    }

    return Task(
      id: json['id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String?,
      tags: tags,
      difficulty: json['difficulty'] as int?,
      completionRate: completionRate,
    );
  }
}
