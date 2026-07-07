/**
 * Normaliza uma string removendo acentos, caracteres especiais e convertendo para minúsculo.
 */
export function normalizeString(str: string): string {
  return str
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '') // Remove acentos
    .replace(/[^a-z0-9\s]/g, ' ')   // Substitui caracteres especiais por espaço
    .replace(/\s+/g, ' ')           // Remove espaços múltiplos
    .trim();
}

/**
 * Divide uma string em tokens de palavras significativas, ignorando palavras de ligação (stop words).
 */
export function getTokens(str: string): string[] {
  const normalized = normalizeString(str);
  const words = normalized.split(' ');
  
  // Lista de palavras irrelevantes comuns em português (stop words)
  const stopWords = new Set([
    'de', 'do', 'da', 'dos', 'das', 'em', 'para', 'com', 'sem', 'por', 'um', 'uma',
    'o', 'a', 'os', 'as', 'e', 'ou', 'sob', 'sobre', 'sob'
  ]);
  
  return words.filter(word => word.length > 1 && !stopWords.has(word));
}

export interface SimilarityResult {
  score: number; // 0 a 100
  matchedWords: string[];
  explanation: string;
}

/**
 * Calcula a similaridade entre dois nomes de produtos baseada no coeficiente de Sorensen-Dice (token overlap).
 * Retorna uma pontuação de similaridade e uma explicação de como chegou ao resultado.
 */
export function calculateSimilarity(nameA: string, nameB: string): SimilarityResult {
  const tokensA = getTokens(nameA);
  const tokensB = getTokens(nameB);

  if (tokensA.length === 0 || tokensB.length === 0) {
    return { score: 0, matchedWords: [], explanation: 'Nenhum termo significativo encontrado para comparação.' };
  }

  const setA = new Set(tokensA);
  const setB = new Set(tokensB);

  // Encontra a interseção de palavras
  const matchedWords = Array.from(setA).filter(token => setB.has(token));
  const intersectionSize = matchedWords.length;

  // Coeficiente de Sorensen-Dice: (2 * |A ∩ B|) / (|A| + |B|)
  const score = (2 * intersectionSize) / (setA.size + setB.size);
  const percentage = Math.round(score * 100);

  let explanation = '';
  if (percentage === 100) {
    explanation = 'Correspondência exata das palavras significativas.';
  } else if (percentage >= 50) {
    explanation = `Correspondência forte de ${percentage}% baseada nos termos em comum: [${matchedWords.join(', ')}].`;
  } else if (percentage > 0) {
    explanation = `Correspondência fraca de ${percentage}%. Termos em comum: [${matchedWords.join(', ')}].`;
  } else {
    explanation = 'Nenhuma palavra significativa em comum foi encontrada.';
  }

  return {
    score: percentage,
    matchedWords,
    explanation
  };
}

/**
 * Procura um produto equivalente numa lista com base em similaridade.
 * Retorna o melhor produto correspondente se a similaridade for maior ou igual ao limite (threshold).
 */
export interface MatchCandidate {
  produto: { id: number; name: string; price: number };
  score: number;
  explanation: string;
}

export function findMatchingProduct(
  newName: string,
  existingProducts: { id: number; name: string; price: number }[],
  threshold = 50
): MatchCandidate | null {
  let bestMatch: MatchCandidate | null = null;

  for (const product of existingProducts) {
    const similarity = calculateSimilarity(newName, product.name);
    if (similarity.score >= threshold) {
      if (!bestMatch || similarity.score > bestMatch.score) {
        bestMatch = {
          produto: product,
          score: similarity.score,
          explanation: similarity.explanation
        };
      }
    }
  }

  return bestMatch;
}
