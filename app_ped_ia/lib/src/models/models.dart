import 'dart:convert';

class Produto {
  final int id;
  final String name;
  final double price;

  Produto({
    required this.id,
    required this.name,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
    };
  }

  factory Produto.fromMap(Map<String, dynamic> map) {
    return Produto(
      id: map['id'] as int,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Produto.fromJson(String source) => Produto.fromMap(json.decode(source) as Map<String, dynamic>);
}

class PedidoItem {
  final int productId;
  final String productName;
  final int quantity;
  final double price;

  PedidoItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
    };
  }

  factory PedidoItem.fromMap(Map<String, dynamic> map) {
    return PedidoItem(
      productId: map['productId'] as int,
      productName: map['productName'] as String,
      quantity: map['quantity'] as int,
      price: (map['price'] as num).toDouble(),
    );
  }
}

class Pedido {
  final int id;
  final String date;
  final List<PedidoItem> items;
  final double total;
  final bool isOcrImported;

  Pedido({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    this.isOcrImported = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'items': items.map((x) => x.toMap()).toList(),
      'total': total,
      'isOcrImported': isOcrImported,
    };
  }

  factory Pedido.fromMap(Map<String, dynamic> map) {
    return Pedido(
      id: map['id'] as int,
      date: map['date'] as String,
      items: List<PedidoItem>.from((map['items'] as List).map((x) => PedidoItem.fromMap(x as Map<String, dynamic>))),
      total: (map['total'] as num).toDouble(),
      isOcrImported: map['isOcrImported'] as bool? ?? false,
    );
  }
}
