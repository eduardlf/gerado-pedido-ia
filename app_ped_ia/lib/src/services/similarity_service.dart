import '../models/models.dart';

class SimilarityResult {
  final int score; // 0 to 100
  final List<String> matchedWords;
  final String explanation;

  SimilarityResult({
    required this.score,
    required this.matchedWords,
    required this.explanation,
  });
}

class MatchCandidate {
  final Produto produto;
  final int score;
  final String explanation;

  MatchCandidate({
    required this.produto,
    required this.score,
    required this.explanation,
  });
}

class SimilarityService {
  /// Normaliza uma string removendo acentos, caracteres especiais e convertendo para minúsculo.
  static String normalizeString(String str) {
    String normalized = str.toLowerCase();
    
    // Mapa simples de substituição de caracteres acentuados comuns em português
    const accents = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const withoutAccents = 'aaaaaeeeeiiiiooooouuuucn';
    
    for (int i = 0; i < accents.length; i++) {
      normalized = normalized.replaceAll(accents[i], withoutAccents[i]);
    }

    // Remove caracteres especiais, mantendo apenas letras, números e espaços
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    // Remove espaços múltiplos
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    
    return normalized.trim();
  }

  /// Divide uma string em tokens de palavras significativas, ignorando palavras de ligação (stop words).
  static List<String> getTokens(String str) {
    final normalized = normalizeString(str);
    if (normalized.isEmpty) return [];
    
    final words = normalized.split(' ');
    
    // Lista de palavras irrelevantes comuns em português (stop words)
    final stopWords = <String>{
      'de', 'do', 'da', 'dos', 'das', 'em', 'para', 'com', 'sem', 'por', 'um', 'uma',
      'o', 'a', 'os', 'as', 'e', 'ou', 'sob', 'sobre'
    };
    
    return words.where((word) => word.length > 1 && !stopWords.contains(word)).toList();
  }

  /// Calcula a similaridade entre dois nomes de produtos baseada no coeficiente de Sorensen-Dice.
  static SimilarityResult calculateSimilarity(String nameA, String nameB) {
    final tokensA = getTokens(nameA);
    final tokensB = getTokens(nameB);

    if (tokensA.isEmpty || tokensB.isEmpty) {
      return SimilarityResult(
        score: 0,
        matchedWords: [],
        explanation: 'Nenhum termo significativo encontrado para comparação.',
      );
    }

    final setA = tokensA.toSet();
    final setB = tokensB.toSet();

    // Encontra a interseção de palavras
    final matchedWords = setA.intersection(setB).toList();
    final intersectionSize = matchedWords.length;

    // Coeficiente de Sorensen-Dice: (2 * |A ∩ B|) / (|A| + |B|)
    final score = (2 * intersectionSize) / (setA.length + setB.length);
    final percentage = (score * 100).round();

    String explanation = '';
    if (percentage == 100) {
      explanation = 'Correspondência exata das palavras significativas.';
    } else if (percentage >= 50) {
      explanation = 'Correspondência forte de $percentage% baseada nos termos em comum: ${matchedWords.toString()}.';
    } else if (percentage > 0) {
      explanation = 'Correspondência fraca de $percentage%. Termos em comum: ${matchedWords.toString()}.';
    } else {
      explanation = 'Nenhuma palavra significativa em comum foi encontrada.';
    }

    return SimilarityResult(
      score: percentage,
      matchedWords: matchedWords,
      explanation: explanation,
    );
  }

  /// Procura um produto equivalente numa lista com base em similaridade.
  /// Retorna o melhor produto correspondente se a similaridade for maior ou igual ao limite (threshold).
  static MatchCandidate? findMatchingProduct(
    String newName,
    List<Produto> existingProducts, {
    int threshold = 50,
  }) {
    MatchCandidate? bestMatch;

    for (final product in existingProducts) {
      final similarity = calculateSimilarity(newName, product.name);
      if (similarity.score >= threshold) {
        if (bestMatch == null || similarity.score > bestMatch.score) {
          bestMatch = MatchCandidate(
            produto: product,
            score: similarity.score,
            explanation: similarity.explanation,
          );
        }
      }
    }

    return bestMatch;
  }
}
