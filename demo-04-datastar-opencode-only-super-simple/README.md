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
