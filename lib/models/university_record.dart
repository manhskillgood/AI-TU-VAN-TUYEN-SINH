/// Trường đại học — Firestore `universities`.
class UniversityRecord {
  final String id;
  final String name;
  final List<String> regions;
  final String location;
  final String website;
  final String description;

  const UniversityRecord({
    required this.id,
    required this.name,
    this.regions = const [],
    this.location = '',
    this.website = '',
    this.description = '',
  });

  factory UniversityRecord.fromMap(String id, Map<String, dynamic> m) {
    final regions = m['regions'];
    return UniversityRecord(
      id: id,
      name: (m['name'] ?? '').toString(),
      regions: regions is List
          ? regions.map((e) => e.toString()).toList()
          : [],
      location: (m['location'] ?? '').toString(),
      website: (m['website'] ?? '').toString(),
      description: (m['description'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'regions': regions,
        'location': location,
        'website': website,
        'description': description,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
}
