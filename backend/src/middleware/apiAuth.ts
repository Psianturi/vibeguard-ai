import { Request, Response, NextFunction } from 'express';
import crypto from 'node:crypto';

const DEFAULT_MAX_SKEW_MS = 5 * 60 * 1000;

function getHeader(req: Request, name: string): string {
  const value = req.headers[name.toLowerCase()];
  if (Array.isArray(value)) return value[0] ?? '';
  return String(value ?? '').trim();
}

function buildPayload(req: Request): string {
  const method = String(req.method || '').toUpperCase();
  const path = String(req.originalUrl || req.url || '').split('?')[0];
  const body = req.body == null
    ? ''
    : (typeof req.body === 'string' ? req.body : JSON.stringify(req.body));

  return `${method}:${path}:${body}`;
}

function safeEqual(a: string, b: string): boolean {
  const ab = Buffer.from(a, 'utf8');
  const bb = Buffer.from(b, 'utf8');
  if (ab.length !== bb.length) return false;
  return crypto.timingSafeEqual(ab, bb);
}

export function requireApiAuth(req: Request, res: Response, next: NextFunction) {
  const apiKey = String(process.env.VIBE_API_KEY || '').trim();
  if (!apiKey) {
    return res.status(500).json({ error: 'Server missing VIBE_API_KEY' });
  }

  const tsRaw = getHeader(req, 'x-api-ts');
  const key = getHeader(req, 'x-api-key');
  const sign = getHeader(req, 'x-api-sign');

  if (!tsRaw || !key || !sign) {
    return res.status(401).json({ error: 'Missing API auth headers' });
  }

  if (key !== apiKey) {
    return res.status(401).json({ error: 'Invalid API key' });
  }

  const ts = Number(tsRaw);
  if (!Number.isFinite(ts)) {
    return res.status(401).json({ error: 'Invalid timestamp' });
  }

  const maxSkewMs = Number(process.env.VIBE_API_AUTH_MAX_SKEW_MS || DEFAULT_MAX_SKEW_MS);
  if (Math.abs(Date.now() - ts) > maxSkewMs) {
    return res.status(401).json({ error: 'Timestamp out of range' });
  }

  const payload = `${tsRaw}:${buildPayload(req)}`;
  const expected = crypto
    .createHmac('sha256', apiKey)
    .update(payload)
    .digest('hex');

  if (!safeEqual(expected, sign)) {
    return res.status(401).json({ error: 'Invalid signature' });
  }

  return next();
}
