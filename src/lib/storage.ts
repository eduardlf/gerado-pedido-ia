import { Produto, Pedido } from '../types';

const PRODUTOS_KEY = 'pedidos_ia_produtos_mvp';
const PEDIDOS_KEY = 'pedidos_ia_pedidos_mvp';

const initialProdutos: Produto[] = [
  { id: 1, name: 'Parafuso Sextavado M8', price: 0.50 },
  { id: 2, name: 'Porca Sextavada M8', price: 0.20 },
  { id: 3, name: 'Arruela Lisa M8', price: 0.10 },
  { id: 4, name: 'Chave Inglesa de 10 polegadas', price: 45.90 },
  { id: 5, name: 'Alicate Universal Isolado', price: 39.90 }
];

const initialPedidos: Pedido[] = [
  {
    id: 1,
    date: new Date().toLocaleDateString('pt-BR'),
    items: [
      { productId: 1, productName: 'Parafuso Sextavado M8', quantity: 100, price: 0.50 },
      { productId: 2, productName: 'Porca Sextavada M8', quantity: 100, price: 0.20 }
    ],
    total: 70.00,
    isOcrImported: false
  }
];

export function getProdutos(): Produto[] {
  const data = localStorage.getItem(PRODUTOS_KEY);
  if (!data) {
    localStorage.setItem(PRODUTOS_KEY, JSON.stringify(initialProdutos));
    return initialProdutos;
  }
  return JSON.parse(data);
}

export function saveProdutos(produtos: Produto[]) {
  localStorage.setItem(PRODUTOS_KEY, JSON.stringify(produtos));
}

export function getPedidos(): Pedido[] {
  const data = localStorage.getItem(PEDIDOS_KEY);
  if (!data) {
    localStorage.setItem(PEDIDOS_KEY, JSON.stringify(initialPedidos));
    return initialPedidos;
  }
  return JSON.parse(data);
}

export function savePedidos(pedidos: Pedido[]) {
  localStorage.setItem(PEDIDOS_KEY, JSON.stringify(pedidos));
}
