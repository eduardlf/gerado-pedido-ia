import React, { useState } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, Plus, Trash2, Edit3, Package, Search, X } from 'lucide-react';
import { Produto } from '../types';

interface ProductsPageProps {
  produtos: Produto[];
  onAddProduto: (name: string, price: number) => void;
  onUpdateProduto: (id: number, name: string, price: number) => void;
  onDeleteProduto: (id: number) => void;
  onBack: () => void;
}

export default function ProductsPage({
  produtos,
  onAddProduto,
  onUpdateProduto,
  onDeleteProduto,
  onBack,
}: ProductsPageProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Produto | null>(null);
  
  // Form fields
  const [nameInput, setNameInput] = useState('');
  const [priceInput, setPriceInput] = useState('');

  const filteredProdutos = produtos.filter((p) =>
    p.name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const openAddModal = () => {
    setEditingProduct(null);
    setNameInput('');
    setPriceInput('0.00');
    setIsModalOpen(true);
  };

  const openEditModal = (produto: Produto) => {
    setEditingProduct(produto);
    setNameInput(produto.name);
    setPriceInput(produto.price.toFixed(2));
    setIsModalOpen(true);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!nameInput.trim()) return;

    const parsedPrice = parseFloat(priceInput) || 0;

    if (editingProduct) {
      onUpdateProduto(editingProduct.id, nameInput.trim(), parsedPrice);
    } else {
      onAddProduto(nameInput.trim(), parsedPrice);
    }

    setIsModalOpen(false);
    setNameInput('');
    setPriceInput('');
    setEditingProduct(null);
  };

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
            id="btn-back-products"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
          <h1 className="text-xl font-bold text-slate-800 tracking-tight">Produtos</h1>
        </div>
        <button
          onClick={openAddModal}
          className="flex items-center gap-2 px-4 py-2 bg-emerald-600 hover:bg-emerald-700 active:bg-emerald-800 text-white font-medium text-sm rounded-xl transition-all shadow-sm cursor-pointer"
          id="btn-add-product-trigger"
        >
          <Plus className="w-4 h-4" />
          <span>Novo Produto</span>
        </button>
      </header>

      {/* List Body */}
      <main className="flex-1 overflow-y-auto p-6 max-w-4xl mx-auto w-full">
        {/* Search */}
        <div className="relative mb-6">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
          <input
            type="text"
            placeholder="Pesquisar por nome do produto..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-12 pr-4 py-3 bg-white border border-slate-200 rounded-2xl focus:outline-hidden focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 transition-all text-sm shadow-xs"
            id="input-search-products"
          />
        </div>

        {/* List Card */}
        <div className="bg-white rounded-3xl border border-slate-100 shadow-sm overflow-hidden">
          {filteredProdutos.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 px-4 text-center">
              <div className="w-16 h-16 bg-slate-50 rounded-full flex items-center justify-center mb-4">
                <Package className="w-8 h-8 text-slate-400" />
              </div>
              <h3 className="text-base font-semibold text-slate-800 mb-1">Nenhum produto cadastrado</h3>
              <p className="text-sm text-slate-400 max-w-xs">
                {searchTerm ? 'Tente buscar por um termo diferente.' : 'Cadastre seu primeiro produto para começar a emitir pedidos.'}
              </p>
            </div>
          ) : (
            <ul className="divide-y divide-slate-100">
              {filteredProdutos.map((p, idx) => (
                <motion.li
                  key={p.id}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: idx * 0.02 }}
                  className="flex items-center justify-between px-6 py-4 hover:bg-slate-50/40 transition-colors"
                  id={`product-item-${p.id}`}
                >
                  <div className="flex items-center gap-4">
                    <div className="w-10 h-10 bg-emerald-50 text-emerald-600 rounded-full flex items-center justify-center shrink-0">
                      <Package className="w-5 h-5" />
                    </div>
                    <div>
                      <h4 className="font-semibold text-slate-800 text-sm md:text-base leading-tight">
                        {p.name}
                      </h4>
                      <p className="text-xs text-slate-400 mt-0.5">ID: {p.id}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="text-sm font-semibold text-slate-700 bg-slate-50 px-3 py-1 rounded-full border border-slate-100">
                      R$ {p.price.toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                    </span>
                    <div className="flex gap-1">
                      <button
                        onClick={() => openEditModal(p)}
                        className="p-2 text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors cursor-pointer"
                        title="Editar produto"
                      >
                        <Edit3 className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => onDeleteProduto(p.id)}
                        className="p-2 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors cursor-pointer"
                        title="Excluir produto"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </motion.li>
              ))}
            </ul>
          )}
        </div>
      </main>

      {/* Modal - Create/Edit Product */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs">
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl border border-slate-100"
            id="modal-product"
          >
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-lg font-bold text-slate-800">
                {editingProduct ? 'Editar Produto' : 'Cadastrar Produto'}
              </h2>
              <button
                onClick={() => setIsModalOpen(false)}
                className="p-1.5 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-full transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label htmlFor="product-name" className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">
                  Nome do Produto
                </label>
                <input
                  id="product-name"
                  type="text"
                  required
                  placeholder="Ex: Parafuso Sextavado M8 20mm"
                  value={nameInput}
                  onChange={(e) => setNameInput(e.target.value)}
                  className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-2xl focus:outline-hidden focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 focus:bg-white transition-all text-sm"
                  autoFocus
                />
              </div>

              <div>
                <label htmlFor="product-price" className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">
                  Preço Padrão (R$)
                </label>
                <input
                  id="product-price"
                  type="number"
                  step="0.01"
                  min="0"
                  required
                  placeholder="0.00"
                  value={priceInput}
                  onChange={(e) => setPriceInput(e.target.value)}
                  className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-2xl focus:outline-hidden focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 focus:bg-white transition-all text-sm"
                />
              </div>

              <div className="flex justify-end gap-3 pt-3">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-5 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-600 font-semibold text-sm rounded-xl transition-colors cursor-pointer"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="px-5 py-2.5 bg-emerald-600 hover:bg-emerald-700 active:bg-emerald-800 text-white font-semibold text-sm rounded-xl transition-all cursor-pointer shadow-xs"
                >
                  {editingProduct ? 'Salvar Alterações' : 'Cadastrar Produto'}
                </button>
              </div>
            </form>
          </motion.div>
        </div>
      )}
    </motion.div>
  );
}
