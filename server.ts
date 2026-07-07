import express from 'express';
import path from 'path';
import { createServer as createViteServer } from 'vite';
import { GoogleGenAI } from '@google/genai';

async function startServer() {
  const app = express();
  const PORT = 3000;

  // Body parser with size limits for base64 images
  app.use(express.json({ limit: '20mb' }));
  app.use(express.urlencoded({ limit: '20mb', extended: true }));

  // Check if Gemini API key is configured
  const apiKey = process.env.GEMINI_API_KEY;
  const isKeyConfigured = !!apiKey;
  if (!isKeyConfigured) {
    console.warn('⚠️ AVISO: A variável de ambiente GEMINI_API_KEY não está definida. O sistema usará o Modo de Simulação para ler Ordens de Compra.');
  }

  // API - Check system configuration state
  app.get('/api/config-status', (req, res) => {
    res.json({
      geminiKeyConfigured: isKeyConfigured,
      message: isKeyConfigured 
        ? 'Gemini API está ativa e pronta para uso.' 
        : 'Usando Modo de Simulação (adicione a chave GEMINI_API_KEY no arquivo .env para processamento real).'
    });
  });

  // API - OCR and Purchase Order analysis using Gemini Multi-modal
  app.post('/api/analyze-purchase-order', async (req, res) => {
    try {
      const { imageBase64, mimeType } = req.body;

      if (!imageBase64) {
        return res.status(400).json({ error: 'Nenhuma imagem enviada para análise.' });
      }

      // If key is not configured, run in SIMULATION MODE with realistic mock OCR results
      if (!isKeyConfigured) {
        console.log('[API] Executando análise em Modo de Simulação (Chave Gemini ausente)...');
        
        // Let's sleep for 2 seconds to simulate network delay & model processing
        await new Promise((resolve) => setTimeout(resolve, 2200));

        // Return a realistic purchase order parsed list
        const mockOcrResult = [
          { productName: 'Parafuso M8 Sextavado', quantity: 150, price: 0.55 },
          { productName: 'Porca M8 Sextavada', quantity: 150, price: 0.25 },
          { productName: 'Arruela Lisa Zincada M8', quantity: 300, price: 0.12 },
          { productName: 'Broca de Metal Duro 8mm', quantity: 5, price: 28.50 }
        ];

        return res.json({
          success: true,
          simulated: true,
          items: mockOcrResult
        });
      }

      // Real Gemini API Integration
      console.log('[API] Inicializando chamada à API Gemini...');
      const ai = new GoogleGenAI({ apiKey });

      // Clean base64 string if it contains prefix (e.g., data:image/png;base64,)
      let cleanBase64 = imageBase64;
      let detectedMimeType = mimeType || 'image/jpeg';
      if (imageBase64.includes(';base64,')) {
        const parts = imageBase64.split(';base64,');
        detectedMimeType = parts[0].replace('data:', '');
        cleanBase64 = parts[1];
      }

      const prompt = `Você é um leitor inteligente de documentos de ordens de compra (purchase orders/pedidos de venda). 
Analise a imagem da Ordem de Compra fornecida e extraia todos os produtos/itens listados.
Para cada item listado, extraia exatamente:
1. O nome do produto ou descrição comercial (em "productName").
2. A quantidade requisitada (em "quantity", como número inteiro).
3. O preço unitário (em "price", como número decimal). Se não houver preço, estime um valor razoável ou use 1.0.

Retorne obrigatoriamente uma lista (JSON array) no formato estruturado especificado.`;

      const response = await ai.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: [
          {
            inlineData: {
              mimeType: detectedMimeType,
              data: cleanBase64
            }
          },
          prompt
        ],
        config: {
          responseMimeType: 'application/json',
          responseSchema: {
            type: 'ARRAY',
            items: {
              type: 'OBJECT',
              properties: {
                productName: { type: 'STRING' },
                quantity: { type: 'NUMBER' },
                price: { type: 'NUMBER' }
              },
              required: ['productName', 'quantity', 'price']
            }
          }
        }
      });

      const responseText = response.text;
      if (!responseText) {
        throw new Error('O modelo Gemini retornou uma resposta vazia.');
      }

      const items = JSON.parse(responseText);
      console.log(`[API] Sucesso: extraídos ${items.length} itens do documento.`);

      return res.json({
        success: true,
        simulated: false,
        items
      });

    } catch (error: any) {
      console.error('[API] Erro ao analisar imagem com Gemini:', error);
      return res.status(500).json({
        error: 'Erro no processamento da IA.',
        details: error.message || error
      });
    }
  });

  // Serve static UI assets or mount Vite dev middleware
  if (process.env.NODE_ENV !== 'production') {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
    console.log('[Server] Vite middleware mounted for development.');
  } else {
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
    console.log('[Server] Static production assets handler configured.');
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`=========================================`);
    console.log(`🚀 Servidor Pedidos IA rodando em: http://localhost:${PORT}`);
    console.log(`=========================================`);
  });
}

startServer().catch((err) => {
  console.error('Falha crítica ao iniciar o servidor:', err);
});
