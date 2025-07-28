class Link {
  final int id;
  final String websiteName;
  final String link;
  final DateTime createdAt;
  final DateTime updatedAt;

  Link({
    required this.id,
    required this.websiteName,
    required this.link,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(
      id: json['id'] as int,
      websiteName: json['websiteName'] as String,
      link: json['link'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
} 