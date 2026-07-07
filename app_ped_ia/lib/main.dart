import 'package:flutter/material.dart';
import 'src/models/models.dart';
import 'src/services/storage_service.dart';
import 'src/widgets/dashboard_page.dart';
import 'src/widgets/products_page.dart';
import 'src/widgets/orders_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PedidosIaApp());
}

class PedidosIaApp extends StatelessWidget {
  const PedidosIaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pedidos IA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.indigo,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo[600],
          secondary: Colors.emerald[600],
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  List<Produto> _produtos = [];
  List<Pedido> _pedidos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    final prods = await StorageService.getProdutos();
    final peds = await StorageService.getPedidos();
    setState(() {
      _produtos = prods;
      _pedidos = peds;
      _isLoading = false;
    });
  }

  // --- Operações de Produtos ---

  Produto _handleAddProduto(String name, double price) {
    final newId = _produtos.isEmpty ? 1 : _produtos.map((x) => x.id).reduce((a, b) => a > b ? a : b) + 1;
    final newProd = Produto(id: newId, name: name, price: price);
    setState(() {
      _produtos.add(newProd);
    });
    StorageService.saveProdutos(_produtos);
    return newProd;
  }

  void _handleUpdateProduto(int id, String name, double price) {
    setState(() {
      final idx = _produtos.indexWhere((x) => x.id == id);
      if (idx >= 0) {
        _produtos[idx] = Produto(id: id, name: name, price: price);
      }
    });
    StorageService.saveProdutos(_produtos);
  }

  void _handleDeleteProduto(int id) {
    setState(() {
      _produtos.removeWhere((x) => x.id == id);
    });
    StorageService.saveProdutos(_produtos);
  }

  // --- Operações de Pedidos ---

  void _handleAddPedido(List<PedidoItem> items) {
    final newId = _pedidos.isEmpty ? 1 : _pedidos.map((x) => x.id).reduce((a, b) => a > b ? a : b) + 1;
    final total = items.fold<double>(0.0, (sum, item) => sum + (item.price * item.quantity));
    
    // Obtém data de hoje formatada
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year;
    final formattedDate = '$day/$month/$year';

    final newPedido = Pedido(
      id: newId,
      date: formattedDate,
      items: items,
      total: total,
      isOcrImported: false,
    );

    setState(() {
      _pedidos.insert(0, newPedido); // Adiciona no início da lista
    });
    StorageService.savePedidos(_pedidos);
    
    // Feedback de sucesso
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pedido #${newPedido.id} criado com sucesso!'),
        backgroundColor: Colors.emerald[600],
      ),
    );
  }

  void _handleImportOcrOrder(List<PedidoItem> items) {
    final newId = _pedidos.isEmpty ? 1 : _pedidos.map((x) => x.id).reduce((a, b) => a > b ? a : b) + 1;
    final total = items.fold<double>(0.0, (sum, item) => sum + (item.price * item.quantity));
    
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year;
    final formattedDate = '$day/$month/$year';

    final newPedido = Pedido(
      id: newId,
      date: formattedDate,
      items: items,
      total: total,
      isOcrImported: true, // Tag informando que veio por OCR Inteligente
    );

    setState(() {
      _pedidos.insert(0, newPedido);
      _currentIndex = 2; // Redireciona automaticamente para a aba de Pedidos
    });
    StorageService.savePedidos(_pedidos);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pedido #${newPedido.id} importado com IA com sucesso!'),
        backgroundColor: Colors.indigo[600],
      ),
    );
  }

  void _handleDeletePedido(int id) {
    setState(() {
      _pedidos.removeWhere((x) => x.id == id);
    });
    StorageService.savePedidos(_pedidos);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.indigo),
        ),
      );
    }

    final pages = [
      DashboardPage(
        totalProdutos: _produtos.length,
        totalPedidos: _pedidos.length,
        produtos: _produtos,
        onNavigateToProducts: () {
          setState(() {
            _currentIndex = 1;
          });
        },
        onNavigateToOrders: () {
          setState(() {
            _currentIndex = 2;
          });
        },
        onImportOcrOrder: _handleImportOcrOrder,
        onAddProduto: _handleAddProduto,
      ),
      ProductsPage(
        produtos: _produtos,
        onAddProduto: (name, price) => _handleAddProduto(name, price),
        onUpdateProduto: _handleUpdateProduto,
        onDeleteProduto: _handleDeleteProduto,
      ),
      OrdersPage(
        pedidos: _pedidos,
        produtos: _produtos,
        onAddPedido: _handleAddPedido,
        onDeletePedido: _handleDeletePedido,
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: Colors.indigo[600],
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Produtos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag),
              label: 'Pedidos',
            ),
          ],
        ),
      ),
    );
  }
}
