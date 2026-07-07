import { useState, useEffect } from 'react';
import { AnimatePresence } from 'motion/react';
import { Produto, Pedido, PedidoItem } from './types';
import {
  getProdutos,
  saveProdutos,
  getPedidos,
  savePedidos,
} from './lib/storage';
import DashboardPage from './components/DashboardPage';
import ProductsPage from './components/ProductsPage';
import OrdersPage from './components/OrdersPage';

type ActiveView = 'dashboard' | 'products' | 'orders';

export default function App() {
  const [activeView, setActiveView] = useState<ActiveView>('dashboard');
  const [produtos, setProdutos] = useState<Produto[]>([]);
  const [pedidos, setPedidos] = useState<Pedido[]>([]);

  // Load initial data on mount
  useEffect(() => {
    setProdutos(getProdutos());
    setPedidos(getPedidos());
  }, []);

  // Products Operations
  const handleAddProduto = (name: string, price: number): Produto => {
    const nextId = produtos.length > 0 ? Math.max(...produtos.map((p) => p.id)) + 1 : 1;
    const newProduct: Produto = { id: nextId, name, price };
    
    // We must update state and local storage synchronously
    const updated = [...produtos, newProduct];
    setProdutos(updated);
    saveProdutos(updated);

    return newProduct;
  };

  const handleUpdateProduto = (id: number, name: string, price: number) => {
    const updated = produtos.map((p) => (p.id === id ? { ...p, name, price } : p));
    setProdutos(updated);
    saveProdutos(updated);
  };

  const handleDeleteProduto = (id: number) => {
    const updated = produtos.filter((p) => p.id !== id);
    setProdutos(updated);
    saveProdutos(updated);
  };

  // Orders (Pedidos) Operations
  const handleAddPedido = (items: PedidoItem[], isOcrImported = false) => {
    const nextId = pedidos.length > 0 ? Math.max(...pedidos.map((o) => o.id)) + 1 : 1;
    const totalAmount = items.reduce((acc, item) => acc + item.price * item.quantity, 0);

    const newOrder: Pedido = {
      id: nextId,
      date: new Date().toLocaleDateString('pt-BR'),
      items: items,
      total: totalAmount,
      isOcrImported: isOcrImported
    };

    const updated = [newOrder, ...pedidos]; // Prepend new orders to list
    setPedidos(updated);
    savePedidos(updated);
  };

  const handleDeletePedido = (id: number) => {
    const updated = pedidos.filter((o) => o.id !== id);
    setPedidos(updated);
    savePedidos(updated);
  };

  return (
    <div className="w-full h-screen max-w-md mx-auto bg-slate-50 border-x border-slate-200/50 shadow-xl overflow-hidden relative flex flex-col">
      <AnimatePresence mode="wait">
        {activeView === 'dashboard' && (
          <DashboardPage
            key="dashboard"
            totalProdutos={produtos.length}
            totalPedidos={pedidos.length}
            produtos={produtos}
            onNavigate={(view) => setActiveView(view)}
            onImportOcrOrder={(items) => handleAddPedido(items, true)}
            onAddProduto={handleAddProduto}
          />
        )}

        {activeView === 'products' && (
          <ProductsPage
            key="products"
            produtos={produtos}
            onAddProduto={(name, price) => { handleAddProduto(name, price); }}
            onUpdateProduto={handleUpdateProduto}
            onDeleteProduto={handleDeleteProduto}
            onBack={() => setActiveView('dashboard')}
          />
        )}

        {activeView === 'orders' && (
          <OrdersPage
            key="orders"
            pedidos={pedidos}
            produtos={produtos}
            onAddPedido={(items) => handleAddPedido(items, false)}
            onDeletePedido={handleDeletePedido}
            onBack={() => setActiveView('dashboard')}
          />
        )}
      </AnimatePresence>
    </div>
  );
}
