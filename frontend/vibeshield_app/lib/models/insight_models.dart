class ChainInfo {
  final String id;
  final String name;
  final String symbol;
  final String network;
  final String icon;

  ChainInfo({
    required this.id,
    required this.name,
    required this.symbol,
    required this.network,
    required this.icon,
  });

  factory ChainInfo.fromJson(Map<String, dynamic> json) {
    return ChainInfo(
      id: json['id'],
      name: json['name'],
      symbol: json['symbol'],
      network: json['network'],
      icon: json['icon'],
    );
  }
}

class TokenInsight {
  final String token;
  final String window;
  final SentimentScores sentiment;
  final CommunityActivity community;
  final SentimentSignals signals;
  final int timestamp;
  final bool isFallback;

  TokenInsight({
    required this.token,
    required this.window,
    required this.sentiment,
    required this.community,
    required this.signals,
    required this.timestamp,
    this.isFallback = false,
  });

  factory TokenInsight.fromJson(Map<String, dynamic> json) {
    return TokenInsight(
      token: json['token'] ?? '',
      window: json['window'] ?? 'Daily',
      sentiment: SentimentScores.fromJson(json['sentiment'] ?? {}),
      community: CommunityActivity.fromJson(json['community'] ?? {}),
      signals: SentimentSignals.fromJson(json['signals'] ?? {}),
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      isFallback: json['isFallback'] ?? false,
    );
  }

  double get vibeScore => sentiment.positive * 100;
  
  String get vibeLevel {
    if (vibeScore >= 70) return 'Bullish';
    if (vibeScore >= 50) return 'Neutral';
    return 'Bearish';
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
      positive: (json['positive'] as num?)?.toDouble() ?? 0.5,
      negative: (json['negative'] as num?)?.toDouble() ?? 0.5,
      sentimentDiff: (json['sentimentDiff'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

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
      totalMessages: json['totalMessages'] ?? 0,
      interactions: json['interactions'] ?? 0,
      mentions: json['mentions'] ?? 0,
      uniqueUsers: json['uniqueUsers'] ?? 0,
      activeCommunities: json['activeCommunities'] ?? 0,
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
      deviation: (json['deviation'] as num?)?.toDouble() ?? 0.0,
      momentum: (json['momentum'] as num?)?.toDouble() ?? 0.0,
      breakout: (json['breakout'] as num?)?.toDouble() ?? 0.0,
      priceDislocation: (json['priceDislocation'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
