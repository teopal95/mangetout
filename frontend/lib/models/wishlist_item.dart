import 'category.dart';

enum ItemStatus { WANTED, DONE }

class WishlistItem {
  final int? id;
  final String title;
  final String? description;
  final String? notes;
  final String? imageUrl;
  final String? externalUrl;
  final ItemStatus status;
  final Category category;

  const WishlistItem({
    this.id,
    required this.title,
    this.description,
    this.notes,
    this.imageUrl,
    this.externalUrl,
    this.status = ItemStatus.WANTED,
    required this.category,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        notes: json['notes'],
        imageUrl: json['imageUrl'],
        externalUrl: json['externalUrl'],
        status: json['status'] == 'DONE' ? ItemStatus.DONE : ItemStatus.WANTED,
        category: Category.fromJson(json['category']),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'notes': notes,
        'imageUrl': imageUrl,
        'externalUrl': externalUrl,
        'status': status.name,
        'category': {'id': category.id},
      };

  WishlistItem copyWith({ItemStatus? status}) => WishlistItem(
        id: id,
        title: title,
        description: description,
        notes: notes,
        imageUrl: imageUrl,
        externalUrl: externalUrl,
        status: status ?? this.status,
        category: category,
      );
}
