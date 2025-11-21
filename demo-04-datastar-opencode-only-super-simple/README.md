# Datastar + OpenCode Super Simple SSE Test

The **absolutely simplest** test of SSE compatibility between pure Datastar and pure OpenCode.

**Current Implementation:** Uses the **data-init auto-connect pattern** (Experiment 2 winner) - the most "Datastar purist" approach that actually works with OpenCode's JSON events.

## What This Tests

1. **OpenCode API** - Connect to local OpenCode server at http://127.0.0.1:42992
2. **Datastar Frontend** - Pure hypermedia approach with reactive patterns
3. **SSE Compatibility** - Both systems use `text/event-stream`
4. **Reactive Integration** - Auto-connect SSE using `data-init` when session exists

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

**Reactive Pattern:** SSE auto-connects when session is created (no manual steps!)

### Step 1: Create Session
- Click "Create Session"
- Executes: `POST /session`
- **Response:** JSON with `{id: "ses_...", ...}`
- Stores `sessionId` in signal
- **Automatic:** SSE connection triggers via `data-init` when `$sessionId` becomes non-empty

### Step 2: Send Prompt
- Click "Send Prompt"
- Executes: `POST /session/:id/message` with `{parts: [{type: 'text', text: '...'}]}`
- **Dual Response:**
  1. **Immediate JSON response:** `{info: {...}, parts: [...]}`
  2. **SSE stream events:** Real-time updates as AI processes (already connected!)

### SSE Auto-Connection (Reactive)
- **Trigger:** `data-init` fires when element becomes visible
- **Condition:** `data-show="$sessionId !== '' && !$sseActive"`
- **Action:** Creates `EventSource('http://127.0.0.1:42992/event')`
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

## Available Files

- **`index.html`** - ✅ **Current gold standard** (Experiment 2: data-init pattern)
  - Reactive SSE auto-connection using `data-init`
  - Most "Datastar purist" working solution (4/5 purity, 5/5 maintainability)

- **`index-baseline.html`** - Original 3-step manual process
  - Historical baseline for comparison
  - Manual SSE connection (2/5 purity)

- **`index-experiment2-init.html`** - Same as index.html (experiment source)

- **`index-experiment3-get.html`** - Failed `@get()` purist attempt
  - Demonstrates why Datastar's `@get()` doesn't work with OpenCode
  - Silently ignores events due to namespace filtering (`datastar-*` vs `message.*`)

- **`SSE_EXPERIMENTS.md`** - Complete experiment documentation
  - Evaluation of all approaches (baseline + 3 experiments)
  - Detailed comparison and recommendation

## Key Learnings

### Why `@get()` Doesn't Work (Experiment 3)

**Event Type Namespace Filtering:**
- Datastar's `@get()` filters on event types: `datastar-patch-elements`, `datastar-patch-signals`
- OpenCode emits event types: `message.updated`, `session.updated`, `file.edited`
- Since `message.*` ≠ `datastar-*`, events are silently ignored
- Both use valid `text/event-stream` protocol, but different event namespaces

**For true Datastar integration, you would need:**
1. Translation layer that listens to OpenCode's `message.*` events
2. Transforms them into `datastar-patch-*` events with HTML fragments
3. Emits transformed events on a new SSE endpoint

**Or** (recommended): Use manual `EventSource` wrapped in Datastar's reactive patterns (current implementation)

## Next Steps

Possible future enhancements:
1. Create a translation endpoint that transforms OpenCode events → Datastar HTML patches
2. Implement server-side rendering of AI responses as `datastar-patch-elements`
3. Add more Datastar reactive patterns (optimistic UI, loading states, etc.)

## Notes

- **No build step** - Pure HTML + Datastar CDN
- **No frameworks** - Just `data-*` attributes
- **No JavaScript files** - All logic in HTML
- **Pure Datastar** - Following hypermedia-first principles

---

## ✅ Textarea Binding Solution

### The Critical Discovery

**Textareas require different binding syntax than inputs!**

**❌ This doesn't work:**
```html
<textarea data-bind:promptText>Hello from Datastar! What is 2+2?</textarea>
```

**✅ This works:**
```html
<div data-signals="{promptText: 'Hello from Datastar! What is 2+2?'}">
  <textarea data-bind="promptText">Hello from Datastar! What is 2+2?</textarea>
</div>
```

### Why It Matters

**Key difference:**
- **Input elements:** Use colon syntax `data-bind:signalName`
- **Textarea elements:** Use value syntax `data-bind="signalName"`

**Reference:** Datastar docs line 2516 shows textarea example with value syntax

### The Working Pattern

**Step 1: Initialize the signal**
```html
<div data-signals="{promptText: 'default value'}">
```

**Step 2: Bind textarea with value syntax**
```html
<textarea data-bind="promptText">default value</textarea>
```

**Step 3: Use the signal**
```javascript
data-on:click="fetch(..., body: JSON.stringify({text: $promptText}))"
```

**Result:** ✅ Signal updates as you type, sends correct value when clicked

### Implementation Notes

This pattern ensures:
1. ✅ Signal is explicitly initialized with default value
2. ✅ Textarea binding works with value syntax (not colon syntax)
3. ✅ Signal and textarea stay synchronized
4. ✅ Button sends the current typed value

**Lesson learned:** When Datastar patterns don't work as expected, check the official docs for element-specific syntax!
