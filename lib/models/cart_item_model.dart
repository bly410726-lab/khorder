import 'product_model.dart';

class CartItemModel {
  const CartItemModel({
    this.id,
    this.product,
    this.quantity = 1,
  });

  final int? id;
  final ProductModel? product;
  final int quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as int?,
      product: json['product'] != null
          ? ProductModel.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product?.toJson(),
      'quantity': quantity,
    };
  }

  double get totalPrice {
    final unitPrice = product?.offerPrice ?? product?.price;
    return unitPrice != null ? unitPrice * quantity : 0;
  }

  CartItemModel copyWith({
    int? id,
    ProductModel? product,
    int? quantity,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}