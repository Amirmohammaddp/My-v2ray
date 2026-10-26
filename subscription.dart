class Subscription {
  final String id;
  final String name;
  final String url;
  final DateTime? lastUpdated;

  const Subscription({required this.id, required this.name, required this.url, this.lastUpdated});

  Subscription copyWith({String? name, DateTime? lastUpdated}) =>
      Subscription(id: id, name: name ?? this.name, url: url, lastUpdated: lastUpdated ?? this.lastUpdated);

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'url': url, 'lastUpdated': lastUpdated?.toIso8601String()};

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
        id: j['id'] as String,
        name: j['name'] as String,
        url: j['url'] as String,
        lastUpdated: j['lastUpdated'] == null ? null : DateTime.parse(j['lastUpdated'] as String),
      );
}
