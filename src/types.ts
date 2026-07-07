export interface Produto {
  id: number;
  name: string;
  price: number;
}

export interface PedidoItem {
  productId: number;
  productName: string;
  quantity: number;
  price: number;
}

export interface Pedido {
  id: number;
  date: string;
  items: PedidoItem[];
  total: number;
  isOcrImported?: boolean;
}
