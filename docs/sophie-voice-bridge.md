# Sophie Voice Bridge

ElevenLabs Custom LLM server that enables voice calls with Sophie AI.

**Repository:** https://github.com/aaron777collins/sophie-voice-bridge

## Overview

The Sophie Voice Bridge allows you to have voice conversations with Sophie via WhatsApp calls. It uses ElevenLabs' Conversational AI platform for speech-to-text and text-to-speech, with Sophie as the brain.

## Architecture

```
WhatsApp Call → ElevenLabs (STT/TTS) → Haiku (fast) ─┬─→ Direct response
                                                      │
                                                      └─→ ask_sophie → Sophie/Opus
                                                                          (full capabilities)
```

**Two-layer design:**
- **Haiku**: Fast voice responses (1-3 sentences, conversational)
- **Sophie (Opus)**: Complex questions via `ask_sophie` tool (calendar, email, research, etc.)

## Quick Setup

### Prerequisites
- Clawdbot running with HTTP endpoint enabled
- Docker and Docker Compose
- ElevenLabs account
- Twilio account with WhatsApp-enabled number

### 1. Deploy the Bridge

```bash
git clone https://github.com/aaron777collins/sophie-voice-bridge.git
cd sophie-voice-bridge

# Configure
cat > .env << EOF
CLAWDBOT_GATEWAY_URL=http://localhost:18789
CLAWDBOT_GATEWAY_TOKEN=your-token
EOF

# Run
docker compose up -d
```

### 2. Enable Clawdbot HTTP Endpoint

```bash
clawdbot config set gateway.http.endpoints.chatCompletions.enabled true
```

### 3. Set Up Caddy (HTTPS)

Add to your Caddyfile:
```
voice.yourdomain.com {
    reverse_proxy 172.18.0.1:8013
}
```

Reload Caddy:
```bash
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
```

### 4. Configure ElevenLabs

1. Create Agent at https://elevenlabs.io/app/agents
2. LLM Settings:
   - Server URL: `https://voice.yourdomain.com`
   - Model: anything (ignored)
   - Enable "Custom LLM extra body"
3. Connect Twilio phone number with WhatsApp

## How ask_sophie Works

Haiku automatically escalates to Sophie when you ask about:
- Calendar, schedule, events
- Emails, messages
- Files, documents, code
- Web research
- Complex technical questions
- Anything requiring memory or tools

Simple questions (greetings, math, general knowledge) are handled by Haiku directly for fast responses.

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `POST /chat/completions` | ElevenLabs format |
| `POST /v1/chat/completions` | OpenAI standard |
| `GET /health` | Health check |

## Environment Variables

| Variable | Description |
|----------|-------------|
| `CLAWDBOT_GATEWAY_URL` | Clawdbot HTTP endpoint (default: `http://localhost:18789`) |
| `CLAWDBOT_GATEWAY_TOKEN` | Gateway auth token |

## Troubleshooting

**Bridge can't reach Clawdbot:**
- Uses `network_mode: host` so it can access localhost:18789
- Ensure Clawdbot HTTP endpoint is enabled

**SSL issues:**
- Caddy handles SSL automatically
- Wait a few seconds for cert provisioning on first request

**Slow responses:**
- Simple questions should be fast (Haiku)
- Complex questions take longer (Sophie/Opus + tools)
