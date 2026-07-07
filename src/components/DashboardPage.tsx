import React, { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { 
  Package, 
  ShoppingCart, 
  Camera, 
  Upload, 
  Sparkles, 
  RefreshCw, 
  Check, 
  X, 
  AlertTriangle,
  Info,
  CheckCircle2,
  Plus
} from 'lucide-react';
import { Produto, PedidoItem } from '../types';
import { findMatchingProduct } from '../lib/similarity';

interface DashboardPageProps {
  totalProdutos: number;
  totalPedidos: number;
  produtos: Produto[];
  onNavigate: (view: 'products' | 'orders') => void;
  onImportOcrOrder: (items: PedidoItem[]) => void;
  onAddProduto: (name: string, price: number) => Produto; // Returns the created product
}

type ScanStep = 'idle' | 'capture' | 'preview' | 'analyzing' | 'review';

interface DetectedItem {
  productName: string;
  quantity: number;
  price: number;
  // Match fields
  matchedProductId?: number;
  matchScore?: number;
  matchExplanation?: string;
  isNewProduct: boolean;
  finalName: string;
}

export default function DashboardPage({
  totalProdutos,
  totalPedidos,
  produtos,
  onNavigate,
  onImportOcrOrder,
  onAddProduto,
}: DashboardPageProps) {
  // Config state
  const [configStatus, setConfigStatus] = useState({ geminiKeyConfigured: false, message: '' });
  
  // OCR Workflow state
  const [scanStep, setScanStep] = useState<ScanStep>('idle');
  const [selectedImage, setSelectedImage] = useState<string | null>(null);
  const [detectedItems, setDetectedItems] = useState<DetectedItem[]>([]);
  const [isError, setIsError] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');
  
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Load config status on mount
  useEffect(() => {
    fetch('/api/config-status')
      .then((res) => res.json())
      .then((data) => setConfigStatus(data))
      .catch((err) => console.error('Erro ao buscar status do servidor:', err));
  }, []);

  // Handle image selection
  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setSelectedImage(reader.result as string);
        setScanStep('preview');
      };
      reader.readAsDataURL(file);
    }
  };

  const triggerCamera = () => {
    if (fileInputRef.current) {
      fileInputRef.current.setAttribute('capture', 'environment');
      fileInputRef.current.click();
    }
  };

  const triggerUpload = () => {
    if (fileInputRef.current) {
      fileInputRef.current.removeAttribute('capture');
      fileInputRef.current.click();
    }
  };

  // Call the server Gemini API
  const startAnalysis = async () => {
    if (!selectedImage) return;
    setScanStep('analyzing');
    setIsError(false);

    try {
      const response = await fetch('/api/analyze-purchase-order', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          imageBase64: selectedImage,
          mimeType: selectedImage.split(';')[0].split(':')[1] || 'image/jpeg'
        }),
      });

      const data = await response.json();
      if (!response.ok || !data.success) {
        throw new Error(data.error || 'Erro no processamento da imagem.');
      }

      // Process similarity matching for each detected item
      const rawItems = data.items as { productName: string; quantity: number; price: number }[];
      
      const enriched: DetectedItem[] = rawItems.map((item) => {
        // Run similarity search against our current products list
        const match = findMatchingProduct(item.productName, produtos, 50); // 50% threshold

        if (match) {
          return {
            productName: item.productName,
            quantity: item.quantity,
            price: item.price,
            matchedProductId: match.produto.id,
            matchScore: match.score,
            matchExplanation: match.explanation,
            isNewProduct: false,
            finalName: match.produto.name, // Use the existing name
          };
        } else {
          return {
            productName: item.productName,
            quantity: item.quantity,
            price: item.price,
            isNewProduct: true,
            finalName: item.productName, // Keep original
          };
        }
      });

      setDetectedItems(enriched);
      setScanStep('review');
    } catch (err: any) {
      console.error(err);
      setIsError(true);
      setErrorMessage(err.message || 'Houve um erro de comunicação com o servidor.');
      setScanStep('preview');
    }
  };

  // Modify individual fields in review stage
  const handleItemFieldChange = (index: number, field: keyof DetectedItem, value: any) => {
    const updated = [...detectedItems];
    updated[index] = {
      ...updated[index],
      [field]: value
    };
    
    // If name changes, recheck similarity for manual entries
    if (field === 'finalName') {
      const nameVal = value as string;
      const match = findMatchingProduct(nameVal, produtos, 50);
      if (match) {
        updated[index].matchedProductId = match.produto.id;
        updated[index].matchScore = match.score;
        updated[index].matchExplanation = match.explanation;
        updated[index].isNewProduct = false;
      } else {
        updated[index].matchedProductId = undefined;
        updated[index].matchScore = undefined;
        updated[index].matchExplanation = undefined;
        updated[index].isNewProduct = true;
      }
    }
    setDetectedItems(updated);
  };

  // Toggle new product vs existing manually in the table
  const toggleNewProduct = (index: number) => {
    const updated = [...detectedItems];
    updated[index].isNewProduct = !updated[index].isNewProduct;
    if (updated[index].isNewProduct) {
      updated[index].matchedProductId = undefined;
      updated[index].matchScore = undefined;
      updated[index].matchExplanation = 'Cadastrando novo produto.';
    } else {
      // Find nearest match
      const match = findMatchingProduct(updated[index].finalName, produtos, 30);
      if (match) {
        updated[index].matchedProductId = match.produto.id;
        updated[index].matchScore = match.score;
        updated[index].matchExplanation = match.explanation;
        updated[index].finalName = match.produto.name;
      }
    }
    setDetectedItems(updated);
  };

  // Commit everything
  const handleConfirmImport = () => {
    const finalItemsToImport: PedidoItem[] = [];

    detectedItems.forEach((item) => {
      let productId = item.matchedProductId;
      let finalName = item.finalName;

      // If it is tagged as new product, add to local storage catalog first
      if (item.isNewProduct || !productId) {
        const newlyCreated = onAddProduto(finalName, item.price);
        productId = newlyCreated.id;
        finalName = newlyCreated.name;
      }

      finalItemsToImport.push({
        productId: productId,
        productName: finalName,
        quantity: item.quantity,
        price: item.price
      });
    });

    onImportOcrOrder(finalItemsToImport);
    
    // Reset state & go to Orders
    setScanStep('idle');
    setSelectedImage(null);
    setDetectedItems([]);
    onNavigate('orders');
  };

  return (
    <div className="flex flex-col h-full bg-slate-50 font-sans relative overflow-hidden">
      {/* Hidden input for camera or file selector */}
      <input
        type="file"
        ref={fileInputRef}
        onChange={handleImageChange}
        accept="image/*"
        className="hidden"
      />

      {/* App Bar */}
      <header className="sticky top-0 z-10 flex items-center justify-between px-6 py-4 bg-white border-b border-slate-100 shadow-xs">
        <h1 className="text-xl font-bold text-slate-800 tracking-tight flex items-center gap-2">
          <span className="w-2.5 h-2.5 bg-indigo-600 rounded-full animate-pulse"></span>
          Pedidos IA
        </h1>
        <div className="flex items-center gap-2">
          <span className={`text-[10px] font-bold px-2 py-1 rounded-full ${
            configStatus.geminiKeyConfigured 
              ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' 
              : 'bg-amber-50 text-amber-700 border border-amber-200'
          }`}>
            {configStatus.geminiKeyConfigured ? 'Gemini Ativo' : 'Modo Simulação'}
          </span>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 overflow-y-auto p-6 max-w-4xl mx-auto w-full space-y-6">
        {/* Banner Informational for configuration */}
        {!configStatus.geminiKeyConfigured && (
          <div className="p-4 bg-amber-50 border border-amber-200 rounded-2xl flex items-start gap-3">
            <AlertTriangle className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
            <div>
              <h4 className="font-bold text-amber-800 text-xs uppercase tracking-wider">Aviso de Configuração</h4>
              <p className="text-xs text-amber-700 leading-relaxed mt-0.5">
                Nenhuma chave de API do Gemini foi adicionada ao arquivo <code className="font-mono bg-amber-100 px-1 py-0.5 rounded text-amber-900 font-semibold">.env</code>. Para fins de testes imediatos, o aplicativo funcionará no <strong>Modo de Simulação</strong> com uma Ordem de Compra de exemplo completa.
              </p>
            </div>
          </div>
        )}

        {/* Large OCR Interactive Action Button */}
        <div className="bg-gradient-to-br from-indigo-600 via-indigo-700 to-indigo-800 rounded-3xl p-6 text-white shadow-lg relative overflow-hidden">
          {/* Background decoration */}
          <div className="absolute -right-10 -bottom-10 w-44 h-44 bg-white/10 rounded-full blur-3xl"></div>
          
          <div className="relative z-10 space-y-4">
            <div className="inline-flex p-3 bg-white/10 rounded-2xl">
              <Sparkles className="w-6 h-6 text-indigo-200" />
            </div>
            
            <div>
              <h2 className="text-xl font-bold tracking-tight">Importação por Inteligência Artificial</h2>
              <p className="text-xs text-indigo-100 leading-relaxed mt-1 max-w-md">
                Tire foto de uma Ordem de Compra ou selecione uma imagem. A IA lerá todos os produtos, associará com produtos existentes para evitar duplicatas e gerará o pedido em segundos.
              </p>
            </div>

            <div className="grid grid-cols-2 gap-3 pt-2">
              <button
                onClick={triggerCamera}
                className="flex items-center justify-center gap-2 py-3.5 bg-white text-indigo-700 hover:bg-slate-50 font-bold text-sm rounded-2xl shadow-xs transition-all active:scale-98 cursor-pointer"
              >
                <Camera className="w-4 h-4" />
                <span>Tirar Foto</span>
              </button>

              <button
                onClick={triggerUpload}
                className="flex items-center justify-center gap-2 py-3.5 bg-indigo-500/30 text-white hover:bg-indigo-500/40 font-bold text-sm rounded-2xl border border-white/20 transition-all active:scale-98 cursor-pointer"
              >
                <Upload className="w-4 h-4" />
                <span>Escolher Imagem</span>
              </button>
            </div>
          </div>
        </div>

        {/* Regular Navigation Grid */}
        <div className="grid grid-cols-2 gap-4">
          <button
            onClick={() => onNavigate('products')}
            className="p-6 bg-white border border-slate-100 hover:border-emerald-200 hover:bg-emerald-50/10 rounded-3xl text-left transition-all group cursor-pointer shadow-xs"
          >
            <div className="p-3 bg-emerald-50 text-emerald-600 rounded-2xl w-fit group-hover:scale-105 transition-transform mb-4">
              <Package className="w-6 h-6" />
            </div>
            <h3 className="font-bold text-slate-800 text-base">Produtos</h3>
            <p className="text-xs text-slate-400 mt-1">Gerencie o catálogo de produtos e preços.</p>
            <div className="flex items-center justify-between mt-4 pt-4 border-t border-slate-50">
              <span className="text-xs font-bold text-slate-400">Total Cadastrado</span>
              <span className="text-sm font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full">
                {totalProdutos}
              </span>
            </div>
          </button>

          <button
            onClick={() => onNavigate('orders')}
            className="p-6 bg-white border border-slate-100 hover:border-indigo-200 hover:bg-indigo-50/10 rounded-3xl text-left transition-all group cursor-pointer shadow-xs"
          >
            <div className="p-3 bg-indigo-50 text-indigo-600 rounded-2xl w-fit group-hover:scale-105 transition-transform mb-4">
              <ShoppingCart className="w-6 h-6" />
            </div>
            <h3 className="font-bold text-slate-800 text-base">Pedidos</h3>
            <p className="text-xs text-slate-400 mt-1">Gere e liste os pedidos de vendas emitidos.</p>
            <div className="flex items-center justify-between mt-4 pt-4 border-t border-slate-50">
              <span className="text-xs font-bold text-slate-400">Total Emitido</span>
              <span className="text-sm font-bold text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded-full">
                {totalPedidos}
              </span>
            </div>
          </button>
        </div>

        {/* Explainability Info box */}
        <div className="p-5 bg-slate-100 border border-slate-200 rounded-3xl flex gap-4">
          <Info className="w-6 h-6 text-slate-500 shrink-0 mt-0.5" />
          <div className="space-y-1">
            <h4 className="font-bold text-slate-800 text-sm">Algoritmo de Correspondência Semântica</h4>
            <p className="text-xs text-slate-500 leading-relaxed">
              Nosso sistema utiliza o <strong>Coeficiente de Sorensen-Dice</strong> para analisar similaridade de strings em português. Ele ignora acentos, letras maiúsculas e palavras vazias (como 'de', 'do', 'da'), calculando o percentual de termos coincidentes de forma transparente e editável.
            </p>
          </div>
        </div>
      </main>

      {/* FULL-SCREEN OCR WORKFLOW DIALOG */}
      <AnimatePresence>
        {scanStep !== 'idle' && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 bg-slate-900/90 backdrop-blur-xs flex flex-col h-full overflow-hidden"
          >
            {/* Workflow Header */}
            <header className="flex items-center justify-between px-6 py-4 bg-slate-900 text-white border-b border-slate-800">
              <div className="flex items-center gap-2">
                <Sparkles className="w-5 h-5 text-indigo-400" />
                <h2 className="text-base font-bold">Importação Inteligente</h2>
              </div>
              <button
                onClick={() => {
                  setScanStep('idle');
                  setSelectedImage(null);
                  setDetectedItems([]);
                }}
                className="p-1 text-slate-400 hover:text-white rounded-full hover:bg-slate-800 transition-colors cursor-pointer"
              >
                <X className="w-6 h-6" />
              </button>
            </header>

            {/* Workflow main layout */}
            <div className="flex-1 overflow-y-auto p-4 md:p-6 flex flex-col items-center justify-center">
              
              {/* ERROR STATE */}
              {isError && (
                <div className="w-full max-w-md p-4 bg-rose-500 text-white rounded-2xl mb-6 shadow-md flex items-start gap-3">
                  <AlertTriangle className="w-5 h-5 shrink-0 mt-0.5" />
                  <div>
                    <h4 className="font-bold">Falha no Processamento</h4>
                    <p className="text-xs text-white/90 mt-1">{errorMessage}</p>
                    <button 
                      onClick={() => setIsError(false)} 
                      className="mt-2 text-xs font-bold underline cursor-pointer"
                    >
                      Dispensar
                    </button>
                  </div>
                </div>
              )}

              {/* STEP 2: IMAGE PREVIEW & CONFIRM */}
              {scanStep === 'preview' && selectedImage && (
                <div className="w-full max-w-md bg-slate-800 p-4 rounded-3xl shadow-xl flex flex-col items-center gap-4">
                  <div className="text-center text-slate-300">
                    <h3 className="font-bold text-sm">Visualizar Ordem de Compra</h3>
                    <p className="text-[11px] text-slate-400 mt-0.5">Certifique-se de que os produtos e quantidades estão legíveis.</p>
                  </div>

                  <div className="w-full aspect-3/4 max-h-[350px] bg-slate-950 rounded-2xl overflow-hidden border border-slate-700 relative">
                    <img
                      src={selectedImage}
                      alt="Ordem de Compra"
                      className="w-full h-full object-contain"
                      referrerPolicy="no-referrer"
                    />
                  </div>

                  <div className="w-full flex gap-3">
                    <button
                      onClick={() => setScanStep('idle')}
                      className="flex-1 py-3 bg-slate-700 hover:bg-slate-600 text-slate-200 font-bold text-sm rounded-2xl transition-colors cursor-pointer"
                    >
                      Refazer Foto
                    </button>
                    <button
                      onClick={startAnalysis}
                      className="flex-1 py-3 bg-indigo-600 hover:bg-indigo-500 text-white font-bold text-sm rounded-2xl transition-all shadow-md active:scale-98 cursor-pointer flex items-center justify-center gap-1.5"
                    >
                      <Sparkles className="w-4 h-4 text-indigo-200" />
                      <span>Analisar com IA</span>
                    </button>
                  </div>
                </div>
              )}

              {/* STEP 3: ANALYZING ANIMATION */}
              {scanStep === 'analyzing' && (
                <div className="flex flex-col items-center text-center max-w-sm space-y-6 text-white">
                  <div className="relative w-44 h-44 bg-slate-800 rounded-3xl overflow-hidden border border-indigo-500/30 flex items-center justify-center shadow-2xl">
                    {/* Laser line effect */}
                    <motion.div
                      animate={{ top: ['0%', '100%', '0%'] }}
                      transition={{ duration: 2, repeat: Infinity, ease: 'easeInOut' }}
                      className="absolute left-0 right-0 h-1 bg-indigo-400 shadow-[0_0_12px_#818cf8] z-20"
                    ></motion.div>
                    
                    {selectedImage ? (
                      <img
                        src={selectedImage}
                        alt="Analisando..."
                        className="w-full h-full object-cover opacity-40 grayscale"
                        referrerPolicy="no-referrer"
                      />
                    ) : (
                      <Camera className="w-16 h-16 text-indigo-500/50" />
                    )}
                  </div>

                  <div className="space-y-2">
                    <div className="flex items-center justify-center gap-2">
                      <RefreshCw className="w-5 h-5 animate-spin text-indigo-400" />
                      <h3 className="font-bold text-lg">Processamento Gemini IA</h3>
                    </div>
                    <p className="text-xs text-slate-400 max-w-xs leading-relaxed">
                      O Gemini está extraindo a descrição comercial, quantidade e preços dos itens da Ordem de Compra multimodal...
                    </p>
                  </div>
                </div>
              )}

              {/* STEP 4: REVIEW, COMPARE & CONFIRM MAPPINGS */}
              {scanStep === 'review' && (
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="w-full max-w-2xl bg-white rounded-3xl shadow-2xl overflow-hidden border border-slate-100 flex flex-col max-h-[80vh]"
                >
                  {/* Review Header */}
                  <div className="p-5 bg-slate-50 border-b border-slate-100 flex justify-between items-center">
                    <div>
                      <h3 className="font-bold text-slate-800 text-base">Revisar Itens da Ordem de Compra</h3>
                      <p className="text-xs text-slate-500 mt-0.5">Valide as informações capturadas pela IA e as associações automáticas de produtos.</p>
                    </div>
                    <span className="text-xs font-bold text-slate-500 bg-slate-200 px-2.5 py-1 rounded-full">
                      {detectedItems.length} Itens
                    </span>
                  </div>

                  {/* Table review list */}
                  <div className="flex-1 overflow-y-auto p-4 space-y-4">
                    {detectedItems.map((item, idx) => (
                      <div
                        key={idx}
                        className="p-4 bg-slate-50 rounded-2xl border border-slate-100/80 space-y-3"
                      >
                        {/* Name Input Edit */}
                        <div className="flex items-center justify-between gap-4">
                          <div className="flex-1">
                            <label className="block text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1">
                              Nome do Produto Detectado
                            </label>
                            <input
                              type="text"
                              value={item.finalName}
                              onChange={(e) => handleItemFieldChange(idx, 'finalName', e.target.value)}
                              className="w-full px-3 py-2 bg-white border border-slate-200 rounded-xl focus:outline-hidden focus:ring-1 focus:ring-indigo-500 text-sm font-semibold text-slate-800"
                            />
                          </div>
                          
                          {/* Qtd and Price */}
                          <div className="w-20">
                            <label className="block text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1 text-center">
                              Qtd
                            </label>
                            <input
                              type="number"
                              value={item.quantity}
                              onChange={(e) => handleItemFieldChange(idx, 'quantity', Number(e.target.value))}
                              className="w-full px-3 py-2 bg-white border border-slate-200 rounded-xl focus:outline-hidden focus:ring-1 focus:ring-indigo-500 text-sm font-mono text-center font-bold"
                            />
                          </div>

                          <div className="w-24">
                            <label className="block text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1 text-right">
                              Preço Unit. (R$)
                            </label>
                            <input
                              type="number"
                              step="0.01"
                              value={item.price}
                              onChange={(e) => handleItemFieldChange(idx, 'price', parseFloat(e.target.value) || 0)}
                              className="w-full px-3 py-2 bg-white border border-slate-200 rounded-xl focus:outline-hidden focus:ring-1 focus:ring-indigo-500 text-sm font-mono text-right font-bold"
                            />
                          </div>
                        </div>

                        {/* Semantic Association details */}
                        <div className="pt-2 border-t border-slate-200/50 flex flex-wrap items-center justify-between gap-2">
                          <div className="flex items-center gap-2">
                            {item.isNewProduct ? (
                              <span className="inline-flex items-center gap-1 text-[10px] font-bold bg-amber-50 text-amber-700 border border-amber-200 px-2 py-0.5 rounded-full">
                                <Plus className="w-3 h-3" />
                                Cadastrar como Novo Produto
                              </span>
                            ) : (
                              <span className="inline-flex items-center gap-1 text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200 px-2 py-0.5 rounded-full">
                                <Check className="w-3 h-3" />
                                Reutilizar Produto Existente ({item.matchScore}%)
                              </span>
                            )}
                            
                            {item.matchScore && item.matchScore < 100 && (
                              <p className="text-[10px] text-slate-400 italic">
                                "{item.productName}" ➔ "{item.finalName}"
                              </p>
                            )}
                          </div>

                          {/* Action toggle between Create and Reuse */}
                          <button
                            type="button"
                            onClick={() => toggleNewProduct(idx)}
                            className="text-[10px] font-bold text-indigo-600 hover:text-indigo-800 bg-indigo-50 hover:bg-indigo-100 px-2.5 py-1 rounded-lg transition-colors cursor-pointer"
                          >
                            {item.isNewProduct ? 'Associar a existente' : 'Forçar Novo Produto'}
                          </button>
                        </div>
                        
                        {/* Explanation string */}
                        {item.matchExplanation && (
                          <p className="text-[10px] text-slate-400 font-medium">
                            💡 {item.matchExplanation}
                          </p>
                        )}
                      </div>
                    ))}
                  </div>

                  {/* Review Footer actions */}
                  <div className="p-4 bg-slate-50 border-t border-slate-100 flex gap-3">
                    <button
                      onClick={() => {
                        setScanStep('idle');
                        setSelectedImage(null);
                        setDetectedItems([]);
                      }}
                      className="flex-1 py-3 bg-slate-200 hover:bg-slate-300 text-slate-600 font-bold text-sm rounded-2xl transition-colors cursor-pointer"
                    >
                      Cancelar
                    </button>
                    <button
                      onClick={handleConfirmImport}
                      className="flex-1 py-3 bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-sm rounded-2xl transition-all shadow-md cursor-pointer flex items-center justify-center gap-2"
                    >
                      <CheckCircle2 className="w-5 h-5" />
                      <span>Confirmar e Criar Pedido</span>
                    </button>
                  </div>
                </motion.div>
              )}

            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
