class CliftonStrength {
  final int id;
  final String name;
  final String domain;
  final String description;
  final int? number;

  CliftonStrength({
    required this.id,
    required this.name,
    required this.domain,
    required this.description,
    this.number,
  });

  factory CliftonStrength.fromJson(Map<String, dynamic> json) {
    return CliftonStrength(
      id: json['id'] as int,
      name: json['name'] as String,
      domain: json['domain'] as String,
      description: json['description'] as String,
      number: json['number'] as int?,
    );
  }
} 