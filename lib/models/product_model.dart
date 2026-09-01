class ProductModel {
  const ProductModel({
    this.id,
    this.name,
    this.description,
    this.price,
    this.offerPrice,
    this.quantity,
    this.category,
    this.categoryId,
    this.image,
    this.images,
    this.isFeatured,
    this.status,
    this.createdAt,
  });

  final int? id;
  final String? name;
  final String? description;
  final double? price;
  final double? offerPrice;
  final int? quantity;
  final String? category;
  final int? categoryId;
  final String? image;
  final List<String>? images;
  final bool? isFeatured;
  final String? status;
  final DateTime? createdAt;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      description: json['description'] as String?,
      price: _toDouble(json['price']),
      offerPrice: _toDouble(json['offer_price']),
      quantity: _toInt(json['quantity']) ?? _toInt(json['stock']),
      category: _categoryName(json['category']),
      categoryId: (json['category_id'] as num?)?.toInt(),
      image: json['image'] as String?,
      images: json['images'] is List
          ? (json['images'] as List).whereType<String>().toList()
          : null,
      isFeatured: json['is_featured'] is bool ? json['is_featured'] as bool : null,
      status: _statusFrom(json),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String? _categoryName(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      final name = value['name'];
      if (name is String) return name;
    }
    return null;
  }

  static String? _statusFrom(Map<String, dynamic> json) {
    final status = json['status'];
    if (status is String && status.isNotEmpty) return status;
    final isActive = json['is_active'];
    if (isActive is bool) return isActive ? 'active' : 'inactive';
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'offer_price': offerPrice,
      'quantity': quantity,
      'category': category,
      'category_id': categoryId,
      'image': image,
      'images': images,
      'is_featured': isFeatured,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  ProductModel copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    double? offerPrice,
    int? quantity,
    String? category,
    int? categoryId,
    String? image,
    List<String>? images,
    bool? isFeatured,
    String? status,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      offerPrice: offerPrice ?? this.offerPrice,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      image: image ?? this.image,
      images: images ?? this.images,
      isFeatured: isFeatured ?? this.isFeatured,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}