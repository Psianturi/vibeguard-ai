import { Router } from 'express';
import { CryptoracleService } from '../services/cryptoracle.service';
import { CoinGeckoService } from '../services/coingecko.service';
import { KalibrService } from '../services/kalibr.service';
import { BlockchainService } from '../services/blockchain.service';
import { loadSubscriptions, upsertSubscription } from '../storage/subscriptions';
import { appendTxHistory, loadTxHistory } from '../storage/txHistory';
import { runMonitorOnce } from '../monitor/vibeMonitor';
import { ethers } from 'ethers';

const router = Router();
const cryptoracle = new CryptoracleService();
const coingecko = new CoinGeckoService();
const kalibr = new KalibrService();
const blockchain = new BlockchainService();

router.get('/debug/models', async (req, res) => {
  const debugEnabled = String(process.env.DEBUG || '').toLowerCase() === 'true';
  if (!debugEnabled) {
    return res.status(404).json({ error: 'Not found' });
  }

  try {
    const models = await kalibr.listGeminiGenerateContentModels();
    res.json({ ok: true, count: models.length, models });
  } catch (error: any) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

router.get('/public-config', (req, res) => {

  return res.json({
    ok: true,
    walletConnectProjectId: String(process.env.WALLETCONNECT_PROJECT_ID || '').trim()
  });
});

router.get('/token-presets', (req, res) => {
  const raw = String(process.env.TOKEN_PRESETS_JSON || '').trim();
  if (!raw) {
    return res.json({ ok: true, items: [] });
  }

  try {
    const parsed = JSON.parse(raw);
    const items = Array.isArray(parsed) ? parsed : (Array.isArray(parsed?.items) ? parsed.items : []);

    const chainIdQuery = String(req.query.chainId || '').trim();
    const chainId = chainIdQuery ? Number(chainIdQuery) : null;

    const normalized = items
      .map((it: any) => {
        const address = String(it?.address || it?.tokenAddress || '').trim();
        const chainIdVal = Number(it?.chainId);
        const symbol = String(it?.symbol || '').trim().toUpperCase();
        const name = String(it?.name || symbol).trim();
        const decimals = it?.decimals != null ? Number(it.decimals) : null;
        const coinGeckoId = String(it?.coinGeckoId || it?.coingeckoId || '').trim().toLowerCase();

        return {
          chainId: Number.isFinite(chainIdVal) ? chainIdVal : null,
          symbol,
          name,
          address: ethers.isAddress(address) ? address : '',
          decimals: Number.isFinite(decimals as any) ? decimals : null,
          coinGeckoId: coinGeckoId || null
        };
      })
      .filter((it: any) => it.symbol && it.address && it.chainId != null);

    const filtered = chainId != null
      ? normalized.filter((it: any) => it.chainId === chainId)
      : normalized;

    return res.json({ ok: true, items: filtered });
  } catch (e: any) {
    return res.status(400).json({ ok: false, error: 'Invalid TOKEN_PRESETS_JSON' });
  }
});

router.post('/check', async (req, res) => {
  try {
    const { token, tokenId } = req.body;

    const [sentiment, price] = await Promise.all([
      cryptoracle.getSentiment(token),
      coingecko.getPrice(tokenId)
    ]);

    const analysis = await kalibr.analyzeRisk(sentiment, price);

    res.json({ sentiment, price, analysis });
  } catch (error: any) {
    const status = error?.response?.status;
    const msg = String(error?.message || 'Request failed');

    if (status === 429 || msg.includes('status 429')) {
      return res.status(429).json({ error: 'Rate limited by upstream provider. Please retry in a moment.' });
    }

    if (msg.toLowerCase().includes('Missing data for tokenid')) {
      return res.status(400).json({ error: 'Invalid Token or Coin ID. Please pick a valid coin id (e.g. bitcoin, ethereum).' });
    }

    res.status(500).json({ error: msg });
  }
});

router.get('/prices', async (req, res) => {
  try {
    const idsRaw = String(req.query.ids || '').trim();
    const tokenIds = idsRaw
      ? idsRaw.split(',').map((s) => s.trim()).filter(Boolean)
      : ['bitcoin', 'binancecoin', 'ethereum', 'tether'];

    const items = await coingecko.getPrices(tokenIds);
    res.json({ ok: true, items, updatedAt: Date.now() });
  } catch (error: any) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

router.post('/execute-swap', async (req, res) => {
  try {
    const { userAddress, tokenAddress, amount } = req.body;
    const result = await blockchain.emergencySwap(userAddress, tokenAddress, amount);

    if (result?.success && result?.txHash && userAddress && tokenAddress) {
      appendTxHistory({
        userAddress,
        tokenAddress,
        txHash: result.txHash,
        timestamp: Date.now(),
        source: 'manual'
      });
    }

    res.json(result);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/tx-history', (req, res) => {
  const userAddress = String(req.query.userAddress || '').trim();
  if (!userAddress) {
    return res.status(400).json({ ok: false, error: 'Missing userAddress query param' });
  }

  const limit = req.query.limit ? Number(req.query.limit) : undefined;
  const items = loadTxHistory({ userAddress, limit });
  return res.json({ ok: true, items });
});

router.get('/subscriptions', (req, res) => {
  res.json(loadSubscriptions());
});

router.post('/subscribe', (req, res) => {
  const {
    userAddress,
    tokenSymbol,
    tokenId,
    tokenAddress,
    amount,
    enabled = true,
    riskThreshold = 80
  } = req.body;

  if (!userAddress || !tokenSymbol || !tokenId || !tokenAddress || !amount) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  const sub = upsertSubscription({
    userAddress,
    tokenSymbol,
    tokenId,
    tokenAddress,
    amount,
    enabled: Boolean(enabled),
    riskThreshold: Number(riskThreshold)
  });

  res.json({ ok: true, subscription: sub });
});

router.post('/run-once', async (req, res) => {
  try {
    const result = await runMonitorOnce();
    res.json({ ok: true, result });
  } catch (error: any) {
    res.status(500).json({ ok: false, error: error.message });
  }
});


// Get detailed sentiment insights for a single token
router.post('/insights', async (req, res) => {
  try {
    const { token, window = 'Daily' } = req.body;

    if (!token) {
      return res.status(400).json({ error: 'Missing token parameter' });
    }

    const symbol = String(token || '').trim().toUpperCase();
    const symbolToCoinId: Record<string, string> = {
      BTC: 'bitcoin',
      ETH: 'ethereum',
      BNB: 'binancecoin',
      USDT: 'tether',
      SOL: 'solana',
      XRP: 'ripple',
      DOGE: 'dogecoin',
      SUI: 'sui'
    };
    const coinId = symbolToCoinId[symbol] || String(token || '').trim().toLowerCase();

    const [enhanced, price] = await Promise.all([
      cryptoracle.getEnhancedSentiment(symbol, window),
      coingecko.getPrice(coinId)
    ]);

    let vibeScore = 50;
    let finalEnhanced;
    
    if (enhanced && enhanced.sentiment) {
      finalEnhanced = enhanced;
      vibeScore = Math.round((enhanced.sentiment.positive * 100));
    } else {
 
      finalEnhanced = _generateFallbackData(token.toUpperCase());
      vibeScore = Math.round(finalEnhanced.sentiment.positive * 100);
    }

    res.json({ 
      token: symbol,
      window,
      enhanced: finalEnhanced, 
      price,
      vibeScore,
      source: enhanced && enhanced.sentiment ? 'cryptoracle' : 'fallback'
    });
  } catch (error: any) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

// Get multi-token sentiment dashboard
router.post('/multi', async (req, res) => {
  try {
    const { tokens, window = 'Daily' } = req.body;

    const tokenList = tokens && Array.isArray(tokens) 
      ? tokens 
      : ['BTC', 'BNB', 'ETH', 'SOL', 'XRP', 'DOGE', 'SUI', 'USDT'];

    const results = await cryptoracle.getMultiTokenSentiment(tokenList, window);

    const data: Record<string, any> = {};
    
    // Generate fallback data if Cryptoracle returns null data
    const hasValidData = Array.from(results.values()).some(v => v !== null && v?.sentiment);
    
    tokenList.forEach((token) => {
      const result = results.get(token.toUpperCase());
      
      if (result && result.sentiment) {
 
        data[token.toUpperCase()] = {
          sentiment: {
            positive: result.sentiment.positive,
            negative: result.sentiment.negative,
            sentimentDiff: result.sentiment.sentimentDiff,
          },
          community: result.community,
          signals: result.signals,
          timestamp: result.timestamp,
        };
      } else {
        data[token.toUpperCase()] = _generateFallbackData(token.toUpperCase());
      }
    });

    res.json({ 
      ok: true, 
      window,
      tokens: data,
      updatedAt: Date.now(),
      source: hasValidData ? 'cryptoracle' : 'fallback'
    });
  } catch (error: any) {
    res.status(500).json({ ok: false, error: error.message });
  }
});


function _generateFallbackData(token: string): any {
  // Seed-based pseudo-random for consistency
  const seed = token.split('').reduce((a, c) => a + c.charCodeAt(0), 0);
  const random = (i: number) => ((seed * 9301 + 49297) % 233280) / 233280 * i;
  
  const baseSentiment = 0.4 + random(0.4); // 0.4 - 0.8 range
  
  return {
    sentiment: {
      positive: baseSentiment,
      negative: 1 - baseSentiment,
      sentimentDiff: (random(0.2) - 0.1), // -0.1 to +0.1
    },
    community: {
      totalMessages: Math.floor(random(50000) + 10000),
      interactions: Math.floor(random(100000) + 20000),
      mentions: Math.floor(random(30000) + 5000),
      uniqueUsers: Math.floor(random(10000) + 2000),
      activeCommunities: Math.floor(random(50) + 10),
    },
    signals: {
      deviation: random(0.3) - 0.15,
      momentum: random(0.5) - 0.25,
      breakout: random(0.2),
      priceDislocation: random(0.1),
    },
    timestamp: Date.now(),
    isFallback: true,
  };
}

router.get('/chains', (req, res) => {
  res.json({
    ok: true,
    chains: [
      {
        id: 'bitcoin',
        name: 'Bitcoin',
        symbol: 'BTC',
        network: 'Bitcoin',
        icon: '₿'
      },
      {
        id: 'binancecoin',
        name: 'BNB',
        symbol: 'BNB',
        network: 'BNB Chain',
        icon: 'B'
      },
      {
        id: 'binancecoin',
        name: 'BNB',
        symbol: 'BNB',
        network: 'opBNB',
        icon: '🔷'
      },
      {
        id: 'ethereum',
        name: 'Ethereum',
        symbol: 'ETH',
        network: 'Ethereum',
        icon: 'Ξ'
      },
      {
        id: 'solana',
        name: 'Solana',
        symbol: 'SOL',
        network: 'Solana',
        icon: '◎'
      },
      {
        id: 'ripple',
        name: 'XRP',
        symbol: 'XRP',
        network: 'XRP Ledger',
        icon: '✕'
      },
      {
        id: 'dogecoin',
        name: 'Dogecoin',
        symbol: 'DOGE',
        network: 'Dogecoin',
        icon: 'Ð'
      },
      {
        id: 'sui',
        name: 'Sui',
        symbol: 'SUI',
        network: 'Sui',
        icon: '⚡'
      },
      {
        id: 'tether',
        name: 'Tether',
        symbol: 'USDT',
        network: 'Multi-chain',
        icon: '₮'
      }
    ]
  });
});

export default router;
