class Category {
  final String id;
  final String name;
  final String slug;
  final String? icon;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'],
        name: json['name'],
        slug: json['slug'],
        icon: json['icon'],
      );
}
