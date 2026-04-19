class DataModel {
  final String id;
  final String title;
  final String description;
  final String author;
  final String email;
  final String status;
  final DateTime timestamp;

  DataModel({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.email,
    required this.status,
    required this.timestamp,
  });

  factory DataModel.fromMap(Map<String, dynamic> map) {
    return DataModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      author: map['author'] ?? '',
      email: map['email'] ?? '',
      status: map['status'] ?? '',
      timestamp: map['timestamp'] ?? DateTime.now(),
    );
  }

  @override
  String toString() => 'DataModel(id: $id, title: $title)';
}