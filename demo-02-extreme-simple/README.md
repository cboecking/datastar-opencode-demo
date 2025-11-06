# demo-02-extreme-simple

The absolute minimal OpenCode + http-nu example.

## Features

- Auto-creates session on page load
- Single text input + submit button
- Real-time event stream
- ~50 lines total

## Usage

```bash
# Terminal 1: Start OpenCode
opencode serve --port 3030

# Terminal 2: Serve this demo
cd demo-02-extreme-simple
./run.sh
```

Open http://localhost:8080

## Files

- `index.html` - Entire app (HTML + CSS + JS)
- `server.nu` - 1-line http-nu handler
- `run.sh` - Start script

## How It Works

1. Page loads → auto-creates session via `POST /session`
2. User enters prompt → submits via `POST /session/:id/message`
3. Events stream via `EventSource('/event')`

That's it!
