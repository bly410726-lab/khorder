import 'product_model.dart';

class OrderItemModel {
  const OrderItemModel({
    this.id,
    this.product,
    this.productId,
    this.productName,
    this.price,
    this.quantity,
  });

  final int? id;
  final ProductModel? product;
  final int? productId;
  final String? productName;
  final double? price;
  final int? quantity;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as int?,
      product: json['product'] != null
          ? ProductModel.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      productId: json['product_id'] as int?,
      productName: json['product_name'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      quantity: json['quantity'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product?.toJson(),
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
    };
  }

  double get totalPrice {
    return (price ?? 0) * (quantity ?? 0);
  }

  OrderItemModel copyWith({
    int? id,
    ProductModel? product,
    int? productId,
    String? productName,
    double? price,
    int? quantity,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      product: product ?? this.product,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }
}