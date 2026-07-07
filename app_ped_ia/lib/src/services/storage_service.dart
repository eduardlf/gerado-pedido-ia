import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const String _produtosKey = 'pedidos_ia_produtos_mvp';
  static const String _pedidosKey = 'pedidos_ia_pedidos_mvp';
  static const String _geminiApiKey = 'pedidos_ia_gemini_key';

  static final List<Produto> _initialProdutos = [
    Produto(id: 1, name: 'Parafuso Sextavado M8', price: 0.50),
    Produto(id: 2, name: 'Porca Sextavada M8', price: 0.20),
    Produto(id: 3, name: 'Arruela Lisa M8', price: 0.10),
    Produto(id: 4, name: 'Chave Inglesa de 10 polegadas', price: 45.90),
    Produto(id: 5, name: 'Alicate Universal Isolado', price: 39.90),
  ];

  static final List<Pedido> _initialPedidos = [
    Pedido(
      id: 1,
      date: '06/07/2026',
      items: [
        PedidoItem(productId: 1, productName: 'Parafuso Sextavado M8', quantity: 100, price: 0.50),
        PedidoItem(productId: 2, productName: 'Porca Sextavada M8', quantity: 100, price: 0.20),
      ],
      total: 70.00,
      isOcrImported: false,
    )
  ];

  /// Recupera a lista de produtos salvos
  static Future<List<Produto>> getProdutos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_produtosKey);
    if (jsonStr == null) {
      await saveProdutos(_initialProdutos);
      return _initialProdutos;
    }
    final List decoded = json.decode(jsonStr);
    return decoded.map((x) => Produto.fromMap(x as Map<String, dynamic>)).toList();
  }

  /// Salva a lista de produtos
  static Future<void> saveProdutos(List<Produto> produtos) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(produtos.map((x) => x.toMap()).toList());
    await prefs.setString(_produtosKey, jsonStr);
  }

  /// Recupera a lista de pedidos salvos
  static Future<List<Pedido>> getPedidos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_pedidosKey);
    if (jsonStr == null) {
      await savePedidos(_initialPedidos);
      return _initialPedidos;
    }
    final List decoded = json.decode(jsonStr);
    return decoded.map((x) => Pedido.fromMap(x as Map<String, dynamic>)).toList();
  }

  /// Salva a lista de pedidos
  static Future<void> savePedidos(List<Pedido> pedidos) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(pedidos.map((x) => x.toMap()).toList());
    await prefs.setString(_pedidosKey, jsonStr);
  }

  /// Recupera a chave de API do Gemini salva
  static Future<String> getGeminiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiApiKey) ?? '';
  }

  /// Salva a chave de API do Gemini
  static Future<void> saveGeminiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiApiKey, key);
  }
}
