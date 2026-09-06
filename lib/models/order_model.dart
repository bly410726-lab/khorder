import 'order_item_model.dart';
import 'user_model.dart';

class OrderModel {
  const OrderModel({
    this.id,
    this.orderNumber,
    this.user,
    this.userId,
    this.items,
    this.subtotal,
    this.deliveryFee,
    this.discount,
    this.total,
    this.status,
    this.paymentMethod,
    this.shippingAddress,
    this.shippingPhone,
    this.notes,
    this.createdAt,
  });

  final int? id;
  final String? orderNumber;
  final UserModel? user;
  final int? userId;
  final List<OrderItemModel>? items;
  final double? subtotal;
  final double? deliveryFee;
  final double? discount;
  final double? total;
  final String? status;
  final String? paymentMethod;
  final String? shippingAddress;
  final String? shippingPhone;
  final String? notes;
  final DateTime? createdAt;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as int?,
      orderNumber: json['order_number'] as String?,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      userId: json['user_id'] as int?,
      items: (json['items'] as List?)
          ?.map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble(),
      discount: (json['discount'] as num?)?.toDouble(),
      total: (json['total'] as num?)?.toDouble(),
      status: json['status'] as String?,
      paymentMethod: json['payment_method'] as String?,
      shippingAddress: json['shipping_address'] as String?,
      shippingPhone: json['shipping_phone'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'user': user?.toJson(),
      'user_id': userId,
      'items': items?.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'discount': discount,
      'total': total,
      'status': status,
      'payment_method': paymentMethod,
      'shipping_address': shippingAddress,
      'shipping_phone': shippingPhone,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  OrderModel copyWith({
    int? id,
    String? orderNumber,
    UserModel? user,
    int? userId,
    List<OrderItemModel>? items,
    double? subtotal,
    double? deliveryFee,
    double? discount,
    double? total,
    String? status,
    String? paymentMethod,
    String? shippingAddress,
    String? shippingPhone,
    String? notes,
    DateTime? createdAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      user: user ?? this.user,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      shippingPhone: shippingPhone ?? this.shippingPhone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}