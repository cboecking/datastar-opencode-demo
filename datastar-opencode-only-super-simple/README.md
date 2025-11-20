# Datastar + OpenCode Super Simple SSE Test

The **absolutely simplest** test of SSE compatibility between pure Datastar and pure OpenCode.

## What This Tests

1. **OpenCode API** - Connect to local OpenCode server at http://127.0.0.1:42992
2. **Datastar Frontend** - Pure hypermedia approach (no traditional frameworks)
3. **SSE Compatibility** - Both systems use `text/event-stream`

## Setup

### 1. Start OpenCode Server
```bash
cd /home/debian/code/vilara/vilara-chuck/opencode
opencode serve --port 42992
```

### 2. Open HTML File
```bash
# Just open in browser - no build step needed (pure Datastar!)
open datastar-opencode-demo/datastar-opencode-only-super-simple/index.html
```

Or use a simple HTTP server:
```bash
python3 -m http.server 8000
# Then navigate to http://localhost:8000
```

## How It Works

### Step 1: Create Session
- Click "Create Session"
- Executes: `POST /session`
- **Response:** JSON with `{id: "ses_...", ...}`
- Stores `sessionId` in signal

### Step 2: Send Prompt
- Click "Send Prompt"
- Executes: `POST /session/:id/message` with `{parts: [{type: 'text', text: '...'}]}`
- **Dual Response:**
  1. **Immediate JSON response:** `{info: {...}, parts: [...]}`
  2. **SSE stream events:** Real-time updates as AI processes

### Step 3: Listen to SSE
- Click "Start SSE Listener"
- Opens: `EventSource('http://127.0.0.1:42992/event')`
- **Receives events:**
  - `message.part.updated` - Reasoning and text chunks
  - `message.updated` - Message metadata updates
  - `session.updated` - Session state changes
  - `session.idle` - AI finished processing

## OpenCode Dual-Channel Pattern

**Critical Understanding:** OpenCode uses **two communication channels simultaneously:**

### Channel 1: Request/Response (HTTP)
```javascript
// POST returns immediate JSON response
POST /session/:id/message
→ Response: {
    info: {id: "msg_...", ...},
    parts: [{type: "text", text: "4"}]
  }
```

### Channel 2: Event Stream (SSE)
```javascript
// Long-lived SSE connection sends real-time updates
GET /event
→ Stream of events:
   event: message.part.updated
   data: {type: "reasoning", text: "..."}

   event: message.part.updated
   data: {type: "text", text: "4"}

   event: session.idle
```

### Why Both?

1. **POST response** - Get message ID immediately, know request was accepted
2. **SSE stream** - Watch AI think in real-time (reasoning, partial responses, etc.)
3. **Final state** - POST response contains final result AFTER stream completes

**This is different from pure Datastar**, which expects:
- Single SSE response with `datastar-patch-elements` events
- No separate JSON response channel

## Key Observations

**Protocol Match:**
- ✅ OpenCode produces `text/event-stream`
- ✅ Datastar consumes `text/event-stream`
- ✅ Both use standard SSE format

**Semantic Difference:**
- ❌ OpenCode events are JSON (application state)
- ❌ Datastar events should be HTML patches
- ⚠️ This test shows RAW events, not HTML patches

## Next Steps

To make this truly work with Datastar's hypermedia model:
1. Create an endpoint that transforms OpenCode events → HTML fragments
2. Emit `datastar-patch-elements` events with `<div>` updates
3. Let Datastar morph the DOM reactively

## Notes

- **No build step** - Pure HTML + Datastar CDN
- **No frameworks** - Just `data-*` attributes
- **No JavaScript files** - All logic in HTML
- **Pure Datastar** - Following hypermedia-first principles

---

## Important Fix: Reading Textarea Values

### The Problem We Encountered

Initially, we tried to use Datastar's `data-bind:promptText` signal binding:

```html
<!-- Textarea with binding -->
<textarea data-bind:promptText>Hello from Datastar! What is 2+2?</textarea>

<!-- Button trying to use signal -->
<button data-on:click="...body: JSON.stringify({parts: [{type: 'text', text: $promptText}]})">
```

**This failed because:**
1. The `$promptText` signal was empty when the button was clicked
2. OpenCode received `{text: ""}` (empty text)
3. Error: "Each message must have at least one content element"

**Why:** Datastar's `data-bind` didn't properly initialize the signal from the textarea's initial content. The binding works for updates (when you type), but the initial value wasn't captured.

### The Solution

**Read the textarea value directly from the DOM:**

```javascript
// Button reads actual DOM element value
const promptValue = document.getElementById('prompt-input').value;
...body: JSON.stringify({parts: [{type: 'text', text: promptValue}]})
```

**How it works:**
1. ✅ Textarea has default content between tags
2. ✅ Button reads current value directly: `element.value`
3. ✅ No signal dependency - just regular DOM access
4. ✅ Sends whatever is currently in the textarea

### Is This a Hack or The Right Approach?

**Important Disclaimer:** We don't yet know if this direct DOM access is:
- ❓ A "hack" because we haven't learned Datastar's proper signal initialization pattern
- ❓ The correct approach for simple, one-time reads like form submission
- ❓ Appropriate for this basic example but signals would be better in complex apps

**We're still learning Datastar!** There may be a proper way to initialize signals from textarea content that we haven't discovered. This solution works reliably for our simple test case.

### The Lesson (Tentative)

**Datastar signals** are powerful for reactive UI updates across multiple elements. But for **simple read operations** (like getting a form value on submit), **direct DOM access** might be:
- **Simpler** - Less abstraction to debug
- **More reliable** - No initialization timing issues (in our basic example)
- **Easier to understand** - Standard JavaScript

**When to use each (our current understanding):**
- **Use signals (`data-bind`):** When you need reactive updates across multiple elements
- **Use direct DOM access:** When you just need to read a value once (or when signals aren't initializing properly)

As we learn more about Datastar, we may update this approach!

### Update: Found the Datastar Pattern!

After researching the Datastar documentation, we discovered the `__ifmissing` signal modifier:

**The proper Datastar way:**
```html
<!-- Set default signal value only if missing -->
<div data-signals__ifmissing="{promptText: 'Hello from Datastar! What is 2+2?'}">
  <textarea data-bind:promptText></textarea>
</div>
```

**What `__ifmissing` does:**
- Sets a signal value ONLY if it doesn't already exist
- Useful for providing defaults without overwriting user input
- Can be used in both HTML attributes and SSE events

**Reference:** https://data-star.dev/examples/signals_ifmissing

This is the proper pattern we should have used! The `__ifmissing` modifier ensures the signal has a default value that `data-bind` can work with. We'll test this pattern in future examples to confirm it works correctly.
