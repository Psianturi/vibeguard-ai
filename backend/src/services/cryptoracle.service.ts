import axios from 'axios';
import { SentimentData, EnhancedSentiment, CommunityActivity, SentimentScores, SentimentSignals } from '../types';

export class CryptoracleService {
  private apiKey: string;
  private baseUrl: string;

  constructor() {
    this.apiKey = process.env.CRYPTORACLE_API_KEY || '';
    this.baseUrl = process.env.CRYPTORACLE_BASE_URL || 'https://service.cryptoracle.network';
  }

  private getHeaders() {
    return this.apiKey
      ? { 'X-API-KEY': this.apiKey, 'Content-Type': 'application/json', Accept: 'application/json' }
      : { 'Content-Type': 'application/json' };
  }

  async getSentiment(token: string): Promise<SentimentData> {
    const symbol = String(token || '').trim().toUpperCase();
    if (!symbol) return { token: symbol, score: 50, timestamp: Date.now(), sources: [] };

    try {
      const enhanced = await this.getEnhancedSentiment(symbol, 'Daily');
      if (!enhanced) {
        return {
          token: symbol,
          score: this.fallbackScore(symbol),
          timestamp: Date.now(),
          sources: ['fallback']
        };
      }

      return {
        token: symbol,
        score: Math.round((enhanced.sentiment.positive ?? 0.5) * 100),
        timestamp: Date.now(),
        sources: ['cryptoracle']
      };
    } catch (error: any) {
      console.error('Cryptoracle error:', error?.message || error?.response?.status || 'Unknown');
      return {
        token: symbol,
        score: this.fallbackScore(symbol),
        timestamp: Date.now(),
        sources: ['fallback']
      };
    }
  }

  private fallbackScore(symbol: string): number {
    // Deterministic pseudo-random score per symbol
    // when upstream is unavailable (keeps demo/monitor behavior meaningful).
    const seed = symbol.split('').reduce((a, c) => a + c.charCodeAt(0), 0);
    const random01 = (i: number) => (((seed * 9301 + 49297 + i * 233) % 233280) / 233280);
    const positive = 0.4 + random01(7) * 0.4; // 0.4 - 0.8
    return Math.round(positive * 100);
  }

  /**
   * Get enhanced sentiment data from Cryptoracle for a specific token and time window
   * @param token - Token symbol (e.g., 'BTC', 'BNB', 'ETH')
   * @param window - Time window: 'Daily', '4H', '1H', '15M' (default: 'Daily')
   */
  async getEnhancedSentiment(token: string, window: string = 'Daily'): Promise<EnhancedSentiment | null> {
    try {
      const symbol = String(token || '').trim().toUpperCase();
      if (!symbol) return null;
      if (!this.apiKey) return null;

      const headers = this.getHeaders();
      const endpointUrl = this.resolveOpenApiEndpointUrl();
      const timeType = this.windowToTimeType(window);
      const { startTime, endTime } = this.getTimeRange(timeType);

      const endpoints = [
        // Community
        'CO-A-01-03',
        'CO-A-01-04',
        'CO-A-01-05',
        'CO-A-01-07',
        'CO-A-01-08',
        // Scores
        'CO-A-02-01',
        'CO-A-02-02',
        'CO-A-02-03',
        // Signals
        'CO-S-01-01',
        'CO-S-01-02',
        'CO-S-01-03',
        'CO-S-01-05'
      ];

      const response = await axios.post(
        endpointUrl,
        {
          apiKey: this.apiKey,
          endpoints,
          startTime,
          endTime,
          timeType,
          token: [symbol]
        },
        { headers, timeout: 20000 }
      );

      const records = this.normalizeOpenApiRecords(response.data);
      if (records.length === 0) return null;

      const byEndpoint = new Map<string, number>();
      for (const r of records) {
        if (String(r.token || '').toUpperCase() !== symbol) continue;
        const endpoint = String(
          (r as any).endpoint || (r as any).endpoints || (r as any).endpointId || (r as any).endpoint_id || ''
        ).trim();
        if (!endpoint) continue;
        const v = this.toNumber(r.value);
        if (v === null) continue;
        byEndpoint.set(endpoint, v);
      }

      const v = (endpoint: string) => byEndpoint.get(endpoint) ?? 0;

      const community: CommunityActivity = {
        totalMessages: Math.round(v('CO-A-01-03')),
        interactions: Math.round(v('CO-A-01-04')),
        mentions: Math.round(v('CO-A-01-05')),
        uniqueUsers: Math.round(v('CO-A-01-07')),
        activeCommunities: Math.round(v('CO-A-01-08'))
      };

      const sentiment: SentimentScores = {
        positive: v('CO-A-02-01') / 100,
        negative: v('CO-A-02-02') / 100,
        sentimentDiff: v('CO-A-02-03') / 100
      };

      const signals: SentimentSignals = {
        deviation: v('CO-S-01-01'),
        momentum: v('CO-S-01-02'),
        breakout: v('CO-S-01-03'),
        priceDislocation: v('CO-S-01-05')
      };

      const looksEmpty =
        community.totalMessages === 0 &&
        community.interactions === 0 &&
        community.mentions === 0 &&
        community.uniqueUsers === 0 &&
        community.activeCommunities === 0 &&
        sentiment.positive === 0 &&
        sentiment.negative === 0 &&
        sentiment.sentimentDiff === 0 &&
        signals.deviation === 0 &&
        signals.momentum === 0 &&
        signals.breakout === 0 &&
        signals.priceDislocation === 0;

      // If all values come back as zeros, treat as invalid so callers can use fallback.
      if (looksEmpty) {
        return null;
      }

      console.log(`Cryptoracle enhanced data for ${token}:`, { community, sentiment, signals });

      return {
        token,
        window,
        community,
        sentiment,
        signals,
        timestamp: Date.now(),
      };
    } catch (error: any) {
      console.error('Cryptoracle enhanced error:', error?.message || 'Failed to fetch enhanced sentiment');
      return null;
    }
  }

