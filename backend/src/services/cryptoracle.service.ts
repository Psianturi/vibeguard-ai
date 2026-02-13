import axios from 'axios';
import { SentimentData } from '../types';

export class CryptoracleService {
  private apiKey: string;
  private baseUrl: string;

  constructor() {
    this.apiKey = process.env.CRYPTORACLE_API_KEY || '';
    this.baseUrl = process.env.CRYPTORACLE_BASE_URL || 'https://api.cryptoracle.io/v1';
  }

  async getSentiment(token: string): Promise<SentimentData> {
    try {
      const url = `${this.baseUrl}/sentiment/${encodeURIComponent(token)}`;

      const headerCandidates: Array<Record<string, string>> = [];
      if (this.apiKey) {
        headerCandidates.push({ Authorization: `Bearer ${this.apiKey}` });
        headerCandidates.push({ 'X-API-Key': this.apiKey });
        headerCandidates.push({ 'x-api-key': this.apiKey });
      }

      let response: any = null;
      let lastError: any = null;

      for (const headers of headerCandidates.length ? headerCandidates : [{}]) {
        try {
          response = await axios.get(url, { headers, timeout: 15000 });
          break;
        } catch (e) {
          lastError = e;
        }
      }

      if (!response) throw lastError;

      return {
        token,
        score: response.data.score,
        timestamp: Date.now(),
        sources: response.data.sources || []
      };
    } catch (error) {
      console.error('Cryptoracle error');
      return { token, score: 50, timestamp: Date.now(), sources: [] };
    }
  }
}
