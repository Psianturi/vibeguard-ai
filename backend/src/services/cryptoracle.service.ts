import axios from 'axios';
import { SentimentData, EnhancedSentiment, CommunityActivity, SentimentScores, SentimentSignals } from '../types';

export class CryptoracleService {
  private apiKey: string;
  private baseUrl: string;

  constructor() {
    this.apiKey = process.env.CRYPTORACLE_API_KEY || '';
    this.baseUrl = process.env.CRYPTORACLE_BASE_URL || 'https://api.cryptoracle.io/v1';
  }

  private getHeaders() {
    return this.apiKey
      ? { 'X-API-Key': this.apiKey, 'Content-Type': 'application/json' }
      : { 'Content-Type': 'application/json' };
  }

  async getSentiment(token: string): Promise<SentimentData> {
    try {
      const url = `${this.baseUrl}/sentiment/${encodeURIComponent(token)}`;
      const response = await axios.get(url, { headers: this.getHeaders(), timeout: 15000 });

      console.log('Cryptoracle response for', token, ':', JSON.stringify(response.data).slice(0, 200));

      return {
        token,
        score: response.data.score ?? 50,
        timestamp: Date.now(),
        sources: response.data.sources || []
      };
    } catch (error: any) {
      console.error('Cryptoracle error:', error?.message || error?.response?.status || 'Unknown');
      return { token, score: 50, timestamp: Date.now(), sources: [] };
    }
  }

  /**
   * Get enhanced sentiment data from Cryptoracle for a specific token and time window
   * @param token - Token symbol (e.g., 'BTC', 'BNB', 'ETH')
   * @param window - Time window: 'Daily', '4H', '1H', '15M' (default: 'Daily')
   */
  async getEnhancedSentiment(token: string, window: string = 'Daily'): Promise<EnhancedSentiment | null> {
    try {
      const headers = this.getHeaders();

      // Community Activity endpoints
      const [messagesRes, interactionsRes, mentionsRes, usersRes, communitiesRes] = await Promise.allSettled([
        axios.get(`${this.baseUrl}/metrics/CO-A-01-03`, { params: { token, window }, headers, timeout: 10000 }),
        axios.get(`${this.baseUrl}/metrics/CO-A-01-04`, { params: { token, window }, headers, timeout: 10000 }),
        axios.get(`${this.baseUrl}/metrics/CO-A-01-05`, { params: { token, window }, headers, timeout: 10000 }),
        axios.get(`${this.baseUrl}/metrics/CO-A-01-07`, { params: { token, window }, headers, timeout: 10000 }),
        axios.get(`${this.baseUrl}/metrics/CO-A-01-08`, { params: { token, window }, headers, timeout: 10000 }),
      ]);

      // Sentiment Score endpoints
      const [positiveRes, negativeRes, diffRes] = await Promise.allSettled([
        axios.get(`${this.baseUrl}/metrics/CO-A-02-01`, { params: { token, window }, headers, timeout: 10000 }),
        axios.get(`${this.baseUrl}/metrics/CO-A-02-02`, { params: { token, window }, headers, timeout: 10000 }),
        axios.get(`${this.baseUrl}/metrics/CO-A-02-03`, { params: { token, window }, headers, timeout: 10000 }),
      ]);

      // Sentiment Signal endpoints
      const [deviationRes, momentumRes, breakoutRes, dislocationRes] = await Promise.allSettled([
        axios.get(`${this.baseUrl}/metrics/CO-S-01-01`, { params: { token, window }, headers, timeout: 10000 }),
        axios.get(`${this.baseUrl}/metrics/CO-S-01-02`, { params: { token, window }, headers, timeout: 10000 }),
        axios.get(`${this.baseUrl}/metrics/CO-S-01-03`, { params: { token, window }, headers, timeout: 10000 }),
        axios.get(`${this.baseUrl}/metrics/CO-S-01-05`, { params: { token, window }, headers, timeout: 10000 }),
      ]);

      const community: CommunityActivity = {
        totalMessages: this.extractValue(messagesRes, 'value'),
        interactions: this.extractValue(interactionsRes, 'value'),
        mentions: this.extractValue(mentionsRes, 'value'),
        uniqueUsers: this.extractValue(usersRes, 'value'),
        activeCommunities: this.extractValue(communitiesRes, 'value'),
      };

      const sentiment: SentimentScores = {
        positive: this.extractValue(positiveRes, 'value') / 100, // Convert to 0-1 range
        negative: this.extractValue(negativeRes, 'value') / 100,
        sentimentDiff: this.extractValue(diffRes, 'value') / 100,
      };

      const signals: SentimentSignals = {
        deviation: this.extractValue(deviationRes, 'value'),
        momentum: this.extractValue(momentumRes, 'value'),
        breakout: this.extractValue(breakoutRes, 'value'),
        priceDislocation: this.extractValue(dislocationRes, 'value'),
      };

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

 
  private extractValue(result: PromiseSettledResult<any>, key: string): number {
    if (result.status === 'fulfilled' && result.value?.data) {
      return Number(result.value.data[key]) || 0;
    }
    return 0;
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