  private resolveOpenApiEndpointUrl(): string {
    const raw = String(this.baseUrl || '').trim().replace(/\/+$/, '');
    if (!raw) return 'https://service.cryptoracle.network/openapi/v2.1/endpoint';
    if (raw.includes('/openapi/v2.1/endpoint')) return raw;
    return `${raw}/openapi/v2.1/endpoint`;
  }

  private windowToTimeType(window: string): string {
    switch (String(window || '').trim()) {
      case '15M':
        return '15m';
      case '1H':
        return '1h';
      case '4H':
        return '4h';
      case 'Daily':
      default:
        return '1d';
    }
  }

  private getTimeRange(timeType: string): { startTime: string; endTime: string } {
    const now = new Date();
    const end = now;
    const ms =
      timeType === '15m'
        ? 15 * 60 * 1000
        : timeType === '1h'
          ? 60 * 60 * 1000
          : timeType === '4h'
            ? 4 * 60 * 60 * 1000
            : 24 * 60 * 60 * 1000;
    const start = new Date(end.getTime() - ms);
    return { startTime: this.formatUtc(start), endTime: this.formatUtc(end) };
  }

  private formatUtc(d: Date): string {
    const pad = (n: number) => String(n).padStart(2, '0');
    return `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())} ${pad(d.getUTCHours())}:${pad(d.getUTCMinutes())}:${pad(d.getUTCSeconds())}`;
  }

  private toNumber(v: any): number | null {
    if (typeof v === 'number' && Number.isFinite(v)) return v;
    if (typeof v === 'string') {
      const n = Number(v);
      if (Number.isFinite(n)) return n;
    }
    return null;
  }

  private normalizeOpenApiRecords(payload: any): Array<any> {
    const root = payload?.data ?? payload?.result ?? payload;

    const unwrap = (x: any): any => {
      if (typeof x === 'string') {
        try {
          return JSON.parse(x);
        } catch {
          return x;
        }
      }
      return x;
    };

    const unwrapped = unwrap(root);
    const data = unwrap(unwrapped?.data ?? unwrapped?.result ?? unwrapped);

    if (Array.isArray(data)) return data as any[];
    if (Array.isArray(data?.records)) return data.records as any[];
    if (Array.isArray(data?.list)) return data.list as any[];
    if (Array.isArray(data?.items)) return data.items as any[];
    return [];
  }


  async getMultiTokenSentiment(tokens: string[], window: string = 'Daily'): Promise<Map<string, EnhancedSentiment | null>> {
    const results = new Map<string, EnhancedSentiment | null>();

    await Promise.all(
      tokens.map(async (token) => {
        const data = await this.getEnhancedSentiment(token, window);
        results.set(token.toUpperCase(), data);
      })
    );

    return results;
  }
}
