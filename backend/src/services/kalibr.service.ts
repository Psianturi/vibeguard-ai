import axios from 'axios';
import { RiskAnalysis, SentimentData, PriceData } from '../types';

export class KalibrService {
  private apiKey: string;
  private tenantId: string;
  private intelligenceUrl: string;
  private goal: string;
  private googleApiKey: string;
  private modelHigh: string;
  private modelLow: string;
  private sentimentBadThreshold: number;

  constructor() {
    this.apiKey = process.env.KALIBR_API_KEY || '';
    this.tenantId = process.env.KALIBR_TENANT_ID || '';
    this.intelligenceUrl = process.env.KALIBR_INTELLIGENCE_URL || 'https://kalibr-intelligence.fly.dev';
    this.goal = process.env.KALIBR_GOAL || 'vibeguard_risk';
    this.googleApiKey = process.env.GOOGLE_API_KEY || process.env.GEMINI_API_KEY || '';
    this.modelHigh = process.env.KALIBR_MODEL_HIGH || 'gemini-1.5-pro';
    this.modelLow = process.env.KALIBR_MODEL_LOW || 'gemini-2.0-flash';
    this.sentimentBadThreshold = Number(process.env.SENTIMENT_BAD_THRESHOLD ?? 30);
  }

  private formatAxiosError(error: any): string {
    const status = error?.response?.status;
    const statusText = error?.response?.statusText;
    const message = error?.message;
    const providerMsg = error?.response?.data?.error?.message;
    return [
      status ? `status ${status}` : null,
      statusText,
      providerMsg,
      message
    ]
      .filter(Boolean)
      .join(' - ');
  }

  private getKalibrHeaders() {
    return {
      'X-API-Key': this.apiKey,
      'X-Tenant-ID': this.tenantId,
      'Content-Type': 'application/json'
    };
  }

  private async registerPathsIfPossible() {
    if (!this.apiKey || !this.tenantId) return;

    const models = Array.from(new Set([this.modelHigh, this.modelLow].filter(Boolean)));
    await Promise.all(
      models.map(async (modelId) => {
        try {
          await axios.post(
            `${this.intelligenceUrl}/api/v1/routing/paths`,
            { goal: this.goal, model_id: modelId },
            { headers: this.getKalibrHeaders(), timeout: 15000 }
          );
        } catch {
          // Ignore: path registration can be idempotent or may already exist.
        }
      })
    );
  }

  private async decideModel(): Promise<{ traceId: string; modelId: string } | null> {
    if (!this.apiKey || !this.tenantId) return null;

    await this.registerPathsIfPossible();

    const res = await axios.post(
      `${this.intelligenceUrl}/api/v1/routing/decide`,
      { goal: this.goal },
      { headers: this.getKalibrHeaders(), timeout: 15000 }
    );

    const data = res.data ?? {};
    const traceId = data.trace_id || data.traceId || (globalThis.crypto?.randomUUID?.() ?? String(Date.now()));
    const modelId = data.model_id || data.modelId || data.recommended_model || this.modelLow;

    return { traceId, modelId };
  }

  private async reportOutcome(params: { traceId: string; modelId: string; success: boolean; reason?: string }) {
    if (!this.apiKey || !this.tenantId) return;

    try {
      await axios.post(
        `${this.intelligenceUrl}/api/v1/intelligence/report-outcome`,
        {
          trace_id: params.traceId,
          goal: this.goal,
          success: params.success,
          model_id: params.modelId,
          reason: params.reason
        },
        { headers: this.getKalibrHeaders(), timeout: 15000 }
      );
    } catch (e) {
      console.warn('Kalibr report-outcome failed');
    }
  }

  private async callGemini(modelId: string, prompt: string): Promise<string> {
    if (!this.googleApiKey) throw new Error('Missing GOOGLE_API_KEY (or GEMINI_API_KEY)');

    const modelPath = modelId.startsWith('models/') ? modelId : `models/${modelId}`;
    const url = `https://generativelanguage.googleapis.com/v1beta/${modelPath}:generateContent?key=${this.googleApiKey}`;

    const response = await axios.post(
      url,
      {
        contents: [{ role: 'user', parts: [{ text: prompt }] }]
      },
      { timeout: 30000 }
    );

    const text =
      response.data?.candidates?.[0]?.content?.parts?.[0]?.text ??
      response.data?.candidates?.[0]?.content?.parts?.map((p: any) => p?.text).filter(Boolean).join('\n');

    if (!text) throw new Error('Empty Gemini response');
    return String(text);
  }

  async analyzeRisk(sentiment: SentimentData, price: PriceData): Promise<RiskAnalysis> {
    // Prepare prompt once.
    const prompt = `Analyze crypto risk:
Token: ${sentiment.token}
Sentiment Score: ${sentiment.score}/100
Price Change 24h: ${price.priceChange24h}%
Volume 24h: $${price.volume24h}

Should we exit position? Respond with JSON: {riskScore: 0-100, shouldExit: boolean, reason: string}`;

    // If Kalibr tenant is configured, use Kalibr Intelligence to pick the model.
    let traceId: string = globalThis.crypto?.randomUUID?.() ?? String(Date.now());
    let chosenModel = sentiment.score < this.sentimentBadThreshold ? this.modelHigh : this.modelLow;

    try {
      const decision = await this.decideModel();
      chosenModel = decision?.modelId ?? chosenModel;
      traceId = decision?.traceId ?? traceId;

      const raw = await this.callGemini(chosenModel, prompt);

      // Gemini may wrap JSON in markdown; try to extract the first JSON object.
      const jsonMatch = raw.match(/\{[\s\S]*\}/);
      const jsonText = (jsonMatch ? jsonMatch[0] : raw).trim();

      const result = JSON.parse(jsonText);
      await this.reportOutcome({ traceId, modelId: chosenModel, success: true });

      return { ...result, aiModel: chosenModel };
    } catch (error) {
      const msg = this.formatAxiosError(error);
      console.error('Kalibr/Gemini error:', msg);

      await this.reportOutcome({
        traceId,
        modelId: chosenModel,
        success: false,
        reason: msg ? msg.slice(0, 120) : 'exception'
      });

      return {
        riskScore: 50,
        shouldExit: false,
        reason: msg ? `Analysis failed (${msg})` : 'Analysis failed',
        aiModel: chosenModel || 'fallback'
      };
    }
  }
}
