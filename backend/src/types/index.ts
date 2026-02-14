export interface SentimentData {
  token: string;
  score: number;
  timestamp: number;
  sources: string[];
}

// Enhanced Cryptoracle Sentiment Data
export interface CommunityActivity {
  totalMessages: number;      // CO-A-01-03
  interactions: number;       // CO-A-01-04
  mentions: number;           // CO-A-01-05
  uniqueUsers: number;        // CO-A-01-07
  activeCommunities: number;  // CO-A-01-08
}

export interface SentimentScores {
  positive: number;          // CO-A-02-01
  negative: number;          // CO-A-02-02
  sentimentDiff: number;     // CO-A-02-03
}

export interface SentimentSignals {
  deviation: number;         // CO-S-01-01
  momentum: number;          // CO-S-01-02
  breakout: number;          // CO-S-01-03
  priceDislocation: number;  // CO-S-01-05
}

export interface EnhancedSentiment {
  token: string;
  window: string;            // Daily, 4H, 1H, 15M
  community: CommunityActivity;
  sentiment: SentimentScores;
  signals: SentimentSignals;
  timestamp: number;
}

export interface PriceData {
  token: string;
  price: number;
  volume24h: number;
  priceChange24h: number;
}

export interface RiskAnalysis {
  riskScore: number;
  shouldExit: boolean;
  reason: string;
  aiModel: string;
}

export interface SwapResult {
  success: boolean;
  txHash?: string;
  error?: string;
}
