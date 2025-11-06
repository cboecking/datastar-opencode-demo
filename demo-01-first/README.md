# Datastar + OpenCode Minimal Demo

A minimal implementation showing Datastar connecting to an OpenCode API server.

## What This Demonstrates

- **Datastar**: Minimal reactive frontend using `data-*` attributes
- **OpenCode API**: Connection to `opencode serve` SSE event stream
- **Real-time Updates**: Live event streaming from OpenCode to the browser

## Prerequisites

1. **OpenCode** - Must be installed and available
2. **http-nu** - For serving the HTML file (`cargo install http-nu`)

## Quick Start

### Terminal 1: Start OpenCode Server

```bash
opencode serve --port 3030
```

This starts the OpenCode API server on `http://localhost:3030`.

### Terminal 2: Serve the HTML File

```bash
cd /home/debian/code/vilara/vilara-chuck/datastar-opencode-demo/demo-01-first
./run.sh
```

Then open: **http://localhost:8080**

### Alternative: Manual http-nu

```bash
cat server.nu | http-nu :8080 -
```

**Note**: http-nu expects a Nushell closure, not raw HTML. The `server.nu` file contains the routing logic.

## Using the Demo

Once running, you'll see:

1. **Connection Status**: Shows if connected to OpenCode API
2. **Session Management**:
   - Click "Create Session" to start a new OpenCode session
   - Session ID will be displayed
   - Buttons become enabled after session creation
3. **Send Prompt**:
   - Enter any prompt/question in the textarea
   - Click "Send Prompt" to send to OpenCode
4. **OpenCode Events**: Live stream of ALL events from the OpenCode server via SSE

### Workflow

1. Click **"Create Session"** - This calls `POST /session` and stores the session ID
2. Enter a prompt like "What is 2+2?" in the textarea
3. Click **"Send Prompt"** - This calls `POST /session/:id/message`
4. Watch the **OpenCode Events** section for real-time event stream updates

## Architecture

```
Browser (:8080)                    OpenCode API (:3030)
    ↓                                      ↓
index.html ←─ http-nu              Hono Server
    ↓                                      ↓
JavaScript                          ┌──────────────┐
    │                               │              │
    ├─ POST /session ───────────────→ Create Session
    │                               │  (returns ID)
    │                               │              │
    ├─ POST /session/:id/message ──→ Send Message  │
    │                               │  (AI response)│
    │                               │              │
    └─ EventSource(/event) ←────────┤ SSE Stream   │
       (Real-time events)           │ (Bus.subscribeAll)
                                    └──────────────┘
```

## What's Happening

1. **http-nu** serves the static HTML file
2. Browser loads **Datastar** from CDN (for future reactive features)
3. JavaScript establishes **EventSource** connection to `GET /event` (SSE stream)
4. User clicks **"Create Session"** → `POST /session` → receives session ID
5. User sends prompt → `POST /session/:id/message` → AI processes
6. **All events** flow through OpenCode's event bus → streamed to browser via SSE
7. Browser displays events in real-time

## Customization

### Change OpenCode URL

Edit `index.html` line ~85:

```javascript
const OPENCODE_URL = 'http://localhost:3030';
```

### Add More Datastar Features

This demo is intentionally minimal. See [Datastar docs](https://data-star.dev) for:
- Form handling
- API requests with `@post()`
- Reactive computations
- View transitions
- And more...

## Files

- `index.html` - Single-file Datastar application
- `server.nu` - Nushell closure for http-nu routing
- `README.md` - This file
- `run.sh` - Convenience script to start everything

## Next Steps

To extend this demo:

1. Add OpenCode API calls (POST /session, etc.)
2. Use Datastar's `@post()` action to interact with OpenCode
3. Build a chat interface for the OpenCode agent
4. Stream agent responses using SSE

## Learn More

- [Datastar Documentation](https://data-star.dev)
- [OpenCode Repository](https://github.com/sst/opencode)
- [http-nu Repository](https://github.com/cablehead/http-nu)
