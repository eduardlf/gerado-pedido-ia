import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'storage_service.dart';

class RawOcrItem {
  final String productName;
  final int quantity;
  final double price;

  RawOcrItem({
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory RawOcrItem.fromMap(Map<String, dynamic> map) {
    return RawOcrItem(
      productName: map['productName'] as String? ?? 'Item sem nome',
      quantity: (map['quantity'] as num? ?? 1).toInt(),
      price: (map['price'] as num? ?? 1.0).toDouble(),
    );
  }
}

class GeminiService {
  /// Envia a imagem para a API do Gemini e retorna os itens extraídos da Ordem de Compra.
  /// Se nenhuma chave estiver configurada, entra em Modo de Simulação.
  static Future<List<RawOcrItem>> analyzePurchaseOrder(Uint8List imageBytes, String mimeType) async {
    final apiKey = await StorageService.getGeminiKey();

    if (apiKey.trim().isEmpty) {
      // Modo de Simulação realista
      await Future.delayed(const Duration(milliseconds: 2200));
      return [
        RawOcrItem(productName: 'Parafuso M8 Sextavado', quantity: 150, price: 0.55),
        RawOcrItem(productName: 'Porca M8 Sextavada', quantity: 150, price: 0.25),
        RawOcrItem(productName: 'Arruela Lisa Zincada M8', quantity: 300, price: 0.12),
        RawOcrItem(productName: 'Broca de Metal Duro 8mm', quantity: 5, price: 28.50),
      ];
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      const prompt = '''Você é um leitor inteligente de documentos de ordens de compra (purchase orders/pedidos de venda). 
Analise a imagem da Ordem de Compra fornecida e extraia todos os produtos/itens listados.
Para cada item listado, extraia exatamente:
1. O nome do produto ou descrição comercial (em "productName").
2. A quantidade requisitada (em "quantity", como número inteiro).
3. O preço unitário (em "price", como número decimal). Se não houver preço, estime um valor razoável ou use 1.0.

Retorne obrigatoriamente um JSON Array de objetos no seguinte formato:
[
  {
    "productName": "Descrição do Produto",
    "quantity": 10,
    "price": 1.50
  }
]''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        throw Exception('A API do Gemini retornou uma resposta vazia.');
      }

      // Decodifica a resposta JSON
      final List decoded = json.decode(responseText);
      return decoded.map((item) => RawOcrItem.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Falha ao processar com Gemini IA: $e');
    }
  }
}
