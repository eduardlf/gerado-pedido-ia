import 'dart:io';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/similarity_service.dart';

class ReviewOcrItem {
  String originalName;
  String finalName;
  int quantity;
  double price;
  bool isNewProduct;
  Produto? matchedProduct;
  int? matchScore;
  String? matchExplanation;

  ReviewOcrItem({
    required this.originalName,
    required this.finalName,
    required this.quantity,
    required this.price,
    required this.isNewProduct,
    this.matchedProduct,
    this.matchScore,
    this.matchExplanation,
  });
}

class ReviewOcrPage extends StatefulWidget {
  final File imageFile;
  final List<ReviewOcrItem> items;
  final List<Produto> existingProducts;
  final Function(List<ReviewOcrItem>) onConfirm;

  const ReviewOcrPage({
    super.key,
    required this.imageFile,
    required this.items,
    required this.existingProducts,
    required this.onConfirm,
  });

  @override
  State<ReviewOcrPage> createState() => _ReviewOcrPageState();
}

class _ReviewOcrPageState extends State<ReviewOcrPage> {
  late List<ReviewOcrItem> _localItems;

  @override
  void initState() {
    super.initState();
    _localItems = List.from(widget.items);
  }

  void _toggleProductType(int index) {
    setState(() {
      final item = _localItems[index];
      item.isNewProduct = !item.isNewProduct;
      if (item.isNewProduct) {
        item.matchedProduct = null;
        item.matchScore = null;
        item.matchExplanation = 'Cadastrando como novo produto.';
      } else {
        // Tenta achar a melhor correspondência novamente
        final match = SimilarityService.findMatchingProduct(
          item.finalName,
          widget.existingProducts,
          threshold: 30,
        );
        if (match != null) {
          item.matchedProduct = match.produto;
          item.matchScore = match.score;
          item.matchExplanation = match.explanation;
          item.finalName = match.produto.name;
        } else {
          item.isNewProduct = true;
          item.matchExplanation = 'Nenhum produto próximo encontrado.';
        }
      }
    });
  }

  void _onNameChanged(int index, String value) {
    setState(() {
      final item = _localItems[index];
      item.finalName = value;
      if (!item.isNewProduct) {
        final match = SimilarityService.findMatchingProduct(
          value,
          widget.existingProducts,
          threshold: 30,
        );
        if (match != null) {
          item.matchedProduct = match.produto;
          item.matchScore = match.score;
          item.matchExplanation = match.explanation;
        } else {
          item.matchedProduct = null;
          item.matchScore = null;
          item.isNewProduct = true;
          item.matchExplanation = 'Nenhum produto próximo encontrado.';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Revisar Itens da IA',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      body: Column(
        children: [
          // Banner explicativo do topo
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.amber[50],
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber[800], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Confirme as associações dos produtos. Nosso algoritmo inteligente tenta cruzar os itens lidos com os produtos já cadastrados para evitar duplicidade.',
                    style: TextStyle(color: Colors.amber[900], fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          // Lista de itens extraídos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _localItems.length,
              itemBuilder: (context, index) {
                final item = _localItems[index];
                return Container(
                  margin: const EdgeInsets.bottom(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome Input
                      const Text(
                        'PRODUTO DETECTADO',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: item.finalName,
                        onChanged: (val) => _onNameChanged(index, val),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Linha de Qtd e Preço
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'QUANTIDADE',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  initialValue: item.quantity.toString(),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    item.quantity = int.tryParse(val) ?? 1;
                                  },
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    fillColor: const Color(0xFFF8FAFC),
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PREÇO UNITÁRIO (R$)',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  initialValue: item.price.toStringAsFixed(2),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (val) {
                                    item.price = double.tryParse(val) ?? 0.0;
                                  },
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    fillColor: const Color(0xFFF8FAFC),
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 8),
                      // Mapeamento Inteligente
                      Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      item.isNewProduct ? Icons.add_circle_outline : Icons.check_circle_outline,
                                      size: 16,
                                      color: item.isNewProduct ? Colors.orange : Colors.emerald,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      item.isNewProduct 
                                        ? 'Cadastrar como Novo' 
                                        : 'Associado a Existente (${item.matchScore}%)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: item.isNewProduct ? Colors.orange[800] : Colors.emerald[800],
                                      ),
                                    ),
                                  ],
                                ),
                                if (item.matchExplanation != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.matchExplanation!,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                                  ),
                                ]
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _toggleProductType(index),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFEEF2F6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              item.isNewProduct ? 'Usar Existente' : 'Forçar Novo',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Botões de rodapé fixos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.grey[800],
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onConfirm(_localItems);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[600],
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Confirmar Pedido', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
