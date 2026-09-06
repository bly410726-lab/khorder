class CategoryModel {
  const CategoryModel({
    this.id,
    this.name,
    this.image,
    this.description,
    this.status,
    this.productCount,
    this.createdAt,
  });

  final int? id;
  final String? name;
  final String? image;
  final String? description;
  final String? status;
  final int? productCount;
  final DateTime? createdAt;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int?,
      name: json['name'] as String?,
      image: json['image'] as String?,
      description: json['description'] as String?,
      status: json['status'] as String?,
      productCount: json['product_count'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'description': description,
      'status': status,
      'product_count': productCount,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    String? image,
    String? description,
    String? status,
    int? productCount,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      description: description ?? this.description,
      status: status ?? this.status,
      productCount: productCount ?? this.productCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}