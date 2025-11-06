# demo-03-true-datastar

Learning Datastar's natural patterns and integrating with OpenCode AI.

## What We Learned

### Datastar Fundamentals

**Datastar is server-driven hypermedia**, not a client-side framework. It's designed for backends that speak its SSE protocol.

1. **Signals** - Reactive state declared in HTML
   ```html
   <body data-signals='{"count": 0, "name": ""}'>
   ```

2. **Reactive Bindings**
   - `data-text="$count"` - Display signal
   - `data-bind="name"` - Two-way input binding
   - `data-show="$sessionId"` - Conditional rendering
   - `data-attr:disabled="$loading"` - Dynamic attributes

3. **Backend Actions**
   ```html
   <button data-on:click="@post('/endpoint')">Click</button>
   ```
   Sends ALL signals to backend as JSON

4. **SSE Protocol** - Backend responds with:
   ```
   event: datastar-patch-signals
   data: signals {"fieldName": "value"}
   ```

### http-nu Integration

**http-nu is Nushell-scriptable HTTP server**

1. **Response metadata** - Use `.response` command
   ```nushell
   .response {headers: {"content-type": "text/event-stream"}}
   "body content"
   ```

2. **SSE formatting** - Use `to sse` for records
   ```nushell
   {event: "datastar-patch-signals", data: "signals {...}"} | to sse
   ```

3. **Request handling** - Capture `$in` at closure level
   ```nushell
   {|req|
       let body = $in
       if ($req.path == "/endpoint") { ... }
   }
   ```

## Current Implementation

### What Works ✅

1. **Session Creation** - Creates OpenCode session via API
2. **Datastar Reactivity** - UI updates on signal changes
3. **Form Submission** - Sends prompts to OpenCode
4. **http-nu Middleware** - Routes requests, transforms responses

### Architecture

```
Browser (Datastar)
    ↓ @post('/create-session')
http-nu (Nushell)
    ↓ curl POST
OpenCode API
    ↓ {"id": "ses_..."}
http-nu
    ↓ SSE: signals {"sessionId": "..."}
Datastar → Updates UI
```

## The Streaming Challenge

### Problem

OpenCode provides SSE at `/event` but:

1. **Broadcasts ALL sessions** - Not filtered by session ID
2. **Never closes** - Stream runs forever
3. **Nushell buffering** - `| lines` waits for stream to close before processing

### Attempted Solutions

**Approach 1: Direct transformation**
```nushell
curl -N $"($OPENCODE_API)/event"
| lines
| each { |line| ... } # Buffers until stream closes!
```
❌ Blocked by nushell pipeline buffering

**Approach 2: Timeout**
```nushell
curl --max-time 10 ...
```
❌ Either times out early or waits full duration

**Approach 3: Manual SSE formatting**
```nushell
| str join # Still buffers
```
❌ Same buffering issue

### Root Cause

Nushell's `| lines` is designed for finite streams. OpenCode's SSE is infinite. There's a fundamental impedance mismatch.

## Options Forward

### Option A: Hybrid Approach (Recommended)

**Keep Datastar for UI, add minimal JavaScript for SSE**

```html
<script>
// Only handles SSE connection
const eventSource = new EventSource('http://localhost:3030/event');
eventSource.onmessage = (e) => {
    const event = JSON.parse(e.data);
    if (event.type === 'message.part.updated' && event.properties.part.sessionId === sessionId) {
        // Update Datastar signal manually
        document.querySelector('body').dataset.signals = JSON.stringify({
            ...currentSignals,
            response: event.properties.part.text
        });
    }
};
</script>
```

**Pros:**
- Works with OpenCode's existing SSE stream
- Still uses Datastar for all UI reactivity
- Minimal JavaScript (~20 lines)
- Real-time streaming

**Cons:**
- Not "pure" Datastar server-driven
- Requires understanding Datastar's internal signal storage

### Option B: Polling

Have client poll for updates instead of streaming.

```html
<button data-on:click="@post('/send-prompt'); setInterval(() => @get('/check-response'), 1000)">
```

**Pros:**
- No streaming complexity
- Pure Datastar

**Cons:**
- Not real-time
- More server load
- Polling feels dated

### Option C: Backend Transformation Service

Create a dedicated service that:
1. Subscribes to OpenCode `/event`
2. Filters by session
3. Transforms to Datastar SSE format
4. Provides session-specific endpoints

**Pros:**
- Pure Datastar from client perspective
- Proper separation of concerns

**Cons:**
- More infrastructure complexity
- Another service to maintain

### Option D: Keep Simple

Accept that streaming is complex and just return "Message sent!"

**Pros:**
- Simple, works now
- Proves the Datastar + http-nu pattern

**Cons:**
- No real AI response visible
- Not a complete demo

## Recommendation

**Option A (Hybrid)** is most pragmatic:

1. Datastar handles 95% of the app (UI reactivity, forms, routing)
2. JavaScript handles the 5% that's browser-specific (EventSource API)
3. This is actually how Datastar is meant to work with custom event sources

The key insight: **Datastar is not meant to eliminate ALL JavaScript**, it's meant to eliminate manual DOM manipulation and reactive state management. Using EventSource for SSE is a browser API, not DOM manipulation.

## Files

- `index.html` - Datastar UI with reactive signals
- `server.nu` - http-nu routing and OpenCode integration
- `run.sh` - Start the demo server

## Usage

```bash
# Terminal 1: Start OpenCode
opencode serve --port 3030

# Terminal 2: Start demo
cd demo-03-true-datastar
./run.sh

# Browser
open http://localhost:8080
```

## Next Steps

If pursuing Option A:
1. Add EventSource connection in `<script>` tag
2. Filter events by sessionId
3. Update Datastar signals on message receipt
4. Keep all other Datastar reactivity unchanged
