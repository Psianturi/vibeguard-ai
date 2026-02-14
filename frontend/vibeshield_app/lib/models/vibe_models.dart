class SentimentData {
  final String token;
  final double score;
  final int timestamp;
  final List<String> sources;

  SentimentData({
    required this.token,
    required this.score,
    required this.timestamp,
    required this.sources,
  });

  factory SentimentData.fromJson(Map<String, dynamic> json) {
    return SentimentData(
      token: json['token'],
      score: (json['score'] as num).toDouble(),
      timestamp: json['timestamp'],
      sources: List<String>.from(json['sources'] ?? []),
    );
  }
}

class PriceData {
  final String token;
  final double price;
  final double volume24h;
  final double priceChange24h;

  PriceData({
    required this.token,
    required this.price,
    required this.volume24h,
    required this.priceChange24h,
  });

  factory PriceData.fromJson(Map<String, dynamic> json) {
    return PriceData(
      token: json['token'],
      price: (json['price'] as num).toDouble(),
      volume24h: (json['volume24h'] as num).toDouble(),
      priceChange24h: (json['priceChange24h'] as num).toDouble(),
    );
  }
}

class RiskAnalysis {
  final double riskScore;
  final bool shouldExit;
  final String reason;
  final String aiModel;

  RiskAnalysis({
    required this.riskScore,
    required this.shouldExit,
    required this.reason,
    required this.aiModel,
  });

  factory RiskAnalysis.fromJson(Map<String, dynamic> json) {
    return RiskAnalysis(
      riskScore: (json['riskScore'] as num).toDouble(),
      shouldExit: json['shouldExit'],
      reason: json['reason'],
      aiModel: json['aiModel'],
    );
  }
}

class VibeCheckResult {
  final SentimentData sentiment;
  final PriceData price;
  final RiskAnalysis analysis;

  VibeCheckResult({
    required this.sentiment,
    required this.price,
    required this.analysis,
  });

  factory VibeCheckResult.fromJson(Map<String, dynamic> json) {
    return VibeCheckResult(
      sentiment: SentimentData.fromJson(json['sentiment']),
      price: PriceData.fromJson(json['price']),
      analysis: RiskAnalysis.fromJson(json['analysis']),
    );
  }
}

class TxHistoryItem {
  final String userAddress;
  final String tokenAddress;
  final String txHash;
  final int timestamp;
  final String source;

  TxHistoryItem({
    required this.userAddress,
    required this.tokenAddress,
    required this.txHash,
    required this.timestamp,
    required this.source,
  });

  factory TxHistoryItem.fromJson(Map<String, dynamic> json) {
    return TxHistoryItem(
      userAddress: json['userAddress'] as String,
      tokenAddress: json['tokenAddress'] as String,
      txHash: json['txHash'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      source: (json['source'] as String?) ?? 'manual',
    );
  }
}

// Enhanced Cryptoracle Sentiment Models

class CommunityActivity {
  final int totalMessages;
  final int interactions;
  final int mentions;
  final int uniqueUsers;
  final int activeCommunities;

  CommunityActivity({
    required this.totalMessages,
    required this.interactions,
    required this.mentions,
    required this.uniqueUsers,
    required this.activeCommunities,
  });

  factory CommunityActivity.fromJson(Map<String, dynamic> json) {
    return CommunityActivity(
      totalMessages: (json['totalMessages'] as num?)?.toInt() ?? 0,
      interactions: (json['interactions'] as num?)?.toInt() ?? 0,
      mentions: (json['mentions'] as num?)?.toInt() ?? 0,
      uniqueUsers: (json['uniqueUsers'] as num?)?.toInt() ?? 0,
      activeCommunities: (json['activeCommunities'] as num?)?.toInt() ?? 0,
    );
  }
}

class SentimentScores {
  final double positive;
  final double negative;
  final double sentimentDiff;

  SentimentScores({
    required this.positive,
    required this.negative,
    required this.sentimentDiff,
  });

  factory SentimentScores.fromJson(Map<String, dynamic> json) {
    return SentimentScores(
      positive: (json['positive'] as num?)?.toDouble() ?? 0,
      negative: (json['negative'] as num?)?.toDouble() ?? 0,
      sentimentDiff: (json['sentimentDiff'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SentimentSignals {
  final double deviation;
  final double momentum;
  final double breakout;
  final double priceDislocation;

  SentimentSignals({
    required this.deviation,
    required this.momentum,
    required this.breakout,
    required this.priceDislocation,
  });

  factory SentimentSignals.fromJson(Map<String, dynamic> json) {
    return SentimentSignals(
      deviation: (json['deviation'] as num?)?.toDouble() ?? 0,
      momentum: (json['momentum'] as num?)?.toDouble() ?? 0,
      breakout: (json['breakout'] as num?)?.toDouble() ?? 0,
      priceDislocation: (json['priceDislocation'] as num?)?.toDouble() ?? 0,
    );
  }
}

class EnhancedSentiment {
  final String token;
  final String window;
  final CommunityActivity community;
  final SentimentScores sentiment;
  final SentimentSignals signals;
  final int timestamp;

  EnhancedSentiment({
    required this.token,
    required this.window,
    required this.community,
    required this.sentiment,
    required this.signals,
    required this.timestamp,
  });

  factory EnhancedSentiment.fromJson(Map<String, dynamic> json) {
    return EnhancedSentiment(
      token: json['token'] as String? ?? '',
      window: json['window'] as String? ?? 'Daily',
      community: CommunityActivity.fromJson(json['community'] ?? {}),
      sentiment: SentimentScores.fromJson(json['sentiment'] ?? {}),
      signals: SentimentSignals.fromJson(json['signals'] ?? {}),
      timestamp: (json['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}


