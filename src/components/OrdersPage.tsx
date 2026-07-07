import React, { useState } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Plus, Trash2, ShoppingBag, Search, X, PlusCircle, MinusCircle, FileText, CheckCircle2 } from 'lucide-react';
import { Pedido, Produto, PedidoItem } from '../types';

interface OrdersPageProps {
  pedidos: Pedido[];
  produtos: Produto[];
  onAddPedido: (items: PedidoItem[]) => void;
  onDeletePedido: (id: number) => void;
  onBack: () => void;
}

export default function OrdersPage({
  pedidos,
  produtos,
  onAddPedido,
  onDeletePedido,
  onBack,
}: OrdersPageProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [isComposerOpen, setIsComposerOpen] = useState(false);
  
  // Composer States (Creating New Order)
  const [selectedProductId, setSelectedProductId] = useState<number | ''>('');
  const [quantityInput, setQuantityInput] = useState<number>(1);
  const [priceInput, setPriceInput] = useState<string>('0.00');
  const [composedItems, setComposedItems] = useState<PedidoItem[]>([]);
  const [validationError, setValidationError] = useState('');

  // Handle product selection in composer to auto-fill default price
  const handleProductSelect = (idStr: string) => {
    if (!idStr) {
      setSelectedProductId('');
      return;
    }
    const id = Number(idStr);
    setSelectedProductId(id);
    const prod = produtos.find((p) => p.id === id);
    if (prod) {
      setPriceInput(prod.price.toFixed(2));
    }
  };

  // Add individual item to the composed list
  const handleAddItemToOrder = () => {
    if (selectedProductId === '') {
      setValidationError('Selecione um produto.');
      return;
    }

    const prod = produtos.find((p) => p.id === selectedProductId);
    if (!prod) return;

    const qty = Number(quantityInput);
    if (qty <= 0) {
      setValidationError('A quantidade deve ser maior que zero.');
      return;
    }

    const price = parseFloat(priceInput) || 0;

    // Check if product already exists in this composed order
    const existingIndex = composedItems.findIndex((item) => item.productId === selectedProductId);
    if (existingIndex >= 0) {
      const updated = [...composedItems];
      updated[existingIndex].quantity += qty;
      setComposedItems(updated);
    } else {
      setComposedItems([
        ...composedItems,
        {
          productId: prod.id,
          productName: prod.name,
          quantity: qty,
          price: price,
        },
      ]);
    }

    // Reset inputs
    setSelectedProductId('');
    setQuantityInput(1);
    setPriceInput('0.00');
    setValidationError('');
  };

  // Remove individual item from composed list
  const handleRemoveComposedItem = (index: number) => {
    const updated = composedItems.filter((_, i) => i !== index);
    setComposedItems(updated);
  };

  // Submit complete order
  const handleSaveOrder = (e: React.FormEvent) => {
    e.preventDefault();
    if (composedItems.length === 0) {
      setValidationError('Adicione pelo menos um produto ao pedido.');
      return;
    }
    onAddPedido(composedItems);
    setComposedItems([]);
    setValidationError('');
    setIsComposerOpen(false);
  };

  // Calculate totals
  const orderTotal = composedItems.reduce((acc, item) => acc + item.price * item.quantity, 0);

  // Search filter
  const filteredPedidos = pedidos.filter((p) => {
    const query = searchTerm.toLowerCase();
    const hasProductInItems = p.items.some((item) =>
      item.productName.toLowerCase().includes(query)
    );
    const hasOrderMatch = p.id.toString().includes(query) || p.date.includes(query);
    return hasProductInItems || hasOrderMatch;
  });

  return (
    <motion.div
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: -20 }}
      className="flex flex-col h-full bg-slate-50 font-sans"
    >
      {/* Header */}
      <header className="sticky top-0 z-10 flex items-center justify-between px-6 py-4 bg-white border-b border-slate-100 shadow-xs">
        <div className="flex items-center gap-3">
          <button
            onClick={onBack}
            className="p-2 -ml-2 text-slate-500 rounded-full hover:bg-slate-50 hover:text-slate-800 transition-colors cursor-pointer"
            id="btn-back-orders"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <h1 className="text-xl font-bold text-slate-800 tracking-tight">Pedidos de Venda</h1>
        </div>
        <button
          onClick={() => {
            if (produtos.length === 0) {
              alert('Por favor, cadastre produtos na aba anterior para poder criar um pedido.');
              return;
            }
            setComposedItems([]);
            setIsComposerOpen(true);
          }}
          className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 active:bg-indigo-800 text-white font-medium text-sm rounded-xl transition-all shadow-sm cursor-pointer"
          id="btn-add-order-trigger"
        >
          <Plus className="w-4 h-4" />
          <span>Novo Pedido</span>
        </button>
      </header>

      {/* Main List Body */}
      <main className="flex-1 overflow-y-auto p-6 max-w-4xl mx-auto w-full">
        {/* Search */}
        <div className="relative mb-6">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
          <input
            type="text"
            placeholder="Pesquisar por produto, data ou ID..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-12 pr-4 py-3 bg-white border border-slate-200 rounded-2xl focus:outline-hidden focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all text-sm shadow-xs"
            id="input-search-orders"
          />
        </div>

        {/* Orders Card List */}
        <div className="space-y-4">
          {filteredPedidos.length === 0 ? (
            <div className="bg-white rounded-3xl border border-slate-100 p-16 text-center shadow-xs">
              <div className="w-16 h-16 bg-slate-50 rounded-full flex items-center justify-center mb-4 mx-auto">
                <ShoppingBag className="w-8 h-8 text-slate-400" />
              </div>
              <h3 className="text-base font-semibold text-slate-800 mb-1">Nenhum pedido encontrado</h3>
              <p className="text-sm text-slate-400 max-w-xs mx-auto">
                {searchTerm ? 'Tente buscar por termos diferentes.' : 'Inicie um novo pedido manualmente ou importe uma Ordem de Compra.'}
              </p>
            </div>
          ) : (
            filteredPedidos.map((p, pIdx) => (
              <motion.div
                key={p.id}
                initial={{ opacity: 0, y: 15 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: pIdx * 0.04 }}
                className="bg-white rounded-3xl border border-slate-100 p-5 shadow-xs relative hover:shadow-sm transition-all"
                id={`order-card-${p.id}`}
              >
                {/* Header info */}
                <div className="flex items-start justify-between border-b border-slate-100 pb-3 mb-3">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-indigo-50 text-indigo-600 rounded-xl">
                      <FileText className="w-5 h-5" />
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <h3 className="font-bold text-slate-800 text-sm md:text-base">Pedido #{p.id}</h3>
                        {p.isOcrImported && (
                          <span className="text-[10px] font-bold bg-purple-100 text-purple-700 px-2 py-0.5 rounded-full">
                            Importado via IA
                          </span>
                        )}
                      </div>
                      <p className="text-xs text-slate-400 font-medium">{p.date}</p>
                    </div>
                  </div>
                  
                  <div className="flex items-center gap-3">
                    <div className="text-right">
                      <p className="text-xs text-slate-400 font-semibold uppercase tracking-wider">Total</p>
                      <p className="font-bold text-slate-800 text-sm md:text-base">
                        R$ {p.total.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}
                      </p>
                    </div>
                    <button
                      onClick={() => onDeletePedido(p.id)}
                      className="p-2 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-xl transition-colors cursor-pointer"
                      title="Excluir pedido"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                {/* Items in Order */}
                <div className="bg-slate-50/50 rounded-2xl p-3 border border-slate-100/50">
                  <table className="w-full text-left text-xs">
                    <thead>
                      <tr className="text-slate-400 border-b border-slate-200/40 font-semibold">
                        <th className="pb-1.5 pl-1">Produto</th>
                        <th className="pb-1.5 text-center">Qtd</th>
                        <th className="pb-1.5 text-right">Unitário</th>
                        <th className="pb-1.5 text-right pr-1">Total</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {p.items.map((item, itemIdx) => (
                        <tr key={itemIdx} className="text-slate-700 font-medium">
                          <td className="py-2 pl-1 font-semibold text-slate-800 truncate max-w-[150px]">
                            {item.productName}
                          </td>
                          <td className="py-2 text-center text-slate-500 font-mono">
                            {item.quantity}
                          </td>
                          <td className="py-2 text-right font-mono">
                            R$ {item.price.toFixed(2)}
                          </td>
                          <td className="py-2 text-right pr-1 font-semibold text-indigo-600 font-mono">
                            R$ {(item.quantity * item.price).toFixed(2)}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </motion.div>
            ))
          )}
        </div>
      </main>

      {/* Full screen composer to build custom Order with MULTIPLE items */}
      {isComposerOpen && (
        <div className="fixed inset-0 z-50 bg-slate-50 flex flex-col h-full font-sans overflow-hidden">
          {/* Composer Header */}
          <header className="flex items-center justify-between px-6 py-4 bg-white border-b border-slate-200">
            <div className="flex items-center gap-3">
              <button
                onClick={() => setIsComposerOpen(false)}
                className="p-2 -ml-2 text-slate-500 rounded-full hover:bg-slate-100 transition-colors cursor-pointer"
              >
                <ArrowLeft className="w-6 h-6" />
              </button>
              <h2 className="text-lg font-bold text-slate-800">Montar Novo Pedido</h2>
            </div>
            <span className="text-xs font-semibold bg-indigo-50 text-indigo-700 px-3 py-1.5 rounded-xl border border-indigo-100">
              Múltiplos Produtos
            </span>
          </header>

          <div className="flex-1 overflow-y-auto p-6 max-w-2xl mx-auto w-full space-y-6">
            {/* Validation alert */}
            {validationError && (
              <div className="p-3 bg-rose-50 border border-rose-100 text-rose-700 text-xs rounded-xl font-semibold">
                {validationError}
              </div>
            )}

            {/* Selector panel to compose individual items */}
            <div className="bg-white p-5 rounded-3xl border border-slate-100 shadow-sm space-y-4">
              <h3 className="text-sm font-bold text-slate-800 uppercase tracking-wider border-b border-slate-50 pb-2">
                Adicionar Item ao Carrinho
              </h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {/* Product Select */}
                <div>
                  <label htmlFor="select-product" className="block text-xs font-semibold text-slate-500 mb-2">
                    Produto
                  </label>
                  <select
                    id="select-product"
                    value={selectedProductId}
                    onChange={(e) => handleProductSelect(e.target.value)}
                    className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-2xl focus:outline-hidden focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all text-sm appearance-none cursor-pointer"
                  >
                    <option value="">-- Escolha um produto --</option>
                    {produtos.map((p) => (
                      <option key={p.id} value={p.id}>
                        {p.name} (R$ {p.price.toFixed(2)})
                      </option>
                    ))}
                  </select>
                </div>

                {/* Price input */}
                <div>
                  <label htmlFor="price-input" className="block text-xs font-semibold text-slate-500 mb-2">
                    Preço Unitário (R$)
                  </label>
                  <input
                    id="price-input"
                    type="number"
                    step="0.01"
                    min="0"
                    value={priceInput}
                    onChange={(e) => setPriceInput(e.target.value)}
                    className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-2xl focus:outline-hidden focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all text-sm"
                  />
                </div>
              </div>

              {/* Quantity selector */}
              <div className="flex items-center justify-between pt-2">
                <div>
                  <label className="block text-xs font-semibold text-slate-500 mb-1">
                    Quantidade
                  </label>
                  <span className="text-xs text-slate-400">Insira a quantidade desejada</span>
                </div>
                
                <div className="flex items-center gap-4">
                  <button
                    type="button"
                    onClick={() => setQuantityInput(q => Math.max(1, q - 1))}
                    className="text-slate-400 hover:text-indigo-600 transition-colors cursor-pointer"
                  >
                    <MinusCircle className="w-8 h-8" />
                  </button>
                  <span className="text-lg font-bold text-slate-800 font-mono w-10 text-center">
                    {quantityInput}
                  </span>
                  <button
                    type="button"
                    onClick={() => setQuantityInput(q => q + 1)}
                    className="text-slate-400 hover:text-indigo-600 transition-colors cursor-pointer"
                  >
                    <PlusCircle className="w-8 h-8" />
                  </button>
                </div>
              </div>

              {/* Add trigger */}
              <button
                type="button"
                onClick={handleAddItemToOrder}
                className="w-full py-3 mt-2 bg-indigo-50 hover:bg-indigo-100 active:bg-indigo-200 text-indigo-700 font-bold text-sm rounded-2xl transition-colors cursor-pointer flex items-center justify-center gap-2 border border-indigo-100"
              >
                <Plus className="w-4 h-4" />
                <span>Adicionar ao Pedido</span>
              </button>
            </div>

            {/* List of currently composed items */}
            <div className="bg-white p-5 rounded-3xl border border-slate-100 shadow-sm space-y-4">
              <h3 className="text-sm font-bold text-slate-800 uppercase tracking-wider border-b border-slate-50 pb-2">
                Itens no Pedido
              </h3>

              {composedItems.length === 0 ? (
                <div className="py-8 text-center text-slate-400 text-sm">
                  Nenhum produto adicionado ao pedido ainda.
                </div>
              ) : (
                <div className="space-y-3">
                  <ul className="divide-y divide-slate-50">
                    {composedItems.map((item, idx) => (
                      <li key={idx} className="flex items-center justify-between py-3">
                        <div>
                          <p className="font-semibold text-slate-800 text-sm">{item.productName}</p>
                          <p className="text-xs text-slate-400">
                            {item.quantity} un x R$ {item.price.toFixed(2)}
                          </p>
                        </div>
                        <div className="flex items-center gap-3">
                          <span className="font-mono text-sm font-bold text-slate-800">
                            R$ {(item.quantity * item.price).toFixed(2)}
                          </span>
                          <button
                            type="button"
                            onClick={() => handleRemoveComposedItem(idx)}
                            className="p-1.5 text-slate-300 hover:text-rose-500 hover:bg-rose-50 rounded-lg transition-colors cursor-pointer"
                          >
                            <X className="w-4 h-4" />
                          </button>
                        </div>
                      </li>
                    ))}
                  </ul>

                  {/* Summary / Totalizer */}
                  <div className="pt-4 border-t border-slate-100 flex items-center justify-between">
                    <div>
                      <p className="text-sm font-bold text-slate-800">Valor Total do Pedido</p>
                      <p className="text-xs text-slate-400">Somatório de todos os itens acima</p>
                    </div>
                    <span className="text-xl font-extrabold text-indigo-600 font-mono">
                      R$ {orderTotal.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}
                    </span>
                  </div>
                </div>
              )}
            </div>

            {/* Submit order */}
            <button
              onClick={handleSaveOrder}
              disabled={composedItems.length === 0}
              className={`w-full py-4 rounded-3xl font-bold text-white transition-all shadow-md flex items-center justify-center gap-2 cursor-pointer ${
                composedItems.length === 0 
                  ? 'bg-slate-300 shadow-none cursor-not-allowed' 
                  : 'bg-indigo-600 hover:bg-indigo-700 active:bg-indigo-800 hover:shadow-lg'
              }`}
            >
              <CheckCircle2 className="w-5 h-5" />
              <span>Concluir e Salvar Pedido</span>
            </button>
          </div>
        </div>
      )}
    </motion.div>
  );
}
