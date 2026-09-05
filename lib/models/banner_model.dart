class BannerModel {
  const BannerModel({
    this.id,
    this.title,
    this.image,
    this.isActive,
    this.sortOrder,
  });

  final int? id;
  final String? title;
  final String? image;
  final bool? isActive;
  final int? sortOrder;

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String?,
      image: json['image'] as String?,
      isActive: json['is_active'] is bool ? json['is_active'] as bool : null,
      sortOrder: (json['sort_order'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  BannerModel copyWith({
    int? id,
    String? title,
    String? image,
    bool? isActive,
    int? sortOrder,
  }) {
    return BannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      image: image ?? this.image,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
