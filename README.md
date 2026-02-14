# VibeShield AI 🛡️

"Sell the Rumor, Protect the Vibe." - An AI Agent that listens to market whispers before the charts do.

**Tagline:** *"Sell the Rumor, Protect the Vibe."*

AI-powered crypto portfolio guardian that monitors social sentiment and executes emergency swaps before crashes happen.

## Good Vibes Only (BNB Chain)

### Tech Stack
- **Backend:** Node.js + TypeScript + Express.js (Railway)
- **Frontend:** Flutter (Web + Mobile)
- **State Management:** Riverpod 2.x
- **Blockchain:** BNB Chain (BSC/opBNB)
- **AI:** Kalibr Systems (model routing; configured via env)
- **Data:** Cryptoracle + CoinGecko

### Live Backend
- Base URL: https://vibeguard-ai-production.up.railway.app
- Health: https://vibeguard-ai-production.up.railway.app/health

## Quick Start

### Backend
```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your API keys
npm run dev
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run -d chrome  # Web
flutter run            # Mobile
```

## Project Structure
```
vibeshield-ai/
├── backend/           # Node.js API (Express + TS) + monitor loop
├── contracts/         # VibeShieldVault (non-custodial) + Hardhat scripts
├── frontend/          # Flutter app (vibeshield_app)
├── railway.json       # Railway config-as-code (DOCKERFILE)
├── railway.toml       # Railway config-as-code (dockerfile)
├── .dockerignore      # Shrinks Docker build context
└── README.md
```

## Core Features
1. Real-time sentiment monitoring (Cryptoracle)
2. AI-powered risk analysis (Kalibr)
3. Non-custodial emergency swap trigger (via on-chain vault)
4. Vibe Meter dashboard
5. Multi-agent strategy (Bull vs Bear)

## What’s actually implemented
- **Backend API** running on Railway with `/health` and `/api/vibe/*` routes.
- **Risk pipeline (API-level):** `/api/vibe/check` calls Cryptoracle + CoinGecko, then sends a prompt to Kalibr and returns `{ sentiment, price, analysis }`.
- **Non-custodial execution (contract + API):** the backend can call the vault function `executeEmergencySwap(user, token, amountIn)` and returns a `txHash` on success.
- **Multi-user subscriptions:** `/api/vibe/subscribe`, `/api/vibe/subscriptions`, and `/api/vibe/run-once`.



---

