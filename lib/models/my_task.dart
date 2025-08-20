class MyTask {
  final int id;
  final String title;
  final DateTime createdAt;

  MyTask({required this.id, required this.title, required this.createdAt});

  factory MyTask.fromJson(Map<String, dynamic> json) {
    return MyTask(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
