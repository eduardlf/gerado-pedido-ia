import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class OrdersPage extends StatefulWidget {
  final List<Pedido> pedidos;
  final List<Produto> produtos;
  final Function(List<PedidoItem>) onAddPedido;
  final Function(int) onDeletePedido;

  const OrdersPage({
    super.key,
    required this.pedidos,
    required this.produtos,
    required this.onAddPedido,
    required this.onDeletePedido,
  });

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String _searchTerm = '';
  final _currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');

  void _openOrderComposer() {
    if (widget.produtos.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Produtos vazios'),
          content: const Text('Por favor, cadastre produtos primeiro para poder montar um pedido.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderComposerDialog(
          produtos: widget.produtos,
          onSave: (items) {
            widget.onAddPedido(items);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.pedidos.where((p) {
      final query = _searchTerm.toLowerCase();
      final hasProductMatch = p.items.any((item) => item.productName.toLowerCase().contains(query));
      final hasDateOrIdMatch = p.id.toString().contains(query) || p.date.contains(query);
      return hasProductMatch || hasDateOrIdMatch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Pedidos de Venda',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: _openOrderComposer,
              icon: const Icon(Icons.add, color: Colors.indigo),
              tooltip: 'Novo Pedido',
            ),
          )
        ],
        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      body: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchTerm = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Pesquisar por produto, data ou ID...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                fillColor: Colors.white,
                filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.all(14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
                ),
              ),
            ),
          ),
          // Lista de Pedidos
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                          child: const Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhum pedido encontrado',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _searchTerm.isNotEmpty ? 'Tente buscar por outro termo.' : 'Crie um pedido ou importe via IA.',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      return Container(
                        margin: const EdgeInsets.bottom(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header do Pedido
                            Row(
                              mainAxisAlignment: MainAxisAlignment.between,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.receipt_long, color: Colors.indigo[600], size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Pedido #${p.id}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                            ),
                                            if (p.isOcrImported) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.purple[50],
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.purple[100]!),
                                                ),
                                                child: Text(
                                                  'IA',
                                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.purple[700]),
                                                ),
                                              )
                                            ]
                                          ],
                                        ),
                                        Text(
                                          p.date,
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('TOTAL', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
                                        Text(
                                          _currencyFormat.format(p.total),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            title: const Text('Excluir Pedido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            content: const Text('Excluir este pedido permanentemente?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                                              TextButton(
                                                onPressed: () {
                                                  widget.onDeletePedido(p.id);
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Excluir', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                              )
                                            ],
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
                                    )
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Tabela simplificada de itens
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: p.items.map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.between,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${item.quantity}x ${item.productName}',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          _currencyFormat.format(item.price * item.quantity),
                                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class OrderComposerDialog extends StatefulWidget {
  final List<Produto> produtos;
  final Function(List<PedidoItem>) onSave;

  const OrderComposerDialog({
    super.key,
    required this.produtos,
    required this.onSave,
  });

  @override
  State<OrderComposerDialog> createState() => _OrderComposerDialogState();
}

class _OrderComposerDialogState extends State<OrderComposerDialog> {
  final List<PedidoItem> _items = [];
  Produto? _selectedProduct;
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');

  void _addItem() {
    if (_selectedProduct == null) return;
    final qty = int.tryParse(_quantityController.text) ?? 1;
    final price = double.tryParse(_priceController.text) ?? _selectedProduct!.price;

    setState(() {
      // Se já houver no carrinho, incrementa
      final idx = _items.indexWhere((x) => x.productId == _selectedProduct!.id);
      if (idx >= 0) {
        final existing = _items[idx];
        _items[idx] = PedidoItem(
          productId: existing.productId,
          productName: existing.productName,
          quantity: existing.quantity + qty,
          price: price,
        );
      } else {
        _items.add(PedidoItem(
          productId: _selectedProduct!.id,
          productName: _selectedProduct!.name,
          quantity: qty,
          price: price,
        ));
      }

      // Reset
      _selectedProduct = null;
      _quantityController.text = '1';
      _priceController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _items.fold<double>(0.0, (sum, item) => sum + (item.price * item.quantity));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Montar Pedido Manual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Painel de Adicionar Item
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ESCOLHER PRODUTO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Produto>(
                    value: _selectedProduct,
                    hint: const Text('Selecione um produto', style: TextStyle(fontSize: 13)),
                    isExpanded: true,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: widget.produtos.map((p) {
                      return DropdownMenuItem<Produto>(
                        value: p,
                        child: Text('${p.name} (${_currencyFormat.format(p.price)})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedProduct = val;
                        if (val != null) {
                          _priceController.text = val.price.toStringAsFixed(2);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('QTD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.all(12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                            const Text('PREÇO UNITÁRIO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _priceController,
                              keyboardType: const TextInputType.withReceiverAndNumbers(decimal: true),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.all(12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[50],
                        foregroundColor: Colors.indigo[700],
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Adicionar Item', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Lista de Itens Atuais
            const Text('ITENS ADICIONADOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: _items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: Text('Nenhum item adicionado ao carrinho.', style: TextStyle(fontSize: 12, color: Colors.grey))),
                    )
                  : Column(
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _items.length,
                          separatorBuilder: (context, idx) => const Divider(color: Color(0xFFF1F5F9), height: 1),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return ListTile(
                              title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('${item.quantity} un x ${_currencyFormat.format(item.price)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_currencyFormat.format(item.price * item.quantity), style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _items.removeAt(index);
                                      });
                                    },
                                    icon: const Icon(Icons.close, color: Colors.red, size: 18),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                        // Totalizador
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.between,
                            children: [
                              const Text('Total do Pedido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                              Text(_currencyFormat.format(total), style: const TextStyle(fontWeight: FontWeight.extrabold, fontSize: 16, color: Colors.indigo, fontFamily: 'monospace')),
                            ],
                          ),
                        )
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _items.isEmpty
                    ? null
                    : () {
                        widget.onSave(_items);
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[600],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Concluir e Salvar Pedido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
