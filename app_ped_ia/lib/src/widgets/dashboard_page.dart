import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/gemini_service.dart';
import '../services/similarity_service.dart';
import 'review_ocr_page.dart';

class DashboardPage extends StatefulWidget {
  final int totalProdutos;
  final int totalPedidos;
  final List<Produto> produtos;
  final VoidCallback onNavigateToProducts;
  final VoidCallback onNavigateToOrders;
  final Function(List<PedidoItem>) onImportOcrOrder;
  final Function(String, double) onAddProduto;

  const DashboardPage({
    super.key,
    required this.totalProdutos,
    required this.totalPedidos,
    required this.produtos,
    required this.onNavigateToProducts,
    required this.onNavigateToOrders,
    required this.onImportOcrOrder,
    required this.onAddProduto,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _picker = ImagePicker();
  String _geminiKey = '';
  final _keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGeminiKey();
  }

  Future<void> _loadGeminiKey() async {
    final key = await StorageService.getGeminiKey();
    setState(() {
      _geminiKey = key;
      _keyController.text = key;
    });
  }

  Future<void> _saveGeminiKey(String key) async {
    await StorageService.saveGeminiKey(key);
    setState(() {
      _geminiKey = key;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chave de API do Gemini salva com sucesso!')),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Configurações da API', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Insira sua chave de API do Gemini para ler fotos de Ordens de Compra em tempo real:',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _keyController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Gemini API Key',
                  hintText: 'AIzaSy...',
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '💡 Se deixado em branco, o aplicativo funcionará em Modo de Simulação com dados fictícios para fins de testes rápidos.',
                style: TextStyle(fontSize: 10, color: Colors.indigo, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                _saveGeminiKey(_keyController.text.trim());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Salvar Chave', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  Future<void> _processImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo == null) return;

      final file = File(photo.path);

      // Mostra tela de carregamento "Analisando com IA"
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              content: const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.indigo),
                    SizedBox(height: 20),
                    Text(
                      'Processamento Gemini IA',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'O Gemini está lendo e extraindo os itens da Ordem de Compra...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      // Executa a chamada à API do Gemini
      final imageBytes = await file.readAsBytes();
      final mimeType = photo.mimeType ?? 'image/jpeg';
      final ocrItems = await GeminiService.analyzePurchaseOrder(imageBytes, mimeType);

      // Fecha o dialog de carregamento
      if (!mounted) return;
      Navigator.pop(context);

      // Converte RawOcrItem para ReviewOcrItem com mapeamento inteligente
      final List<ReviewOcrItem> reviewItems = ocrItems.map((item) {
        final match = SimilarityService.findMatchingProduct(item.productName, widget.produtos, threshold: 50);

        if (match != null) {
          return ReviewOcrItem(
            originalName: item.productName,
            finalName: match.produto.name,
            quantity: item.quantity,
            price: item.price,
            isNewProduct: false,
            matchedProduct: match.produto,
            matchScore: match.score,
            matchExplanation: match.explanation,
          );
        } else {
          return ReviewOcrItem(
            originalName: item.productName,
            finalName: item.productName,
            quantity: item.quantity,
            price: item.price,
            isNewProduct: true,
            matchExplanation: 'Nenhum produto cadastrado é parecido com este.',
          );
        }
      }).toList();

      // Abre a tela de revisão e mapeamento
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewOcrPage(
            imageFile: file,
            items: reviewItems,
            existingProducts: widget.produtos,
            onConfirm: (confirmedItems) {
              final List<PedidoItem> finalItems = [];

              for (final item in confirmedItems) {
                int prodId;
                String prodName = item.finalName;

                if (item.isNewProduct || item.matchedProduct == null) {
                  // Cadastra o novo produto no catálogo primeiro
                  final newProd = widget.onAddProduto(prodName, item.price);
                  prodId = newProd.id;
                  prodName = newProd.name;
                } else {
                  prodId = item.matchedProduct!.id;
                  prodName = item.matchedProduct!.name;
                }

                finalItems.add(PedidoItem(
                  productId: prodId,
                  productName: prodName,
                  quantity: item.quantity,
                  price: item.price,
                ));
              }

              // Salva o pedido importado
              widget.onImportOcrOrder(finalItems);
            },
          ),
        ),
      );
    } catch (e) {
      // Fecha o loader caso esteja aberto
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erro na Análise'),
            content: Text('Houve um problema ao ler a imagem: $e'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            const Text(
              'Pedidos IA',
              style: TextStyle(fontWeight: FontWeight.extrabold, fontSize: 18, letterSpacing: -0.5),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showSettingsDialog,
            icon: Icon(
              Icons.settings,
              color: _geminiKey.isNotEmpty ? Colors.indigo : Colors.grey,
            ),
            tooltip: 'Configurações',
          )
        ],
        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner explicativo se em Modo Simulação
            if (_geminiKey.isEmpty) ...[
              Container(
                margin: const EdgeInsets.bottom(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber[100]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber[800], size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.amber[900], fontSize: 11, height: 1.4),
                          children: [
                            const TextSpan(text: 'Nenhuma chave de API configurada. O app está operando no '),
                            const TextSpan(text: 'Modo de Simulação', style: TextStyle(fontWeight: FontWeight.bold)),
                            const TextSpan(text: ' com uma Ordem de Compra exemplo. Toque na engrenagem no topo para adicionar sua chave do Gemini.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Card Principal de OCR por Inteligência Artificial
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo[600]!, Colors.indigo[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.yellow, size: 22),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Importação por Inteligência Artificial',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tire foto de uma Ordem de Compra física ou carregue um arquivo. A IA do Gemini lerá os itens e os cruzará com seus produtos automaticamente.',
                    style: TextStyle(color: Colors.indigo[50], fontSize: 11, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _processImage(ImageSource.camera),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.indigo[700],
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Tirar Foto', style: TextStyle(fontWeight: FontWeight.extrabold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _processImage(ImageSource.gallery),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo[500]!.withOpacity(0.4),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('Escolher Imagem', style: TextStyle(fontWeight: FontWeight.extrabold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Grid de Atalhos de Navegação
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: widget.onNavigateToProducts,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.emerald[50], borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.inventory_2, color: Colors.emerald[600], size: 20),
                          ),
                          const SizedBox(height: 16),
                          const Text('Produtos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                          const Text('Gerencie o catálogo de preços', style: TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 14),
                          const Divider(color: Color(0xFFF1F5F9), height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.between,
                            children: [
                              const Text('Total Cadastrado', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.emerald[50], borderRadius: BorderRadius.circular(20)),
                                child: Text('${widget.totalProdutos}', style: TextStyle(color: Colors.emerald[700], fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: InkWell(
                    onTap: widget.onNavigateToOrders,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.receipt_long, color: Colors.indigo[600], size: 20),
                          ),
                          const SizedBox(height: 16),
                          const Text('Pedidos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                          const Text('Acompanhe vendas emitidas', style: TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 14),
                          const Divider(color: Color(0xFFF1F5F9), height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.between,
                            children: [
                              const Text('Total Emitido', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(20)),
                                child: Text('${widget.totalPedidos}', style: TextStyle(color: Colors.indigo[700], fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Caixa informativa sobre o algoritmo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[700], size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mapeamento Semântico Offline',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Nosso algoritmo Sorensen-Dice roda totalmente offline no celular. Ele limpa acentuações, pontuações e ignora "stop words" (de, para, com) para calcular a similaridade de palavras exata.',
                          style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
